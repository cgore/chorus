#|
  This file is a part of cl-cuda project.
  Copyright (c) 2014 Masayuki Takagi (kamonama@gmail.com)
|#


(in-package :cl-cuda.driver-api)


;;;
;;; Load CUDA library
;;;

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
