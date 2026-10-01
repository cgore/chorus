#|
  This file is a part of the Chorus project.
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
|#

(in-package :chorus/cuda-libs)

;;; Signatures from nvjpeg.h (CUDA 13.4). Handles are pointers. length is
;;; size_t. nComponents, subsampling, widths, and heights are pointers.
;;; widths and heights point at NVJPEG_MAX_COMPONENT ints.

(defvar *nvjpeg-not-found* nil
  "True when neither nvjpeg64_13.dll nor nvjpeg64.dll loaded.")

(setf *nvjpeg-not-found*
      (not (load-cuda-library "nvJPEG" '("nvjpeg64_13.dll" "nvjpeg64.dll"))))

(deflibfun (nvjpeg-create-simple "nvjpegCreateSimple"
            :library "nvJPEG" :not-found *nvjpeg-not-found*)
    :int
  (handle :pointer))

(deflibfun (nvjpeg-destroy "nvjpegDestroy"
            :library "nvJPEG" :not-found *nvjpeg-not-found*)
    :int
  (handle :pointer))

(deflibfun (nvjpeg-get-image-info "nvjpegGetImageInfo"
            :library "nvJPEG" :not-found *nvjpeg-not-found*)
    :int
  (handle :pointer)
  (data :pointer)
  (length :size)
  (n-components :pointer)
  (subsampling :pointer)
  (widths :pointer)
  (heights :pointer))

(deflibfun (nvjpeg-jpeg-state-create "nvjpegJpegStateCreate"
            :library "nvJPEG" :not-found *nvjpeg-not-found*)
    :int
  (handle :pointer)
  (jpeg-handle :pointer))

(deflibfun (nvjpeg-jpeg-state-destroy "nvjpegJpegStateDestroy"
            :library "nvJPEG" :not-found *nvjpeg-not-found*)
    :int
  (jpeg-handle :pointer))
