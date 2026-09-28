#|
  This file is a part of the Chorus project.
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
|#

(in-package :cl-user)
(defpackage chorus/backend
  (:use :cl)
  (:export :*backend*
           :backend
           :backend-name
           :backend-available-p
           :find-backend
           :current-backend
           :use-backend
           :with-backend
           :list-devices
           :device
           :device-name
           :device-native
           :device-backend
           :backend-unavailable
           :backend-not-found))
(in-package :chorus/backend)

(define-condition backend-not-found (error)
  ((name :initarg :name :reader backend-not-found-name))
  (:report (lambda (condition stream)
             (format stream "No backend named ~S."
                     (backend-not-found-name condition)))))

(define-condition backend-unavailable (error)
  ((backend :initarg :backend :reader backend-unavailable-backend))
  (:report (lambda (condition stream)
             (format stream "The ~A backend is not available."
                     (backend-name (backend-unavailable-backend condition))))))

(defclass backend ()
  ((name :initarg :name :reader backend-name)
   (available-p :initarg :available-p :reader %backend-available-p)
   (devices :initarg :devices :reader %backend-devices)))

(defmethod print-object ((backend backend) stream)
  (print-unreadable-object (backend stream :type t :identity nil)
    (princ (backend-name backend) stream)))

(defclass device ()
  ((backend :initarg :backend :reader device-backend)
   (name :initarg :name :reader device-name)
   (native :initarg :native :reader device-native)))

(defmethod print-object ((device device) stream)
  (print-unreadable-object (device stream :type t :identity nil)
    (format stream "~A ~A"
            (backend-name (device-backend device))
            (device-name device))))

(defvar *backends* ())

(defvar *backend* nil
  "The backend used by the generic interface. NIL selects the default.")

(defun register-backend (name available-p devices)
  (let ((backend (make-instance 'backend
                                :name name
                                :available-p available-p
                                :devices devices)))
    (setf *backends*
          (cons backend (remove name *backends* :key #'backend-name)))
    backend))

(defun find-backend (name)
  (etypecase name
    (backend name)
    (keyword
     (or (find name *backends* :key #'backend-name)
         (error 'backend-not-found :name name)))))

(defun backend-available-p (backend)
  (funcall (%backend-available-p (find-backend backend))))

(defgeneric native-device-name (device))
(defgeneric native-device-handle (device))

(defmethod native-device-name ((device chorus/apple-silicon:device))
  (chorus/apple-silicon:device-name device))

(defmethod native-device-handle ((device chorus/apple-silicon:device))
  (chorus/apple-silicon:device-pointer device))

(defmethod native-device-name ((device chorus/cuda:device))
  (chorus/cuda:device-name device))

(defmethod native-device-handle ((device chorus/cuda:device))
  (chorus/cuda:device-id device))

(defun preferred-backend-names ()
  #+darwin '(:apple-silicon :cuda)
  #-darwin '(:cuda :apple-silicon))

(defun default-backend ()
  (let ((names (preferred-backend-names)))
    (or (find-if #'backend-available-p (mapcar #'find-backend names))
        (find-backend (first names)))))

(defun current-backend ()
  (if *backend*
      (find-backend *backend*)
      (default-backend)))

(defun use-backend (backend)
  (setf *backend* (find-backend backend)))

(defmacro with-backend ((backend) &body body)
  `(let ((*backend* (find-backend ,backend)))
     ,@body))

(defun list-devices (&optional (backend nil backend-supplied-p))
  (let ((chosen (if backend-supplied-p
                    (find-backend backend)
                    (current-backend))))
    (unless (backend-available-p chosen)
      (error 'backend-unavailable :backend chosen))
    (mapcar (lambda (native)
              (make-instance 'device
                             :backend chosen
                             :name (native-device-name native)
                             :native (native-device-handle native)))
            (funcall (%backend-devices chosen)))))

(register-backend :cuda
                  #'chorus/cuda:available-p
                  #'chorus/cuda:devices)
(register-backend :apple-silicon
                  #'chorus/apple-silicon:available-p
                  #'chorus/apple-silicon:devices)
