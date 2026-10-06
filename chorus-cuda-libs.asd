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
                  :components
                  ((:file "package")
                   (:file "loader"
                    :depends-on ("package"))
                   (:file "cublas"
                    :depends-on ("loader" "package"))
                   (:file "cublas-lt"
                    :depends-on ("loader" "package"))
                   (:file "cufft"
                    :depends-on ("loader" "package"))
                   (:file "curand"
                    :depends-on ("loader" "package"))
                   (:file "cusolver"
                    :depends-on ("loader" "package"))
                   (:file "cusparse"
                    :depends-on ("loader" "package"))
                   (:file "npp"
                    :depends-on ("loader" "package"))
                   (:file "nvjpeg"
                    :depends-on ("loader" "package"))
                   (:file "nccl"
                    :depends-on ("loader" "package"))
                   (:file "cudnn"
                    :depends-on ("loader" "package")))))))
  :description "CUDA toolkit libraries for Chorus: cuBLAS, cuBLASLt, cuFFT, cuSPARSE, cuSOLVER, cuRAND, NPP, nvJPEG, and optional NCCL and cuDNN."
  :in-order-to ((test-op (test-op "chorus-cuda-libs-test"))))
