#|
  This file is a part of the Chorus project.
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
|#

(in-package :chorus/cuda-libs)

;;; Signatures from cublasLt.h (CUDA 13.4). Descriptor handles are pointers.
;;; cublasComputeType_t, cudaDataType, and attribute enums are ints.
;;; cublasLtMatmulAlgoGetHeuristic's heuristicResultsArray is a C array, so
;;; the caller passes a pointer to cublasLtMatmulHeuristicResult_t elements.
;;; rows/cols are uint64_t and ld is int64_t, matching the header.

(defvar *cublas-lt-not-found* nil
  "True when neither cublasLt64_13.dll nor cublasLt64.dll loaded.")

(setf *cublas-lt-not-found*
      (not (load-cuda-library "cuBLASLt"
                              '("cublasLt64_13.dll" "cublasLt64.dll"))))

(deflibfun (cublas-lt-create "cublasLtCreate"
            :library "cuBLASLt" :not-found *cublas-lt-not-found*)
    :int
  (light-handle :pointer))

(deflibfun (cublas-lt-destroy "cublasLtDestroy"
            :library "cuBLASLt" :not-found *cublas-lt-not-found*)
    :int
  (light-handle :pointer))

(deflibfun (cublas-lt-matmul-desc-create "cublasLtMatmulDescCreate"
            :library "cuBLASLt" :not-found *cublas-lt-not-found*)
    :int
  (matmul-desc :pointer)
  (compute-type :int)
  (scale-type :int))

(deflibfun (cublas-lt-matmul-desc-destroy "cublasLtMatmulDescDestroy"
            :library "cuBLASLt" :not-found *cublas-lt-not-found*)
    :int
  (matmul-desc :pointer))

(deflibfun (cublas-lt-matmul-desc-set-attribute "cublasLtMatmulDescSetAttribute"
            :library "cuBLASLt" :not-found *cublas-lt-not-found*)
    :int
  (matmul-desc :pointer)
  (attr :int)
  (buf :pointer)
  (size-in-bytes :size))

(deflibfun (cublas-lt-matrix-layout-create "cublasLtMatrixLayoutCreate"
            :library "cuBLASLt" :not-found *cublas-lt-not-found*)
    :int
  (mat-layout :pointer)
  (type :int)
  (rows :uint64)
  (cols :uint64)
  (ld :int64))

(deflibfun (cublas-lt-matrix-layout-destroy "cublasLtMatrixLayoutDestroy"
            :library "cuBLASLt" :not-found *cublas-lt-not-found*)
    :int
  (mat-layout :pointer))

(deflibfun (cublas-lt-matmul "cublasLtMatmul"
            :library "cuBLASLt" :not-found *cublas-lt-not-found*)
    :int
  (light-handle :pointer)
  (compute-desc :pointer)
  (alpha :pointer)
  (a :pointer)
  (a-desc :pointer)
  (b :pointer)
  (b-desc :pointer)
  (beta :pointer)
  (c :pointer)
  (c-desc :pointer)
  (d :pointer)
  (d-desc :pointer)
  (algo :pointer)
  (workspace :pointer)
  (workspace-size-in-bytes :size)
  (stream :pointer))

(deflibfun (cublas-lt-matmul-algo-get-heuristic "cublasLtMatmulAlgoGetHeuristic"
            :library "cuBLASLt" :not-found *cublas-lt-not-found*)
    :int
  (light-handle :pointer)
  (operation-desc :pointer)
  (a-desc :pointer)
  (b-desc :pointer)
  (c-desc :pointer)
  (d-desc :pointer)
  (preference :pointer)
  (requested-algo-count :int)
  (heuristic-results-array :pointer)
  (return-algo-count :pointer))
