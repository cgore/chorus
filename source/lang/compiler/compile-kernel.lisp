#|
  This file is a part of the Chorus project.
  Copyright (c) 2012-2016 Masayuki Takagi (kamonama@gmail.com)
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
|#

(in-package :cl-user)
(defpackage chorus/lang/compiler/compile-kernel
  (:use :cl
        :chorus/lang/util
        :chorus/lang/type
        :chorus/lang/syntax
        :chorus/lang/environment
        :chorus/lang/kernel
        :chorus/lang/compiler/compile-data
        :chorus/lang/compiler/compile-type
        :chorus/lang/compiler/compile-expression
        :chorus/lang/compiler/compile-statement
        :chorus/lang/compiler/type-of-expression)
  (:export :compile-kernel))
(in-package :chorus/lang/compiler/compile-kernel)


;;;
;;; Kernel to Environment
;;;

(defun %add-function-arguments (kernel name var-env)
  (flet ((aux (var-env0 argument)
           (let ((var (argument-var argument))
                 (type (argument-type argument)))
             (variable-environment-add-variable var type var-env0))))
    (reduce #'aux (kernel-function-arguments kernel name)
            :initial-value var-env)))

(defun %add-symbol-macros (kernel var-env)
  (flet ((aux (var-env0 name)
           (let ((expansion (kernel-symbol-macro-expansion kernel name)))
             (variable-environment-add-symbol-macro name expansion
                                                    var-env0))))
    (reduce #'aux (kernel-symbol-macro-names kernel)
            :initial-value var-env)))

(defun %add-globals (kernel var-env)
  (flet ((aux (var-env0 name)
           (let* ((initializer (kernel-global-initializer kernel name))
                  (type (type-of-expression initializer nil nil)))
            (variable-environment-add-global name type initializer var-env0))))
    (reduce #'aux (kernel-global-names kernel)
            :initial-value var-env)))

(defun kernel->variable-environment (kernel name)
  (if name
      (%add-function-arguments kernel name
       (%add-symbol-macros kernel
        (%add-globals kernel
         (empty-variable-environment))))
      (%add-symbol-macros kernel
       (%add-globals kernel
        (empty-variable-environment)))))

(defun %add-functions (kernel func-env)
  (flet ((aux (func-env0 name)
           (let ((return-type (kernel-function-return-type kernel name))
                 (argument-types (kernel-function-argument-types kernel
                                                                 name)))
             (function-environment-add-function name return-type
                                                argument-types func-env0))))
    (reduce #'aux (kernel-function-names kernel)
            :initial-value func-env)))

(defun %add-macros (kernel func-env)
  (flet ((aux (func-env0 name)
           (let ((arguments (kernel-macro-arguments kernel name))
                 (body (kernel-macro-body kernel name)))
             (function-environment-add-macro name arguments body func-env0))))
    (reduce #'aux (kernel-macro-names kernel)
            :initial-value func-env)))

(defun kernel->function-environment (kernel)
  (%add-functions kernel
    (%add-macros kernel
      (empty-function-environment))))


;;;
;;; Compile kernel
;;;

(defun tree-mentions-extended-float-p (tree)
  (cond ((extended-float-type-name-p tree) t)
        ((consp tree)
         (or (tree-mentions-extended-float-p (car tree))
             (tree-mentions-extended-float-p (cdr tree))))
        (t nil)))

(defun user-structures-need-extended-types-p ()
  (some (lambda (entry)
          (some (lambda (accessor)
                  (extended-float-type-name-p (third accessor)))
                (third entry)))
        (user-structures)))

(defun kernel-needs-extended-types-p (kernel)
  (or (user-structures-need-extended-types-p)
      (some (lambda (name)
              (or (tree-mentions-extended-float-p
                   (kernel-function-return-type kernel name))
                  (tree-mentions-extended-float-p
                   (kernel-function-arguments kernel name))
                  (tree-mentions-extended-float-p
                   (kernel-function-body kernel name))))
            (kernel-function-names kernel))
      (some (lambda (name)
              (tree-mentions-extended-float-p
               (kernel-global-initializer kernel name)))
            (kernel-global-names kernel))))

(defun compile-user-structure (entry)
  (format nil "struct ~A {~%~{~A~}};~%~%"
          (second entry)
          (mapcar (lambda (accessor)
                    (format nil "  ~A ~A;~%"
                            (cuda-type (third accessor))
                            (second accessor)))
                  (third entry))))

