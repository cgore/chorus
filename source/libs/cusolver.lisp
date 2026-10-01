#|
  This file is a part of the Chorus project.
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
|#

(in-package :chorus/cuda-libs)

;;; Signatures from cusolverDn.h (CUDA 13.4). cusolverDnHandle_t is a pointer.
;;; cublasFillMode_t is an int (CUBLAS_FILL_MODE_LOWER = 0, UPPER = 1).
;;; potrf and getrf take a device devInfo int pointer. getrf also takes devIpiv.

(defvar *cusolver-not-found* nil
  "True when neither cusolver64_12.dll nor cusolver64.dll loaded.")

(setf *cusolver-not-found*
      (not (load-cuda-library "cuSOLVER"
                              '("cusolver64_12.dll" "cusolver64.dll"))))

(deflibfun (cusolver-dn-create "cusolverDnCreate"
            :library "cuSOLVER" :not-found *cusolver-not-found*)
    :int
  (handle :pointer))

(deflibfun (cusolver-dn-destroy "cusolverDnDestroy"
            :library "cuSOLVER" :not-found *cusolver-not-found*)
    :int
  (handle :pointer))

(deflibfun (cusolver-dn-set-stream "cusolverDnSetStream"
            :library "cuSOLVER" :not-found *cusolver-not-found*)
    :int
  (handle :pointer)
  (stream-id :pointer))

(deflibfun (cusolver-dn-spotrf-buffer-size "cusolverDnSpotrf_bufferSize"
            :library "cuSOLVER" :not-found *cusolver-not-found*)
    :int
  (handle :pointer)
  (uplo :int)
  (n :int)
  (a :pointer)
  (lda :int)
  (lwork :pointer))

(deflibfun (cusolver-dn-spotrf "cusolverDnSpotrf"
            :library "cuSOLVER" :not-found *cusolver-not-found*)
    :int
  (handle :pointer)
  (uplo :int)
  (n :int)
  (a :pointer)
  (lda :int)
  (workspace :pointer)
  (lwork :int)
  (dev-info :pointer))

(deflibfun (cusolver-dn-dpotrf-buffer-size "cusolverDnDpotrf_bufferSize"
            :library "cuSOLVER" :not-found *cusolver-not-found*)
    :int
  (handle :pointer)
  (uplo :int)
  (n :int)
  (a :pointer)
  (lda :int)
  (lwork :pointer))

(deflibfun (cusolver-dn-dpotrf "cusolverDnDpotrf"
            :library "cuSOLVER" :not-found *cusolver-not-found*)
    :int
  (handle :pointer)
  (uplo :int)
  (n :int)
  (a :pointer)
  (lda :int)
  (workspace :pointer)
  (lwork :int)
  (dev-info :pointer))

(deflibfun (cusolver-dn-sgetrf-buffer-size "cusolverDnSgetrf_bufferSize"
            :library "cuSOLVER" :not-found *cusolver-not-found*)
    :int
  (handle :pointer)
  (m :int)
  (n :int)
  (a :pointer)
  (lda :int)
  (lwork :pointer))

(deflibfun (cusolver-dn-sgetrf "cusolverDnSgetrf"
            :library "cuSOLVER" :not-found *cusolver-not-found*)
    :int
  (handle :pointer)
  (m :int)
  (n :int)
  (a :pointer)
  (lda :int)
  (workspace :pointer)
  (dev-ipiv :pointer)
  (dev-info :pointer))
