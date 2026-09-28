#|
  This file is a part of the Chorus project.
  Copyright (c) 2014 Masayuki Takagi (kamonama@gmail.com)
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
|#

(in-package :cl-user)
(defpackage :chorus/interop/api/defkernel
  (:use :cl :cl-reexport
        :chorus/lang/syntax
        :chorus/lang/type
        :chorus/interop/driver-api
        :chorus/interop/api/memory)
  (:export :defkernel)
  (:import-from :chorus/api/kernel-manager
                :kernel-manager-define-function
                :ensure-kernel-function-loaded
                :*kernel-manager*)
  (:import-from :chorus/api/defkernel
                :argument-vars
                :argument-var-ptr
                :argument-cffi-type
                :ptr-binding
                :setf-to-argument-array-form)
  (:import-from :alexandria
                :with-gensyms))
(in-package :chorus/interop/api/defkernel)

(reexport-from :chorus/api/defkernel
               :include '(:defkernelmacro
                          :expand-macro-1
                          :expand-macro
                          :defkernel-symbol-macro))


;;;
;;; DEFKERNEL
;;;

(defun init-foreign-object-form (argument)
  (let ((var (argument-var argument))
        (type (argument-type argument))
        (var-ptr (argument-var-ptr argument))
        (cffi-type (argument-cffi-type argument)))
    (if (array-type-p type)
        `(setf (cffi:mem-ref ,var-ptr ',cffi-type)
               (cond
                 ((memory-block-p ,var)
                  (memory-block-init-device-ptr ,var))
                 ((chorus:memory-block-p ,var)
                  (chorus:memory-block-device-ptr ,var))
                 (t ,var)))
        `(setf (cffi:mem-ref ,var-ptr ',cffi-type) ,var))))

(defun release-foreign-object-form (argument)
  (let ((var (argument-var argument))
        (type (argument-type argument)))
    (if (array-type-p type)
        `(when (memory-block-p ,var)
           (memory-block-release-device-ptr ,var))
        nil)))

(defmacro with-launching-arguments ((var arguments) &body body)
  ;; See CHORUS/API/DEFKERNEL:WITH-LAUNCHING-ARGUMENTS macro for detailed comments.
  ;;
  ;; Example:
  ;;
  ;; (with-launching-arguments (kargs ((x int) (y float3) (a float3*)))
  ;;   (launch-cuda-kernel-function kargs))
  ;;
  ;; Expanded:
  ;;
  ;; (cffi:with-foreign-objects ((x-ptr :int) (y-ptr '(:struct float3)) (a-ptr 'cu-device-ptr))
  ;;   (setf (cffi:mem-ref x-ptr :int) x)
  ;;   (setf (cffi:mem-ref y-ptr '(:struct float3)) y)
  ;;   (setf (cffi:mem-ref a-ptr 'cu-device-ptr) (memory-block-init-device-ptr a))
  ;;   (unwind-protect
  ;;       (cffi:with-foreign-object (kargs :pointer 3)
  ;;         (setf (cffi:mem-aref kargs :pointer 0) x-ptr)
  ;;         (setf (cffi:mem-aref kargs :pointer 1) y-ptr)
  ;;         (setf (cffi:mem-aref kargs :pointer 2) a-ptr)
  ;;         (launch-cuda-kernel-function kargs))
  ;;     (memory-block-release-device-ptr a)))
  ;;
  (let ((ptr-bindings (mapcar #'ptr-binding arguments)))
    `(cffi:with-foreign-objects ,ptr-bindings
       ,@(loop for argument in arguments
            collect (init-foreign-object-form argument))
       (unwind-protect
           (cffi:with-foreign-object (,var :pointer ,(length arguments))
             ,@(loop for argument in arguments
                     for i from 0
                  collect (setf-to-argument-array-form var argument i))
             ,@body)
         ,@(loop for argument in arguments
              collect (release-foreign-object-form argument))))))

(defmacro defkernel (name (return-type arguments) &body body)
  (with-gensyms (hfunc kargs)
    `(progn
       (kernel-manager-define-function *kernel-manager* ',name ',return-type ',arguments ',body)
       (defun ,name (,@(argument-vars arguments) &key (grid-dim '(1 1 1)) (block-dim '(1 1 1)))
         (let ((,hfunc (ensure-kernel-function-loaded *kernel-manager* ',name)))
           (with-launching-arguments (,kargs ,arguments)
             (destructuring-bind (grid-dim-x grid-dim-y grid-dim-z) grid-dim
             (destructuring-bind (block-dim-x block-dim-y block-dim-z) block-dim
               (cu-launch-kernel ,hfunc
                                 grid-dim-x  grid-dim-y  grid-dim-z
                                 block-dim-x block-dim-y block-dim-z
                                 0 (cffi:null-pointer) ,kargs (cffi:null-pointer))))))))))
