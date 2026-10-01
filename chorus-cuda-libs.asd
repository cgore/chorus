#|
  This file is a part of the Chorus project.
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
|#

(defsystem "chorus-cuda-libs"
  :author "Masayuki Takagi, Christopher Mark Gore"
  :license "MIT"
  :depends-on ("chorus" "cffi" "alexandria")
  :components ((:module "source"
                :components
                ((:module "libs"
                  :serial t
                  :components
                  ((:file "package")
                   (:file "loader")
                   (:file "cublas")
                   (:file "cublas-lt")
                   (:file "cufft")
                   (:file "curand")
                   (:file "cusolver")
                   (:file "cusparse")
                   (:file "npp")
                   (:file "nvjpeg")
                   (:file "nccl")
                   (:file "cudnn"))))))
  :description "CUDA toolkit libraries for Chorus: cuBLAS, cuBLASLt, cuFFT, cuSPARSE, cuSOLVER, cuRAND, NPP, nvJPEG, and optional NCCL and cuDNN."
  :in-order-to ((test-op (test-op "chorus-cuda-libs-test"))))
