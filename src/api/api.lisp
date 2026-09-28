#|
  This file is a part of the Chorus project.
  Copyright (c) 2014 Masayuki Takagi (kamonama@gmail.com)
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
|#

(in-package :cl-user)
(eval-when (:compile-toplevel :load-toplevel :execute)
  (locally
      (declare #+sbcl
               (sb-ext:muffle-conditions sb-kernel::package-at-variance))
    (handler-bind
        (#+sbcl (sb-kernel::package-at-variance #'muffle-warning))
      (defpackage chorus.api
        (:use :cl :cl-reexport)))))
(in-package :chorus.api)

(reexport-from :chorus.api.nvcc
               :include '(:*tmp-path*
                          :*nvcc-options*
                          :*nvcc-binary*
                          :find-nvcc
                          :nvcc-available-p
                          :nvcc-arch-option))
(reexport-from :chorus.api.context)
(reexport-from :chorus.api.memory)
(reexport-from :chorus.api.defkernel)
(reexport-from :chorus.api.macro)
(reexport-from :chorus.api.timer)

;; reexport no symbols from chorus.api.kernel-manager package
