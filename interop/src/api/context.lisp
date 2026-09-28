#|
  This file is a part of the Chorus project.
  Copyright (c) 2014 Masayuki Takagi (kamonama@gmail.com)
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
|#

(in-package :cl-user)
(defpackage chorus-interop.api.context
  (:use :cl :cl-reexport
        :chorus.api.kernel-manager
        :chorus-interop.driver-api)
  (:export ;; CUDA context
           :create-cuda-context
           ;; WITH-CUDA macro
           :with-cuda))
(in-package :chorus-interop.api.context)

(eval-when (:execute :load-toplevel :compile-toplevel)
  (reexport-from :chorus.api.context
                 :exclude '(:create-cuda-context
                            :with-cuda)))


;;;
;;; CUDA context
;;;

(defun create-cuda-context (device)
  (cffi:with-foreign-object (context-ptr 'cu-context)
    (cu-gl-ctx-create context-ptr 0 device)
    (cffi:mem-ref context-ptr 'cu-context)))


;;;
;;; WITH-CUDA macro
;;;

(defmacro with-cuda ((dev-id &key (interop t)) &body body)
  `(progn
     ;; initialize CUDA
     (init-cuda)
     (let* (;; get CUDA device
            (*cuda-device* (get-cuda-device ,dev-id))
            ;; create CUDA context
            (*cuda-context*
              (if ,interop
                  (create-cuda-context *cuda-device*)
                  (chorus:create-cuda-context *cuda-device*))))
       (unwind-protect (progn ,@body)
         ;; unload kernel manager
         (kernel-manager-unload *kernel-manager*)
         ;; destroy CUDA context
         (destroy-cuda-context *cuda-context*)))))
