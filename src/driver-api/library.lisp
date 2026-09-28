#|
  This file is a part of the Chorus project.
  Copyright (c) 2014-2016 Masayuki Takagi (kamonama@gmail.com)
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
|#


(in-package :chorus.driver-api)


;;;
;;; Load CUDA library
;;;

;;; Darwin still names CUDA.framework and libcuda.dylib. CUDA 10.2 is
;;; the last toolkit that supports macOS. CUDA 11.0 does not. This
;;; clause does not load on current Macs, and *sdk-not-found* is set.
(cffi:define-foreign-library libcuda
  (:darwin (:or (:framework "CUDA") "libcuda.dylib"))
  (:windows (:or "nvcuda.dll"))
  (:unix (:or "libcuda.so.1" "libcuda.so" "libcuda64.so")))

(handler-case (progn
                (cffi:use-foreign-library libcuda)
                (pushnew :cuda-sdk *features*))
  (cffi:load-foreign-library-error (e)
    (setf *sdk-not-found* t)
    (princ e *error-output*)
    (terpri *error-output*)
    (assert (not (member :cuda-sdk *features*)))))
