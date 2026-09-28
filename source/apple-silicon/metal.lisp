#|
  This file is a part of the Chorus project.
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
|#

(in-package :cl-user)
(defpackage chorus/apple-silicon
  (:use :cl)
  (:export :available-p
           :devices
           :device
           :device-name
           :device-pointer
           :metal-unavailable))
(in-package :chorus/apple-silicon)

(define-condition metal-unavailable (error) ()
  (:report "Metal is not available."))

(defvar *metal-loaded* nil)

(defclass device ()
  ((name :initarg :name :reader device-name)
   (pointer :initarg :pointer :reader device-pointer)))

(defmethod print-object ((device device) stream)
  (print-unreadable-object (device stream :type t :identity nil)
    (princ (device-name device) stream)))

#+darwin
(progn
  (cffi:define-foreign-library libobjc
    (:darwin (:default "libobjc")))
  (cffi:define-foreign-library corefoundation
    (:darwin (:framework "CoreFoundation")))
  (cffi:define-foreign-library metal
    (:darwin (:framework "Metal")))
  (handler-case
      (progn
        (cffi:use-foreign-library libobjc)
        (cffi:use-foreign-library corefoundation)
        (cffi:use-foreign-library metal)
        (setf *metal-loaded* t))
    (cffi:load-foreign-library-error (e)
      (setf *metal-loaded* nil)
      (princ e *error-output*)
      (terpri *error-output*))))

;;; MTLCopyAllDevices returns a retained array. Each device pointer from
;;; that array is owned by the array, so a device kept here is retained
;;; on its own and the array is released. UTF8String is an inner pointer
;;; and is copied before the string can go away.
#+darwin
(when *metal-loaded*
  (cffi:defcfun ("sel_registerName" sel-register-name) :pointer
    (name :string))
  (cffi:defcfun ("objc_msgSend" objc-msg-send) :pointer
    (self :pointer)
    (selector :pointer))
  (cffi:defcfun ("objc_msgSend" objc-msg-send-ulong) :unsigned-long
    (self :pointer)
    (selector :pointer))
  (cffi:defcfun ("objc_msgSend" objc-msg-send-at) :pointer
    (self :pointer)
    (selector :pointer)
    (index :unsigned-long))
  (cffi:defcfun ("MTLCopyAllDevices" mtl-copy-all-devices) :pointer)
  (cffi:defcfun ("CFRetain" cf-retain) :pointer
    (object :pointer))
  (cffi:defcfun ("CFRelease" cf-release) :void
    (object :pointer)))

(defvar *devices* nil)
(defvar *devices-probed* nil)

(defmacro without-fp-traps (&body body)
  #+sbcl
  `(sb-int:with-float-traps-masked (:underflow :overflow :inexact :invalid :divide-by-zero)
     ,@body)
  #-sbcl
  `(progn ,@body))

#+darwin
(defun selector (name)
  (sel-register-name name))

#+darwin
(defun nsstring-to-lisp (nsstring)
  (let ((utf8 (objc-msg-send nsstring (selector "UTF8String"))))
    (if (cffi:null-pointer-p utf8)
        ""
        (cffi:foreign-string-to-lisp utf8 :encoding :utf-8))))

#+darwin
(defun fetch-devices ()
  (without-fp-traps
    (let ((array (mtl-copy-all-devices)))
      (when (cffi:null-pointer-p array)
        (return-from fetch-devices nil))
      (unwind-protect
           (loop for index below (objc-msg-send-ulong array (selector "count"))
                 for pointer = (objc-msg-send-at array
                                                  (selector "objectAtIndex:")
                                                  index)
                 unless (cffi:null-pointer-p pointer)
                   collect (make-instance 'device
                                          :name (nsstring-to-lisp
                                                 (objc-msg-send pointer
                                                                (selector "name")))
                                          :pointer (cf-retain pointer)))
        (cf-release array)))))

(defun probe-devices ()
  (unless *devices-probed*
    (setf *devices* (when *metal-loaded*
                      #+darwin (fetch-devices)
                      #-darwin nil)
          *devices-probed* t))
  *devices*)

(defun available-p ()
  (and *metal-loaded* (probe-devices) t))

(defun devices ()
  (or (probe-devices)
      (error 'metal-unavailable)))
