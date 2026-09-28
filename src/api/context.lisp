#|
  This file is a part of the Chorus project.
  Copyright (c) 2014-2016 Masayuki Takagi (kamonama@gmail.com)
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
|#

(in-package :cl-user)
(defpackage chorus.api.context
  (:use :cl
        :chorus.driver-api
        :chorus.api.nvcc
        :chorus.api.kernel-manager)
  (:export ;; Initialize CUDA
           :init-cuda
           ;; CUDA device
           :get-cuda-device
           :device-compute-capability
           ;; CUDA context
           :create-cuda-context
           :destroy-cuda-context
           :synchronize-context
           ;; WITH-CUDA macro
           :*cuda-device*
           :*cuda-context*
           :with-cuda
           :*cuda-stream*))
(in-package :chorus.api.context)


;;;
;;; Initialize CUDA
;;;

(defun init-cuda ()
  (cu-init 0))


;;;
;;; CUDA device
;;;

(defun get-cuda-device (dev-id)
  (cffi:with-foreign-object (device-ptr 'cu-device)
    (cu-device-get device-ptr dev-id)
    (cffi:mem-ref device-ptr 'cu-device)))

(defun device-compute-capability (device)
  "Return (values major minor) for DEVICE's compute capability.
   Uses cuDeviceGetAttribute (current API). RTX 5090 is 12.0."
  (check-type device integer)
  (cffi:with-foreign-objects ((major :int)
                              (minor :int))
    (cu-device-get-attribute major
                             cu-device-attribute-compute-capability-major
                             device)
    (cu-device-get-attribute minor
                             cu-device-attribute-compute-capability-minor
                             device)
    (values (cffi:mem-ref major :int)
            (cffi:mem-ref minor :int))))


;;;
;;; CUDA context
;;;

(defun create-cuda-context (device)
  (cffi:with-foreign-object (context-ptr 'cu-context)
    (cu-ctx-create context-ptr 0 device)
    (cffi:mem-ref context-ptr 'cu-context)))

(defun destroy-cuda-context (context)
  (cu-ctx-destroy context))

(defun synchronize-context ()
  (cu-ctx-synchronize))


;;;
;;; WITH-CUDA macro
;;;

(defvar *cuda-device*)

(defvar *cuda-context*)

(defun get-nvcc-arch (device)
  (multiple-value-bind (major minor)
      (device-compute-capability device)
    (nvcc-arch-option major minor)))

(defun arch-exists-p (options)
  (arch-option-p options))

(defun append-arch (options device)
  (check-type options list)
  (cons (get-nvcc-arch device)
        options))

(defmacro with-cuda ((dev-id) &body body)
  `(progn
     ;; Initialize CUDA.
     (init-cuda)
     (let* (;; Get CUDA device.
            (*cuda-device* (get-cuda-device ,dev-id))
            ;; Create CUDA context.
            (*cuda-context* (create-cuda-context *cuda-device*))
            ;; Append nvcc arch option if not specified.
            (*nvcc-options* (if (arch-exists-p *nvcc-options*)
                                *nvcc-options*
                                (append-arch *nvcc-options* *cuda-device*))))
       (unwind-protect (progn ,@body)
         ;; Unload kernel manager.
         (kernel-manager-unload *kernel-manager*)
         ;; Destroy CUDA context.
         (destroy-cuda-context *cuda-context*)))))

(defvar *cuda-stream* (cffi:null-pointer))
