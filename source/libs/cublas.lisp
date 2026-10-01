#|
  This file is a part of the Chorus project.
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
|#

(in-package :chorus/cuda-libs)

;;; Signatures from cublas_api.h (CUDA 13.4). Handles and device pointers are
;;; pointers. cublasOperation_t and sizes are ints. CUBLAS_OP_N = 0,
;;; CUBLAS_OP_T = 1, CUBLAS_OP_C = 2. Status 0 is CUBLAS_STATUS_SUCCESS.

(defvar *cublas-not-found* nil
  "True when neither cublas64_13.dll nor cublas64.dll loaded.")

(setf *cublas-not-found*
      (not (load-cuda-library "cuBLAS" '("cublas64_13.dll" "cublas64.dll"))))

(deflibfun (cublas-create "cublasCreate_v2"
            :library "cuBLAS" :not-found *cublas-not-found*)
    :int
  (handle :pointer))

(deflibfun (cublas-destroy "cublasDestroy_v2"
            :library "cuBLAS" :not-found *cublas-not-found*)
    :int
  (handle :pointer))

(deflibfun (cublas-set-stream "cublasSetStream_v2"
            :library "cuBLAS" :not-found *cublas-not-found*)
    :int
  (handle :pointer)
  (stream-id :pointer))

(deflibfun (cublas-sgemm "cublasSgemm_v2"
            :library "cuBLAS" :not-found *cublas-not-found*)
    :int
  (handle :pointer)
  (transa :int)
  (transb :int)
  (m :int)
  (n :int)
  (k :int)
  (alpha :pointer)
  (a :pointer)
  (lda :int)
  (b :pointer)
  (ldb :int)
  (beta :pointer)
  (c :pointer)
  (ldc :int))

(deflibfun (cublas-dgemm "cublasDgemm_v2"
            :library "cuBLAS" :not-found *cublas-not-found*)
    :int
  (handle :pointer)
  (transa :int)
  (transb :int)
  (m :int)
  (n :int)
  (k :int)
  (alpha :pointer)
  (a :pointer)
  (lda :int)
  (b :pointer)
  (ldb :int)
  (beta :pointer)
  (c :pointer)
  (ldc :int))

(deflibfun (cublas-saxpy "cublasSaxpy_v2"
            :library "cuBLAS" :not-found *cublas-not-found*)
    :int
  (handle :pointer)
  (n :int)
  (alpha :pointer)
  (x :pointer)
  (incx :int)
  (y :pointer)
  (incy :int))

(deflibfun (cublas-daxpy "cublasDaxpy_v2"
            :library "cuBLAS" :not-found *cublas-not-found*)
    :int
  (handle :pointer)
  (n :int)
  (alpha :pointer)
  (x :pointer)
  (incx :int)
  (y :pointer)
  (incy :int))

(deflibfun (cublas-sdot "cublasSdot_v2"
            :library "cuBLAS" :not-found *cublas-not-found*)
    :int
  (handle :pointer)
  (n :int)
  (x :pointer)
  (incx :int)
  (y :pointer)
  (incy :int)
  (result :pointer))

(deflibfun (cublas-ddot "cublasDdot_v2"
            :library "cuBLAS" :not-found *cublas-not-found*)
    :int
  (handle :pointer)
  (n :int)
  (x :pointer)
  (incx :int)
  (y :pointer)
  (incy :int)
  (result :pointer))

(deflibfun (cublas-sscal "cublasSscal_v2"
            :library "cuBLAS" :not-found *cublas-not-found*)
    :int
  (handle :pointer)
  (n :int)
  (alpha :pointer)
  (x :pointer)
  (incx :int))

(deflibfun (cublas-dscal "cublasDscal_v2"
            :library "cuBLAS" :not-found *cublas-not-found*)
    :int
  (handle :pointer)
  (n :int)
  (alpha :pointer)
  (x :pointer)
  (incx :int))
