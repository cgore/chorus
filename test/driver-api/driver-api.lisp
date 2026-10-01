#|
  This file is a part of the Chorus project.
  Copyright (c) 2014-2016 Masayuki Takagi (kamonama@gmail.com)
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
|#

(in-package :cl-user)
(defpackage chorus/test/driver-api
  (:use :cl :prove
        :chorus/driver-api)
  (:import-from :alexandria
                :with-gensyms))
(in-package :chorus/test/driver-api)

(plan nil)

(defun compile-test-ptx ()
  "Compile a tiny module for driver-API tests. The checked-in sm_10 PTX
   cannot load on modern GPUs (including Blackwell)."
  (unless (chorus/api/nvcc:nvcc-available-p)
    (return-from compile-test-ptx nil))
  (chorus/api/nvcc:nvcc-compile
   "extern \"C\" __global__ void VecAdd_kernel(int *a) { a[0] = 1; }
__device__ int a = 0;
"))


;;;
;;; WITH-CU-CONTEXT macro
;;;

(defmacro with-cu-context ((dev-id) &body body)
  (with-gensyms (device context)
    `(let (,device ,context)
       ;; initialize CUDA
       (cu-init 0)
       ;; get CUdevice
       (cffi:with-foreign-object (device-ptr 'cu-device)
         (cu-device-get device-ptr ,dev-id)
         (setf ,device (cffi:mem-ref device-ptr 'cu-device)))
       ;; create CUcontext
       (cffi:with-foreign-object (context-ptr 'cu-context)
         (cu-ctx-create context-ptr 0 ,device)
         (setf ,context (cffi:mem-ref context-ptr 'cu-context)))
     (unwind-protect
          (progn ,@body)
       (cu-ctx-destroy ,context)))))


;;;
;;; test CUDA driver API
;;;

(diag "test cuInit")
(cu-init 0)

(diag "test cuDriverGetVersion")
(cffi:with-foreign-object (version :int)
  (cu-driver-get-version version)
  (let ((code (cffi:mem-ref version :int)))
    (format t "CUDA driver version code: ~A~%" code)
    (ok (>= code 10000) "cuDriverGetVersion is major*1000 + minor*10")))

(diag "test cuDeviceGet")
(let ((dev-id 0))
  (cffi:with-foreign-object (device 'cu-device)
    (setf (cffi:mem-ref device :int) 42)
    (cu-device-get device dev-id)
    (format t "CUDA device handle: ~A~%" (cffi:mem-ref device 'cu-device))))

(diag "test cuDeviceGetCount")
(cffi:with-foreign-object (count :int)
  (cu-device-get-count count)
  (format t "CUDA device count: ~A~%" (cffi:mem-ref count :int)))

(diag "test cuDeviceComputeCapability")
(let ((dev-id 0))
  (cffi:with-foreign-objects ((major :int)
                              (minor :int)
                              (device 'cu-device))
    (cu-device-get device dev-id)
    (cu-device-compute-capability major minor (cffi:mem-ref device 'cu-device))
    (format t "CUDA device compute capability: ~A.~A~%"
              (cffi:mem-ref major :int) (cffi:mem-ref minor :int))))

(diag "test cuDeviceGetName")
(let ((dev-id 0))
  (cffi:with-foreign-object (device 'cu-device)
  (cffi:with-foreign-pointer-as-string ((name size) 255)
    (cu-device-get device dev-id)
    (cu-device-get-name name size (cffi:mem-ref device 'cu-device))
    (format t "CUDA device name: ~A~%" (cffi:foreign-string-to-lisp name)))))

(diag "test cuCtxCreate/cuCtxDestroy")
(let ((flags 0)
      (dev-id 0))
  (cffi:with-foreign-objects ((pctx   'cu-context)
                              (device 'cu-device))
    (cu-device-get device dev-id)
    (cu-ctx-create pctx flags (cffi:mem-ref device 'cu-device))
    (cu-ctx-destroy (cffi:mem-ref pctx 'cu-context))))

(diag "test cuMemAlloc/cuMemFree")
(let ((flags 0)
      (dev-id 0))
  (cffi:with-foreign-objects ((device 'cu-device)
                              (pctx   'cu-context)
                              (dptr   'cu-device-ptr))
    (cu-device-get device dev-id)
    (cu-ctx-create pctx flags (cffi:mem-ref device 'cu-device))
    (cu-mem-alloc dptr 1024)
    (cu-mem-free (cffi:mem-ref dptr 'cu-device-ptr))
    (cu-ctx-destroy (cffi:mem-ref pctx 'cu-context))))

(diag "test cuMemAlloc/cuMemFree using WITH-CU-CONTEXT macro")
(with-cu-context (0)
  (cffi:with-foreign-object (dptr 'cu-device-ptr)
    (cu-mem-alloc dptr 1024)
    (cu-mem-free (cffi:mem-ref dptr 'cu-device-ptr))))

(diag "test cuMemcpyHtoD/cuMemcpyDtoH")
(let ((size 1024))
  (with-cu-context (0)
    (cffi:with-foreign-objects ((hptr :float size)
                                (dptr 'cu-device-ptr))
      (cu-mem-alloc dptr size)
      (cu-memcpy-host-to-device (cffi:mem-ref dptr 'cu-device-ptr) hptr size)
      (cu-memcpy-device-to-host hptr (cffi:mem-ref dptr 'cu-device-ptr) size)
      (cu-mem-free (cffi:mem-ref dptr 'cu-device-ptr)))))

(diag "test cuModuleLoad")
(let ((ptx-path (compile-test-ptx)))
  (if ptx-path
      (with-cu-context (0)
        (cffi:with-foreign-object (module 'cu-module)
          (cu-module-load module ptx-path)
          (format t "CUDA module is loaded.~%")))
      (skip 1 "nvcc not installed")))

(diag "test cuModuleGetFunction")
(let ((ptx-path (compile-test-ptx)))
  (if ptx-path
      (with-cu-context (0)
        (cffi:with-foreign-objects ((module 'cu-module)
                                    (hfunc  'cu-function))
          (cu-module-load module ptx-path)
          (cu-module-get-function hfunc (cffi:mem-ref module 'cu-module)
                                  "VecAdd_kernel")))
      (skip 1 "nvcc not installed")))

(diag "test cuModuleGetGlobal")
(let ((ptx-path (compile-test-ptx)))
  (if ptx-path
      (with-cu-context (0)
        (cffi:with-foreign-objects ((hmodule 'cu-module)
                                    (dptr 'cu-device-ptr))
          ;; Load kernel module.
          (cu-module-load hmodule ptx-path)
          ;; Get global's device pointer.
          (cu-module-get-global dptr
                                (cffi:null-pointer)
                                (cffi:mem-ref hmodule 'cu-module)
                                "a")        ; "a" is the name of the global.
          ;; Write to global.
          (cffi:with-foreign-object (a :int)
            (setf (cffi:mem-ref a :int) 42)
            (cu-memcpy-host-to-device (cffi:mem-ref dptr 'cu-device-ptr)
                                      a
                                      (cffi:foreign-type-size :int)))
          ;; Read from global and test it.
          (cffi:with-foreign-object (a :int)
            (setf (cffi:mem-ref a :int) 0)
            (cu-memcpy-device-to-host a
                                      (cffi:mem-ref dptr 'cu-device-ptr)
                                      (cffi:foreign-type-size :int))
            (is (cffi:mem-ref a :int) 42))))
      (skip 1 "nvcc not installed")))


(diag "test cuDeviceGetAttribute")
(let ((dev-id 0))
  (cffi:with-foreign-objects ((major :int)
                              (minor :int)
                              (device 'cu-device))
    (cu-init 0)
    (cu-device-get device dev-id)
    (cu-device-get-attribute major
                             cu-device-attribute-compute-capability-major
                             (cffi:mem-ref device 'cu-device))
    (cu-device-get-attribute minor
                             cu-device-attribute-compute-capability-minor
                             (cffi:mem-ref device 'cu-device))
    (let ((maj (cffi:mem-ref major :int))
          (min (cffi:mem-ref minor :int)))
      (ok (>= maj 1) "compute capability major")
      (ok (<= 0 min 9) "compute capability minor")
      (cffi:with-foreign-pointer-as-string ((name size) 255)
        (cu-device-get-name name size (cffi:mem-ref device 'cu-device))
        (let ((lisp-name (cffi:foreign-string-to-lisp name)))
          (when (search "5090" lisp-name)
            (is maj 12 "RTX 5090 is sm_120 major")
            (is min 0 "RTX 5090 is sm_120 minor")))))))

(diag "test cuDeviceTotalMem")
(cffi:with-foreign-object (bytes 'size-t)
  (cu-init 0)
  (cu-device-total-mem bytes 0)
  (ok (>= (cffi:mem-ref bytes 'size-t) (* 1024 1024 1024))
      "total device memory is a 64-bit size_t of at least 1GB"))

(diag "test cuStreamCreate/cuStreamSynchronize/cuStreamDestroy")
(with-cu-context (0)
  (cffi:with-foreign-object (stream 'cu-stream)
    (cu-stream-create stream 0)
    (cu-stream-synchronize (cffi:mem-ref stream 'cu-stream))
    (cu-stream-destroy (cffi:mem-ref stream 'cu-stream))))

(diag "test cuLaunchKernel")
(let ((ptx-path (compile-test-ptx)))
  (if ptx-path
      (with-cu-context (0)
        (cffi:with-foreign-objects ((module 'cu-module)
                                    (hfunc 'cu-function)
                                    (dptr 'cu-device-ptr)
                                    (arg 'cu-device-ptr)
                                    (kargs :pointer 1)
                                    (host :int))
          (cu-module-load module ptx-path)
          (cu-module-get-function hfunc
                                  (cffi:mem-ref module 'cu-module)
                                  "VecAdd_kernel")
          (cu-mem-alloc dptr (cffi:foreign-type-size :int))
          (setf (cffi:mem-ref host :int) 0)
          (cu-memcpy-host-to-device (cffi:mem-ref dptr 'cu-device-ptr)
                                    host
                                    (cffi:foreign-type-size :int))
          (setf (cffi:mem-ref arg 'cu-device-ptr)
                (cffi:mem-ref dptr 'cu-device-ptr))
          (setf (cffi:mem-aref kargs :pointer 0) arg)
          (cu-launch-kernel (cffi:mem-ref hfunc 'cu-function)
                            1 1 1
                            1 1 1
                            0
                            (cffi:null-pointer)
                            kargs
                            (cffi:null-pointer))
          (cu-ctx-synchronize)
          (cu-memcpy-device-to-host host
                                    (cffi:mem-ref dptr 'cu-device-ptr)
                                    (cffi:foreign-type-size :int))
          (is (cffi:mem-ref host :int) 1
              "launched kernel wrote 1")
          (cu-mem-free (cffi:mem-ref dptr 'cu-device-ptr))
          (cu-module-unload (cffi:mem-ref module 'cu-module))))
      (skip 1 "nvcc not installed")))


;;;
;;; test CUDA Event Management functions
;;;

(with-cu-context (0)
  (cffi:with-foreign-objects ((start-event 'cu-event)
                              (stop-event  'cu-event)
                              (milliseconds :float))
    (cu-event-create start-event cu-event-default)
    (cu-event-create stop-event  cu-event-default)
    (cu-event-record (cffi:mem-ref start-event 'cu-event) (cffi:null-pointer))
    (cu-event-record (cffi:mem-ref stop-event  'cu-event) (cffi:null-pointer))
    (cu-event-synchronize (cffi:mem-ref stop-event 'cu-event))
    (cu-event-elapsed-time milliseconds
                           (cffi:mem-ref start-event 'cu-event)
                           (cffi:mem-ref stop-event  'cu-event))
    (format t "CUDA Event - elapsed time: ~A~%" (cffi:mem-ref milliseconds
                                                              :float))
    (cu-event-destroy (cffi:mem-ref start-event 'cu-event))
    (cu-event-destroy (cffi:mem-ref stop-event  'cu-event))))



(finalize)
