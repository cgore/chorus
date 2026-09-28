#|
  This file is a part of the Chorus project.
  Copyright (c) 2014 Masayuki Takagi (kamonama@gmail.com)
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
|#


(in-package :chorus/driver-api)


;;;
;;; DEFCUENUM macro
;;;

(eval-when (:compile-toplevel :load-toplevel)
  (defun defconstant-enum-value (name enum-elem)
    (let ((keyword (car enum-elem)))
      `(defconstant ,(symbolicate keyword)
         (cffi:foreign-enum-value ',name ,keyword)))))

(defmacro defcuenum (name-and-options &body enum-list)
  (let ((name name-and-options))
    `(progn
       (cffi:defcenum ,name
         ,@enum-list)
       ,@(mapcar (lambda (enum-elem)
                   (defconstant-enum-value name enum-elem))
                 enum-list))))


;;;
;;; Enumerations
;;;

(defcuenum cu-event-flags-enum
  (:cu-event-default        #X0)
  (:cu-event-blocking-sync  #X1)
  (:cu-event-disable-timing #X2)
  (:cu-event-interprocess   #X4))

(defcuenum cu-stream-flags-enum
  (:cu-stream-default       #X0)
  (:cu-stream-non-blocking  #X1))

(defcuenum cu-mem-host-register-flags-enum
  (:cu-mem-host-register-portable  #X1)
  (:cu-mem-host-register-devicemap #X2))

;; From CUdevice_attribute. Only the compute-capability queries are bound;
;; the rest of the enum is large and unused by chorus.
(defconstant cu-device-attribute-compute-capability-major 75)
(defconstant cu-device-attribute-compute-capability-minor 76)
