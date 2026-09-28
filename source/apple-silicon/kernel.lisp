#|
  This file is a part of the Chorus project.
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
|#

(in-package :chorus/apple-silicon)

(defun c-name (symbol)
  (substitute #\_ #\- (string-downcase (symbol-name symbol))))

(defun pointer-type-p (type)
  (let ((name (symbol-name type)))
    (and (> (length name) 1)
         (char= (char name (1- (length name))) #\*))))

(defun msl-name (type)
  (string-downcase (symbol-name (if (pointer-type-p type)
                                    (intern (subseq (symbol-name type)
                                                    0
                                                    (1- (length (symbol-name type)))))
                                    type))))

(defun index-symbol-p (symbol)
  (member (symbol-name symbol)
          '("THREAD-IDX-X" "THREAD-IDX-Y" "THREAD-IDX-Z"
            "BLOCK-IDX-X" "BLOCK-IDX-Y" "BLOCK-IDX-Z"
            "BLOCK-DIM-X" "BLOCK-DIM-Y" "BLOCK-DIM-Z"
            "GRID-DIM-X" "GRID-DIM-Y" "GRID-DIM-Z")
          :test #'string=))

(defun expr-type (form env)
  (cond
    ((integerp form) 'int)
    ((typep form 'double-float) 'double)
    ((floatp form) 'float)
    ((symbolp form)
     (or (cdr (assoc form env))
         (and (index-symbol-p form) 'int)
         (error 'metal-error
                :message (format nil "Unbound kernel variable ~A." form))))
    ((atom form)
     (error 'metal-error
            :message (format nil "Cannot compile ~S." form)))
    (t
     (case (car form)
       (aref
        (let ((base (expr-type (second form) env)))
          (unless (pointer-type-p base)
            (error 'metal-error
                   :message (format nil "~A is not a pointer." (second form))))
          (intern (subseq (symbol-name base) 0 (1- (length (symbol-name base)))))))
       ((+ - *)
        (let ((types (mapcar (lambda (arg) (expr-type arg env)) (cdr form))))
          (cond ((member 'double types) 'double)
                ((member 'float types) 'float)
                (t 'int))))
       (/
        (let ((types (mapcar (lambda (arg) (expr-type arg env)) (cdr form))))
          (cond ((member 'double types) 'double)
                ((member 'float types) 'float)
                (t 'int))))
       ((< > <= >= = not and or) 'bool)
       (t
        (error 'metal-error
               :message (format nil "Cannot compile ~S." form)))))))

(defun emit-expr (form env)
  (cond
    ((integerp form) (princ-to-string form))
    ((floatp form)
     (format nil "~F" (if (typep form 'double-float) form (float form 1.0))))
    ((symbolp form) (c-name form))
    ((and (consp form) (eq (car form) 'aref))
     (format nil "~A[~A]"
             (emit-expr (second form) env)
             (emit-expr (third form) env)))
    ((and (consp form) (eq (car form) 'not))
     (format nil "(!~A)" (emit-expr (second form) env)))
    ((and (consp form) (member (car form) '(+ - * / < > <= >= = and or)))
     (let ((op (case (car form)
                 (= "==")
                 (and "&&")
                 (or "||")
                 (t (string (car form))))))
       (if (and (eq (car form) '-) (= (length (cdr form)) 1))
           (format nil "(-~A)" (emit-expr (second form) env))
           (format nil "(~{~A~^ ~})"
                   (loop for (arg . rest) on (cdr form)
                         collect (emit-expr arg env)
                         when rest
                           collect op)))))
    (t
     (error 'metal-error
            :message (format nil "Cannot compile ~S." form)))))

(defun emit-stmt (form env)
  (cond
    ((atom form)
     (format nil "~A;~%" (emit-expr form env)))
    ((eq (car form) 'progn)
     (with-output-to-string (out)
       (dolist (statement (cdr form))
         (write-string (emit-stmt statement env) out))))
    ((eq (car form) 'let)
     (emit-let (second form) (cddr form) env))
    ((eq (car form) 'set)
     (format nil "~A;~%" (emit-set (second form) (third form) env)))
    ((eq (car form) 'if)
     (if (fourth form)
         (format nil "if (~A) {~%~A} else {~%~A}~%"
                 (emit-expr (second form) env)
                 (emit-stmt (third form) env)
                 (emit-stmt (fourth form) env))
         (format nil "if (~A) {~%~A}~%"
                 (emit-expr (second form) env)
                 (emit-stmt (third form) env))))
    (t
     (format nil "~A;~%" (emit-expr form env)))))

(defun emit-set (place expr env)
  (if (and (consp place) (eq (car place) 'aref))
      (format nil "~A[~A] = ~A"
              (emit-expr (second place) env)
              (emit-expr (third place) env)
              (emit-expr expr env))
      (format nil "~A = ~A" (emit-expr place env) (emit-expr expr env))))

(defun emit-let (bindings body env)
  (let* ((typed (mapcar (lambda (binding)
                          (list (first binding)
                                (expr-type (second binding) env)
                                (second binding)))
                        bindings))
         (inner (append (mapcar (lambda (binding)
                                  (cons (first binding) (second binding)))
                                typed)
                        env)))
    (with-output-to-string (out)
      (format out "{~%")
      (dolist (binding typed)
        (format out "~A ~A = ~A;~%"
                (msl-name (second binding))
                (c-name (first binding))
                (emit-expr (third binding) env)))
      (dolist (statement body)
        (write-string (emit-stmt statement inner) out))
      (format out "}~%"))))

(defun emit-kernel (name return-type arguments body)
  (unless (and (symbolp return-type)
              (string-equal (symbol-name return-type) "VOID"))
    (error 'metal-error
           :message "A Metal kernel returns void."))
  (let ((buffers nil)
        (scalars nil))
    (dolist (argument arguments)
      (if (pointer-type-p (second argument))
          (push argument buffers)
          (push argument scalars)))
    (setq buffers (nreverse buffers))
    (setq scalars (nreverse scalars))
    (with-output-to-string (out)
      (format out "#include <metal_stdlib>~%using namespace metal;~%")
      (format out "kernel void ~A(~%" (c-name name))
      (loop for argument in buffers
            for index from 0
            do (format out "device ~A *~A [[buffer(~D)]],~%"
                       (msl-name (second argument))
                       (c-name (first argument))
                       index))
      (loop for argument in scalars
            for index from (length buffers)
            do (format out "constant ~A *chorus_scalar_~A [[buffer(~D)]],~%"
                       (msl-name (second argument))
                       (c-name (first argument))
                       index))
      (format out "uint3 thread_position_in_threadgroup [[thread_position_in_threadgroup]],~%")
      (format out "uint3 threadgroup_position_in_grid [[threadgroup_position_in_grid]],~%")
      (format out "uint3 threads_per_threadgroup [[threads_per_threadgroup]],~%")
      (format out "uint3 threadgroups_per_grid [[threadgroups_per_grid]])~%{~%")
      (format out "int thread_idx_x = (int)thread_position_in_threadgroup.x;~%")
      (format out "int thread_idx_y = (int)thread_position_in_threadgroup.y;~%")
      (format out "int thread_idx_z = (int)thread_position_in_threadgroup.z;~%")
      (format out "int block_idx_x = (int)threadgroup_position_in_grid.x;~%")
      (format out "int block_idx_y = (int)threadgroup_position_in_grid.y;~%")
      (format out "int block_idx_z = (int)threadgroup_position_in_grid.z;~%")
      (format out "int block_dim_x = (int)threads_per_threadgroup.x;~%")
      (format out "int block_dim_y = (int)threads_per_threadgroup.y;~%")
      (format out "int block_dim_z = (int)threads_per_threadgroup.z;~%")
      (format out "int grid_dim_x = (int)threadgroups_per_grid.x;~%")
      (format out "int grid_dim_y = (int)threadgroups_per_grid.y;~%")
      (format out "int grid_dim_z = (int)threadgroups_per_grid.z;~%")
      (dolist (argument scalars)
        (format out "~A ~A = chorus_scalar_~A[0];~%"
                (msl-name (second argument))
                (c-name (first argument))
                (c-name (first argument))))
      (let ((env (mapcar (lambda (argument)
                           (cons (first argument) (second argument)))
                         arguments)))
        (dolist (statement body)
          (write-string (emit-stmt statement env) out)))
      (format out "}~%"))))

(defmacro defkernel (name (return-type arguments) &body body)
  (let* ((source (emit-kernel name return-type arguments body))
         (function-name (c-name name))
         (buffer-vars (mapcar #'first
                              (remove-if-not (lambda (argument)
                                               (pointer-type-p (second argument)))
                                             arguments)))
         (scalar-vars (remove-if (lambda (argument)
                                   (pointer-type-p (second argument)))
                                 arguments)))
    `(defun ,name (,@ (mapcar #'first arguments)
                    &key (threads '(1 1 1)) threads-per-group)
       (launch-kernel *device* *command-queue*
                      ,source ,function-name
                      (list ,@buffer-vars)
                      (list ,@(mapcar (lambda (argument)
                                        `(list ',(second argument) ,(first argument)))
                                      scalar-vars))
                      threads
                      threads-per-group))))
