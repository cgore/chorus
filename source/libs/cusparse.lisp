#|
  This file is a part of the Chorus project.
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
|#

(in-package :chorus/cuda-libs)

;;; Signatures from cusparse.h (CUDA 13.4). cusparseHandle_t and the generic
;;; descriptors are pointers. Dimensions are int64_t. Operation, index type,
;;; index base, order, cudaDataType, and algorithm enums are ints.
;;; cusparseScsrmv is not in this header; the generic SpMV and SpMM APIs are.

(defvar *cusparse-not-found* nil
  "True when neither cusparse64_12.dll nor cusparse64.dll loaded.")

(setf *cusparse-not-found*
      (not (load-cuda-library "cuSPARSE"
                              '("cusparse64_12.dll" "cusparse64.dll"))))

(deflibfun (cusparse-create "cusparseCreate"
            :library "cuSPARSE" :not-found *cusparse-not-found*)
    :int
  (handle :pointer))

(deflibfun (cusparse-destroy "cusparseDestroy"
            :library "cuSPARSE" :not-found *cusparse-not-found*)
    :int
  (handle :pointer))

(deflibfun (cusparse-create-csr "cusparseCreateCsr"
            :library "cuSPARSE" :not-found *cusparse-not-found*)
    :int
  (sp-mat-descr :pointer)
  (rows :int64)
  (cols :int64)
  (nnz :int64)
  (csr-row-offsets :pointer)
  (csr-col-ind :pointer)
  (csr-values :pointer)
  (csr-row-offsets-type :int)
  (csr-col-ind-type :int)
  (idx-base :int)
  (value-type :int))

(deflibfun (cusparse-destroy-sp-mat "cusparseDestroySpMat"
            :library "cuSPARSE" :not-found *cusparse-not-found*)
    :int
  (sp-mat-descr :pointer))

(deflibfun (cusparse-create-dn-vec "cusparseCreateDnVec"
            :library "cuSPARSE" :not-found *cusparse-not-found*)
    :int
  (dn-vec-descr :pointer)
  (size :int64)
  (values :pointer)
  (value-type :int))

(deflibfun (cusparse-destroy-dn-vec "cusparseDestroyDnVec"
            :library "cuSPARSE" :not-found *cusparse-not-found*)
    :int
  (dn-vec-descr :pointer))

(deflibfun (cusparse-create-dn-mat "cusparseCreateDnMat"
            :library "cuSPARSE" :not-found *cusparse-not-found*)
    :int
  (dn-mat-descr :pointer)
  (rows :int64)
  (cols :int64)
  (ld :int64)
  (values :pointer)
  (value-type :int)
  (order :int))

(deflibfun (cusparse-destroy-dn-mat "cusparseDestroyDnMat"
            :library "cuSPARSE" :not-found *cusparse-not-found*)
    :int
  (dn-mat-descr :pointer))

(deflibfun (cusparse-spmv "cusparseSpMV"
            :library "cuSPARSE" :not-found *cusparse-not-found*)
    :int
  (handle :pointer)
  (op-a :int)
  (alpha :pointer)
  (mat-a :pointer)
  (vec-x :pointer)
  (beta :pointer)
  (vec-y :pointer)
  (compute-type :int)
  (alg :int)
  (external-buffer :pointer))

(deflibfun (cusparse-spmm "cusparseSpMM"
            :library "cuSPARSE" :not-found *cusparse-not-found*)
    :int
  (handle :pointer)
  (op-a :int)
  (op-b :int)
  (alpha :pointer)
  (mat-a :pointer)
  (mat-b :pointer)
  (beta :pointer)
  (mat-c :pointer)
  (compute-type :int)
  (alg :int)
  (external-buffer :pointer))
