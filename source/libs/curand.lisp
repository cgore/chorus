#|
  This file is a part of the Chorus project.
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
|#

(in-package :chorus/cuda-libs)

;;; Signatures from curand.h (CUDA 13.4). curandGenerator_t is a pointer.
;;; curandRngType_t is an int. 0 is CURAND_RNG_TEST, not XORWOW.
;;; CURAND_RNG_PSEUDO_DEFAULT is 100 and selects XORWOW; XORWOW itself is 101.
;;; The seed is unsigned long long. Counts are size_t.

(defconstant +curand-rng-pseudo-default+ 100)
(defconstant +curand-rng-pseudo-xorwow+ 101)

(defvar *curand-not-found* nil
  "True when neither curand64_10.dll nor curand64.dll loaded.")

(setf *curand-not-found*
      (not (load-cuda-library "cuRAND" '("curand64_10.dll" "curand64.dll"))))

(deflibfun (curand-create-generator "curandCreateGenerator"
            :library "cuRAND" :not-found *curand-not-found*)
    :int
  (generator :pointer)
  (rng-type :int))

(deflibfun (curand-destroy-generator "curandDestroyGenerator"
            :library "cuRAND" :not-found *curand-not-found*)
    :int
  (generator :pointer))

(deflibfun (curand-set-stream "curandSetStream"
            :library "cuRAND" :not-found *curand-not-found*)
    :int
  (generator :pointer)
  (stream :pointer))

(deflibfun (curand-set-pseudo-random-generator-seed
            "curandSetPseudoRandomGeneratorSeed"
            :library "cuRAND" :not-found *curand-not-found*)
    :int
  (generator :pointer)
  (seed :unsigned-long-long))

(deflibfun (curand-generate "curandGenerate"
            :library "cuRAND" :not-found *curand-not-found*)
    :int
  (generator :pointer)
  (output-ptr :pointer)
  (num :size))

(deflibfun (curand-generate-uniform "curandGenerateUniform"
            :library "cuRAND" :not-found *curand-not-found*)
    :int
  (generator :pointer)
  (output-ptr :pointer)
  (num :size))

(deflibfun (curand-generate-uniform-double "curandGenerateUniformDouble"
            :library "cuRAND" :not-found *curand-not-found*)
    :int
  (generator :pointer)
  (output-ptr :pointer)
  (num :size))

(deflibfun (curand-generate-normal "curandGenerateNormal"
            :library "cuRAND" :not-found *curand-not-found*)
    :int
  (generator :pointer)
  (output-ptr :pointer)
  (n :size)
  (mean :float)
  (stddev :float))
