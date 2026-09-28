#|
  This file is a part of cl-cuda project.
  Copyright (c) 2012-2016 Masayuki Takagi (kamonama@gmail.com)
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
|#


(in-package cl-cuda.driver-api)

(defvar *sdk-not-found* nil)

(define-condition sdk-not-found-error (simple-error) ()
  (:report "CUDA driver library not found (nvcuda.dll / libcuda.so.1 / CUDA.framework)."))
