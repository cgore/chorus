#|
  This file is a part of the Chorus project.
  Copyright (c) 2014 Masayuki Takagi (kamonama@gmail.com)
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
|#

(in-package :cl-user)
(defpackage chorus/interop/api
  (:use :cl :cl-reexport))
(in-package :chorus/interop/api)

(reexport-from :chorus/api
               :exclude '(;; context
                          :create-cuda-context
                          :with-cuda
                          ;; memory
                          :alloc-memory-block
                          :free-memory-block
                          :memory-block-p
                          :memory-block-device-ptr
                          :memory-block-host-ptr
                          :memory-block-type
                          :memory-block-size
                          :with-memory-block
                          :with-memory-blocks
                          :sync-memory-block
                          :memory-block-aref
                          ;; defkernel
                          :defkernel))
(reexport-from :chorus/interop/api/context)
(reexport-from :chorus/interop/api/memory)
(reexport-from :chorus/interop/api/defkernel)
