#|
  This file is a part of the Chorus project.
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
|#

(in-package :chorus/cuda-libs)

;;; Signatures from cufft.h (CUDA 13.4). cufftHandle is an int, not a pointer:
;;; plan creation writes the int through a pointer, and exec/destroy/set-stream
;;; take that int. cufftType and the direction are ints.

(defconstant +cufft-r2c+ #x2a)
(defconstant +cufft-c2r+ #x2c)
(defconstant +cufft-c2c+ #x29)
(defconstant +cufft-d2z+ #x6a)
(defconstant +cufft-z2d+ #x6c)
(defconstant +cufft-z2z+ #x69)
(defconstant +cufft-forward+ -1)
(defconstant +cufft-inverse+ 1)

(defvar *cufft-not-found* nil
  "True when neither cufft64_12.dll nor cufft64.dll loaded.")

(setf *cufft-not-found*
      (not (load-cuda-library "cuFFT" '("cufft64_12.dll" "cufft64.dll"))))

(deflibfun (cufft-plan-1d "cufftPlan1d"
            :library "cuFFT" :not-found *cufft-not-found*)
    :int
  (plan :pointer)
  (nx :int)
  (type :int)
  (batch :int))

(deflibfun (cufft-plan-2d "cufftPlan2d"
            :library "cuFFT" :not-found *cufft-not-found*)
    :int
  (plan :pointer)
  (nx :int)
  (ny :int)
  (type :int))

(deflibfun (cufft-plan-3d "cufftPlan3d"
            :library "cuFFT" :not-found *cufft-not-found*)
    :int
  (plan :pointer)
  (nx :int)
  (ny :int)
  (nz :int)
  (type :int))

(deflibfun (cufft-exec-c2c "cufftExecC2C"
            :library "cuFFT" :not-found *cufft-not-found*)
    :int
  (plan :int)
  (idata :pointer)
  (odata :pointer)
  (direction :int))

(deflibfun (cufft-exec-z2z "cufftExecZ2Z"
            :library "cuFFT" :not-found *cufft-not-found*)
    :int
  (plan :int)
  (idata :pointer)
  (odata :pointer)
  (direction :int))

(deflibfun (cufft-exec-r2c "cufftExecR2C"
            :library "cuFFT" :not-found *cufft-not-found*)
    :int
  (plan :int)
  (idata :pointer)
  (odata :pointer))

(deflibfun (cufft-exec-c2r "cufftExecC2R"
            :library "cuFFT" :not-found *cufft-not-found*)
    :int
  (plan :int)
  (idata :pointer)
  (odata :pointer))

(deflibfun (cufft-destroy "cufftDestroy"
            :library "cuFFT" :not-found *cufft-not-found*)
    :int
  (plan :int))

(deflibfun (cufft-set-stream "cufftSetStream"
            :library "cuFFT" :not-found *cufft-not-found*)
    :int
  (plan :int)
  (stream :pointer))
