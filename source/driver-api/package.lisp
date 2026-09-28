#|
  This file is a part of the Chorus project.
  Copyright (c) 2014-2016 Masayuki Takagi (kamonama@gmail.com)
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
|#

(in-package :cl-user)
(defpackage chorus/driver-api
  (:use :cl)
  (:export ;; Types
           :cu-result
           :cu-device
           :cu-context
           :cu-module
           :cu-function
           :cu-stream
           :cu-event
           :cu-device-ptr
           :size-t
           ;; Enumerations
           :cu-event-default
           :cu-event-blocking-sync
           :cu-event-disable-timing
           :cu-event-interprocess
           ;; Functions
           :cu-init
           :cu-device-get
           :cu-device-get-count
           :cu-device-compute-capability
           :cu-device-get-attribute
           :cu-device-attribute-compute-capability-major
           :cu-device-attribute-compute-capability-minor
           :cu-device-get-name
           :cu-ctx-create
           :cu-ctx-destroy
           :cu-ctx-synchronize
           :cu-device-total-mem
           :cu-mem-alloc
           :cu-mem-free
           :cu-mem-host-register
           :cu-mem-host-unregister
           :cu-memcpy-host-to-device
           :cu-memcpy-host-to-device-async
           :cu-memcpy-device-to-host
           :cu-memcpy-device-to-host-async
           :cu-module-load
           :cu-module-unload
           :cu-module-get-function
           :cu-module-get-global
           :cu-launch-kernel
           :cu-event-create
           :cu-event-destroy
           :cu-event-elapsed-time
           :cu-event-record
           :cu-event-synchronize
           :cu-stream-create
           :cu-stream-destroy
           :cu-stream-query
           :cu-stream-synchronize
           :cu-stream-wait-event
           ;; Variables
           :*show-messages*
           :*sdk-not-found*)
  (:import-from :alexandria
                :format-symbol
                :symbolicate))
