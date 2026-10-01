#|
  This file is a part of the Chorus project.
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
|#

(in-package :chorus/cuda-libs)

;;; cuDNN is optional. cudnnGetVersion returns size_t and is not a status.
;;; The other entry points return cudnnStatus_t; 0 is success. Handles are
;;; pointers and enums are ints. cudnnConvolutionForward matches the cuDNN 9
;;; signature: alpha, x, filter, conv, algo, workspace, workspace size, beta, y.

(defvar *cudnn-not-found* nil
  "True when neither cudnn64_9.dll nor cudnn64_8.dll loaded.")

(setf *cudnn-not-found*
      (not (load-cuda-library "cuDNN" '("cudnn64_9.dll" "cudnn64_8.dll"))))

(deflibfun (cudnn-get-version "cudnnGetVersion"
            :library "cuDNN" :not-found *cudnn-not-found* :check-status nil)
    :size)

(deflibfun (cudnn-create "cudnnCreate"
            :library "cuDNN" :not-found *cudnn-not-found*)
    :int
  (handle :pointer))

(deflibfun (cudnn-destroy "cudnnDestroy"
            :library "cuDNN" :not-found *cudnn-not-found*)
    :int
  (handle :pointer))

(deflibfun (cudnn-create-tensor-descriptor "cudnnCreateTensorDescriptor"
            :library "cuDNN" :not-found *cudnn-not-found*)
    :int
  (tensor-desc :pointer))

(deflibfun (cudnn-destroy-tensor-descriptor "cudnnDestroyTensorDescriptor"
            :library "cuDNN" :not-found *cudnn-not-found*)
    :int
  (tensor-desc :pointer))

(deflibfun (cudnn-set-tensor-4d-descriptor "cudnnSetTensor4dDescriptor"
            :library "cuDNN" :not-found *cudnn-not-found*)
    :int
  (tensor-desc :pointer)
  (format :int)
  (data-type :int)
  (n :int)
  (c :int)
  (h :int)
  (w :int))

(deflibfun (cudnn-create-convolution-descriptor "cudnnCreateConvolutionDescriptor"
            :library "cuDNN" :not-found *cudnn-not-found*)
    :int
  (conv-desc :pointer))

(deflibfun (cudnn-destroy-convolution-descriptor "cudnnDestroyConvolutionDescriptor"
            :library "cuDNN" :not-found *cudnn-not-found*)
    :int
  (conv-desc :pointer))

(deflibfun (cudnn-set-convolution-2d-descriptor "cudnnSetConvolution2dDescriptor"
            :library "cuDNN" :not-found *cudnn-not-found*)
    :int
  (conv-desc :pointer)
  (pad-h :int)
  (pad-w :int)
  (stride-h :int)
  (stride-w :int)
  (dilation-h :int)
  (dilation-w :int)
  (mode :int)
  (compute-type :int))

(deflibfun (cudnn-convolution-forward "cudnnConvolutionForward"
            :library "cuDNN" :not-found *cudnn-not-found*)
    :int
  (handle :pointer)
  (alpha :pointer)
  (x-desc :pointer)
  (x :pointer)
  (w-desc :pointer)
  (w :pointer)
  (conv-desc :pointer)
  (algo :int)
  (workspace :pointer)
  (workspace-size-in-bytes :size)
  (beta :pointer)
  (y-desc :pointer)
  (y :pointer))
