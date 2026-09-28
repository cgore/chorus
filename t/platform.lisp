#|
  This file is a part of the Chorus project.
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
|#

(in-package :cl-user)
(defpackage chorus/test/platform
  (:use :cl :prove
        :chorus/driver-api))
(in-package :chorus/test/platform)

(plan nil)

(diag "platform / FFI types")

(subtest "size_t matches pointer width"
  (is (cffi:foreign-type-size 'size-t)
      (cffi:foreign-type-size :pointer)
      "size_t is pointer-sized (8 bytes on 64-bit Windows and Unix)")
  (is (cffi:foreign-type-size 'cu-device-ptr)
      8
      "CUdeviceptr is 64-bit"))

(subtest "opaque driver types"
  (is (cffi:foreign-type-size 'cu-device) (cffi:foreign-type-size :int)
      "CUdevice is an int")
  (is (cffi:foreign-type-size 'cu-context) (cffi:foreign-type-size :pointer))
  (is (cffi:foreign-type-size 'cu-module) (cffi:foreign-type-size :pointer))
  (is (cffi:foreign-type-size 'cu-function) (cffi:foreign-type-size :pointer))
  (is (cffi:foreign-type-size 'cu-stream) (cffi:foreign-type-size :pointer))
  (is (cffi:foreign-type-size 'cu-event) (cffi:foreign-type-size :pointer)))

(subtest "driver error strings"
  (is (chorus/driver-api::get-error-string 0) "CUDA_SUCCESS")
  (is (chorus/driver-api::get-error-string 700) "CUDA_ERROR_ILLEGAL_ADDRESS")
  (is (chorus/driver-api::get-error-string 719) "CUDA_ERROR_LAUNCH_FAILED")
  (is (chorus/driver-api::get-error-string 218) "CUDA_ERROR_INVALID_PTX")
  (is (chorus/driver-api::get-error-string 221) "CUDA_ERROR_JIT_COMPILER_NOT_FOUND")
  (is (chorus/driver-api::get-error-string 222) "CUDA_ERROR_UNSUPPORTED_PTX_VERSION")
  (is (chorus/driver-api::get-error-string 801) "CUDA_ERROR_NOT_SUPPORTED")
  (is (chorus/driver-api::get-error-string 123456)
      "CUDA_ERROR_UNKNOWN_CODE_123456"
      "unknown codes do not signal"))

(subtest "CUDA driver library"
  (ok (not *sdk-not-found*)
      "nvcuda.dll / libcuda loaded")
  (is *sdk-not-found* nil)
  (ok (member :cuda-sdk *features*)
      ":cuda-sdk is on *features* after a successful load"))

(finalize)
