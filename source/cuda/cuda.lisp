#|
  This file is a part of the Chorus project.
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
|#

(in-package :cl-user)
(defpackage chorus/cuda
  (:use :cl :cl-reexport)
  (:export :available-p
           :devices
           :device
           :device-name
           :device-id))
(in-package :chorus/cuda)

(reexport-from :chorus/driver-api)
(reexport-from :chorus/api)

(defclass device ()
  ((name :initarg :name :reader device-name)
   (id :initarg :id :reader device-id)))

(defmethod print-object ((device device) stream)
  (print-unreadable-object (device stream :type t :identity nil)
    (princ (device-name device) stream)))

(defun available-p ()
  (not chorus/driver-api:*sdk-not-found*))

(defun device-count ()
  (unless (available-p)
    (error 'chorus/driver-api:sdk-not-found-error))
  (chorus/driver-api:cu-init 0)
  (cffi:with-foreign-object (count :int)
    (chorus/driver-api:cu-device-get-count count)
    (cffi:mem-ref count :int)))

(defun %device-name (id)
  (cffi:with-foreign-object (buffer :char 256)
    (chorus/driver-api:cu-device-get-name buffer 256 id)
    (cffi:foreign-string-to-lisp buffer)))

(defun devices ()
  (loop for ordinal below (device-count)
        for id = (chorus/api/context:get-cuda-device ordinal)
        collect (make-instance 'device
                               :name (%device-name id)
                               :id id)))
