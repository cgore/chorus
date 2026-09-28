#|
  This file is a part of cl-cuda project.
  Copyright (c) 2014 Masayuki Takagi (kamonama@gmail.com)
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
|#

#|
  Unused. Previously grovelled CUevent and size_t from cuda.h.
  Types are hardcoded in type.lisp; this file is not loaded.
|#

(pkg-config-cflags "cuda" :optional t)
(in-package :cl-cuda.driver-api)


;;;
;;; Include CUDA header file
;;;

#+darwin (include "cuda/cuda.h")
#-darwin (include "cuda.h")


;;;
;;; Types
;;;

;; The followings are redefined with grovel over their definitions in type.lisp.
(ctype cu-event "CUevent")
(ctype size-t "size_t")