(defun compile-user-structures ()
  (let ((entries (user-structures)))
    (if entries
        (format nil "~%~{~A~}" (mapcar #'compile-user-structure entries))
        "")))

(defun compile-includes (&optional kernel)
  (concatenate 'string
               "#include \"int.h\"
#include \"float.h\"
#include \"float3.h\"
#include \"float4.h\"
#include \"double.h\"
#include \"double3.h\"
#include \"double4.h\"
#include \"curand.h\"
#include \"chorus-cluster.h\"
"
               (if (and kernel (kernel-needs-extended-types-p kernel))
                   "#include \"chorus-types.h\"
"
                   "")
               (compile-user-structures)))

(defun compile-variable-qualifier (qualifier)
  (format nil "__~A__" (string-downcase (princ-to-string qualifier))))

(defun compile-global (kernel name)
  (let ((c-name (kernel-global-c-name kernel name))
        (qualifiers (kernel-global-qualifiers kernel name))
        (initializer (kernel-global-initializer kernel name)))
    (let ((type1 (compile-type
                  (type-of-expression initializer nil nil)))
          (qualifiers1 (mapcar #'compile-variable-qualifier qualifiers))
          (initializer1 (compile-expression initializer
                         (kernel->variable-environment kernel nil)
                         (kernel->function-environment kernel)
                         t)))
      (format nil "~{~A~^ ~} static ~A ~A~@[ = ~A~];~%"
              qualifiers1 type1 c-name initializer1))))

(defun compile-globals (kernel)
  (flet ((aux (name)
           (compile-global kernel name)))
    (let ((globals (mapcar #'aux (kernel-global-names kernel))))
      (format nil "/**
 *  Kernel globals
 */

~{~A~}" globals))))

(defun compile-specifier (return-type)
  (unless (chorus-type-p return-type)
    (error 'type-error :datum return-type :expected 'chorus-type))
  (if (eq return-type 'void)
      "__global__"
      "__device__"))

(defun compile-argument (argument)
  (let ((var (argument-var argument))
        (type (argument-type argument)))
    (format nil "~A~:[~; __restrict__~] ~A"
            (compile-type type)
            (argument-restrict-p argument)
            (compile-symbol var))))

(defun compile-arguments (arguments)
  (let ((arguments1 (mapcar #'compile-argument arguments)))
    (if arguments1
        (format nil " ~{~A~^, ~} " arguments1)
        "")))

(defun compile-declaration (kernel name)
  (let ((c-name (kernel-function-c-name kernel name))
        (return-type (kernel-function-return-type kernel name))
        (arguments (kernel-function-arguments kernel name))
        (bounds (launch-bounds-values (kernel-function-body kernel name))))
    (when (and bounds (not (eq return-type 'void)))
      (error "launch-bounds applies to kernels only: ~S." name))
    (let ((specifier (compile-specifier return-type))
          (return-type1 (compile-type return-type))
          (arguments1 (compile-arguments arguments)))
      (format nil "~A ~A~@[ __launch_bounds__(~{~A~^, ~})~] ~A(~A)"
              specifier return-type1 bounds c-name arguments1))))

(defun compile-prototype (kernel name)
  (let ((declaration (compile-declaration kernel name)))
    (format nil "extern \"C\" ~A;~%" declaration)))

(defun compile-prototypes (kernel)
  (flet ((aux (name)
           (compile-prototype kernel name)))
    (let ((prototypes (mapcar #'aux (kernel-function-names kernel))))
      (format nil "/**
 *  Kernel function prototypes
 */

~{~A~}" prototypes))))

(defun body-without-declares (body)
  (loop for rest on body
        while (declare-p (first rest))
        finally (return rest)))

(defun compile-statements (kernel name)
  (let ((var-env (kernel->variable-environment kernel name))
        (func-env (kernel->function-environment kernel)))
    (flet ((aux (statement)
             (compile-statement statement var-env func-env)))
      (let ((statements (body-without-declares
                         (kernel-function-body kernel name))))
        (format nil "~{~A~}" (mapcar #'aux statements))))))

(defun compile-definition (kernel name)
  (let ((declaration (compile-declaration kernel name))
        (statements (compile-statements kernel name)))
    (let ((statements1 (indent 2 statements)))
      (format nil "~A~%{~%~A}~%" declaration statements1))))

(defun compile-definitions (kernel)
  (flet ((aux (name)
           (compile-definition kernel name)))
    (let ((definitions (mapcar #'aux (kernel-function-names kernel))))
      (format nil "/**
 *  Kernel function definitions
 */

~{~A~^~%~}" definitions))))

(defun compile-kernel (kernel)
  (let ((includes (compile-includes kernel))
        (globals (compile-globals kernel))
        (prototypes (compile-prototypes kernel))
        (definitions (compile-definitions kernel)))
    (format nil "~A~%~%~A~%~%~A~%~%~A" includes
                                       globals
                                       prototypes
                                       definitions)))
