#|
  This file is a part of the Chorus project.
  Copyright (c) 2016 Masayuki Takagi (kamonama@gmail.com)
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
|#

(in-package :cl-user)
(defpackage chorus-test.api.context
  (:use :cl :prove
        :chorus.api.context)
  (:import-from :cffi :null-pointer-p)
  (:import-from :chorus.api.nvcc :*nvcc-options* :arch-option-p))
(in-package :chorus-test.api.context)

(plan nil)


;;
;; WITH-CUDA macro

(subtest "arch-exists-p"

  (is (chorus.api.context::arch-exists-p '("-arch=sm_11"))
      t)

  (is (chorus.api.context::arch-exists-p '())
      nil)

  (is-error (chorus.api.context::arch-exists-p :foo)
            type-error
            "Invalid options."))

(subtest "append-arch"

  (let ((dev-id 0))
    (chorus.driver-api:cu-init 0)
    (is (chorus.api.context::append-arch '("foo") dev-id)
        (list (chorus.api.context::get-nvcc-arch dev-id)
              "foo")))

  (let ((dev-id 0))
    (is-error (chorus.api.context::append-arch :foo dev-id)
              type-error
              "Invalid options."))

  (is-error (chorus.api.context::append-arch nil :foo)
            type-error
            "Invalid device ID."))

(subtest "device-compute-capability"
  (chorus.driver-api:cu-init 0)
  (multiple-value-bind (major minor)
      (device-compute-capability 0)
    (ok (integerp major) "major is an integer")
    (ok (integerp minor) "minor is an integer")
    (ok (>= major 1) "compute capability is at least 1.x")
    (ok (<= 0 minor 9) "minor is a single digit")
    (is (chorus.api.nvcc:nvcc-arch-option major minor)
        (chorus.api.context::get-nvcc-arch 0)
        "arch option matches compute capability")))

(subtest "with-cuda bindings"
  (with-cuda (0)
    (ok (integerp *cuda-device*) "*cuda-device* is bound")
    (ok *cuda-context* "*cuda-context* is bound")
    (is (get-cuda-device 0) *cuda-device*)
    (ok (arch-option-p *nvcc-options*)
        "with-cuda inserts an nvcc architecture")
    (ok (search "-arch=sm_" (first *nvcc-options*))
        "architecture is sm_XY form")
    (ok (null-pointer-p *cuda-stream*)
        "default *cuda-stream* is the null stream")
    (synchronize-context))
  (ok (null (chorus.api.kernel-manager:kernel-manager-module-handle
             chorus.api.kernel-manager:*kernel-manager*))
      "kernel module is unloaded when with-cuda exits"))

(subtest "with-cuda preserves user -arch"
  (let ((chorus.api.nvcc:*nvcc-options* '("-arch=sm_120")))
    (with-cuda (0)
      (is chorus.api.nvcc:*nvcc-options* '("-arch=sm_120")
          "explicit -arch is not rewritten"))))

(finalize)
