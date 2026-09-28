#|
  This file is a part of cl-cuda project.
  Copyright (c) 2014 Masayuki Takagi (kamonama@gmail.com)
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
|#


(in-package :cl-cuda.driver-api)


;;;
;;; Types
;;;

(cffi:defctype cu-result :unsigned-int)
(cffi:defctype cu-device :int)
(cffi:defctype cu-context :pointer)
(cffi:defctype cu-module :pointer)
(cffi:defctype cu-function :pointer)
(cffi:defctype cu-stream :pointer)
(cffi:defctype cu-event :pointer)
(cffi:defctype cu-graphics-resource :pointer)

;; CUdeviceptr is unsigned long long on all current 64-bit CUDA ports.
;; CFFI's :size is size_t (8 bytes on 64-bit Windows and Unix). These used
;; to be grovelled from cuda.h; they are hardcoded so the system loads
;; without a C compiler or CUDA headers.
(cffi:defctype cu-device-ptr :unsigned-long-long)
(cffi:defctype size-t :size)