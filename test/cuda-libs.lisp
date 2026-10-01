#|
  This file is a part of the Chorus project.
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
|#

(defpackage :chorus/cuda-libs/test
  (:use :cl :prove :chorus/cuda-libs))
(in-package :chorus/cuda-libs/test)

(plan nil)

(diag (format nil "not-found: cublas=~A cublaslt=~A cufft=~A curand=~A cusolver=~A cusparse=~A npp=~A nvjpeg=~A nccl=~A cudnn=~A"
              *cublas-not-found* *cublas-lt-not-found* *cufft-not-found*
              *curand-not-found* *cusolver-not-found* *cusparse-not-found*
              *npp-not-found* *nvjpeg-not-found* *nccl-not-found*
              *cudnn-not-found*))

(ok (not *cublas-not-found*) "cuBLAS loaded")
(ok (not *cublas-lt-not-found*) "cuBLASLt loaded")
(ok (not *cufft-not-found*) "cuFFT loaded")
(ok (not *curand-not-found*) "cuRAND loaded")
(ok (not *cusolver-not-found*) "cuSOLVER loaded")
(ok (not *cusparse-not-found*) "cuSPARSE loaded")
(ok (not *npp-not-found*) "NPP loaded")
(ok (not *nvjpeg-not-found*) "nvJPEG loaded")

(defun pointer-handle (slot)
  (cffi:mem-ref slot :pointer))

(chorus:with-cuda (0)
  (unless *cublas-not-found*
    (cffi:with-foreign-object (slot :pointer)
      (is (cublas-create slot) 0 "cublas-create")
      (let ((handle (pointer-handle slot)))
        (ok (not (cffi:null-pointer-p handle)) "cublas handle")
        (is (cublas-destroy handle) 0 "cublas-destroy"))))
  (unless *cublas-lt-not-found*
    (cffi:with-foreign-object (slot :pointer)
      (is (cublas-lt-create slot) 0 "cublasLtCreate")
      (let ((handle (pointer-handle slot)))
        (ok (not (cffi:null-pointer-p handle)) "cublasLt handle")
        (is (cublas-lt-destroy handle) 0 "cublasLtDestroy"))))
  (unless *cufft-not-found*
    ;; CUFFT_C2C is #x29. CUFFT_FORWARD is -1. The plan handle is an int.
    (cffi:with-foreign-object (plan :int)
      (is (cufft-plan-1d plan 8 +cufft-c2c+ 1) 0 "cufft-plan-1d")
      (is (cufft-destroy (cffi:mem-ref plan :int)) 0 "cufft-destroy")))
  (unless *curand-not-found*
    ;; Header value 101 is CURAND_RNG_PSEUDO_XORWOW. 0 is CURAND_RNG_TEST.
    (cffi:with-foreign-object (slot :pointer)
      (is (curand-create-generator slot +curand-rng-pseudo-xorwow+) 0
          "curand-create-generator XORWOW")
      (let ((generator (pointer-handle slot)))
        (ok (not (cffi:null-pointer-p generator)) "curand generator")
        (is (curand-destroy-generator generator) 0
            "curand-destroy-generator"))))
  (unless *cusolver-not-found*
    (cffi:with-foreign-object (slot :pointer)
      (is (cusolver-dn-create slot) 0 "cusolverDnCreate")
      (let ((handle (pointer-handle slot)))
        (ok (not (cffi:null-pointer-p handle)) "cusolver handle")
        (is (cusolver-dn-destroy handle) 0 "cusolverDnDestroy"))))
  (unless *cusparse-not-found*
    (cffi:with-foreign-object (slot :pointer)
      (is (cusparse-create slot) 0 "cusparseCreate")
      (let ((handle (pointer-handle slot)))
        (ok (not (cffi:null-pointer-p handle)) "cusparse handle")
        (is (cusparse-destroy handle) 0 "cusparseDestroy"))))
  (unless *nvjpeg-not-found*
    (cffi:with-foreign-object (slot :pointer)
      (is (nvjpeg-create-simple slot) 0 "nvjpegCreateSimple")
      (let ((handle (pointer-handle slot)))
        (ok (not (cffi:null-pointer-p handle)) "nvjpeg handle")
        (is (nvjpeg-destroy handle) 0 "nvjpegDestroy"))))
  (unless *npp-not-found*
    (let ((version (npp-get-lib-version)))
      (ok (not (cffi:null-pointer-p version)) "nppGetLibVersion")
      (ok (plusp (cffi:mem-ref version :int)) "NPP major version")))
  (if *nccl-not-found*
      (ok *nccl-not-found* "NCCL is optional and did not load")
      (cffi:with-foreign-object (version :int)
        (is (nccl-get-version version) 0 "ncclGetVersion")
        (ok (plusp (cffi:mem-ref version :int)) "nccl version")))
  (if *cudnn-not-found*
      (ok *cudnn-not-found* "cuDNN is optional and did not load")
      (cffi:with-foreign-object (slot :pointer)
        (is (cudnn-create slot) 0 "cudnnCreate")
        (let ((handle (pointer-handle slot)))
          (ok (not (cffi:null-pointer-p handle)) "cudnn handle")
          (is (cudnn-destroy handle) 0 "cudnnDestroy")))))

(finalize)
