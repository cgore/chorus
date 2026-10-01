#|
  This file is a part of the Chorus project.
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
|#

(in-package :chorus/cuda-libs)

;;; NCCL is optional. The header is not part of the CUDA toolkit on this
;;; machine. Signatures are the documented NCCL C API.
;;;
;;; Skipped ncclCommInitRank. It passes ncclUniqueId by value (128 bytes).
;;; Windows x64 would hide a pointer and System V would pass the bytes in
;;; memory, so declaring the argument :pointer is not a portable convention.
;;; ncclComm_t itself is a pointer, which ncclCommDestroy, ncclAllReduce, and
;;; ncclCommCount can take directly.
;;;
;;; nccl-get-unique-id writes +nccl-unique-id-bytes+ bytes through its pointer.

(defconstant +nccl-unique-id-bytes+ 128)

(defvar *nccl-not-found* nil
  "True when neither nccl.dll nor nccl64.dll loaded.")

(setf *nccl-not-found*
      (not (load-cuda-library "NCCL" '("nccl.dll" "nccl64.dll"))))

(deflibfun (nccl-get-version "ncclGetVersion"
            :library "NCCL" :not-found *nccl-not-found*)
    :int
  (version :pointer))

(deflibfun (nccl-get-unique-id "ncclGetUniqueId"
            :library "NCCL" :not-found *nccl-not-found*)
    :int
  (id :pointer))

(deflibfun (nccl-comm-destroy "ncclCommDestroy"
            :library "NCCL" :not-found *nccl-not-found*)
    :int
  (comm :pointer))

(deflibfun (nccl-all-reduce "ncclAllReduce"
            :library "NCCL" :not-found *nccl-not-found*)
    :int
  (sendbuff :pointer)
  (recvbuff :pointer)
  (count :size)
  (datatype :int)
  (op :int)
  (comm :pointer)
  (stream :pointer))

(deflibfun (nccl-comm-count "ncclCommCount"
            :library "NCCL" :not-found *nccl-not-found*)
    :int
  (comm :pointer)
  (count :pointer))
