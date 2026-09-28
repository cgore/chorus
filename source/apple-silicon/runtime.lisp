#|
  This file is a part of the Chorus project.
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
|#

(in-package :chorus/apple-silicon)

(define-condition metal-error (error)
  ((message :initarg :message :reader metal-error-message))
  (:report (lambda (condition stream)
             (write-string (metal-error-message condition) stream))))

(defvar *device* nil)
(defvar *command-queue* nil)
(defvar *shim-loaded* nil)

(defclass owned ()
  ((cell :initarg :cell :reader object-cell)))

(defclass command-queue (owned) ())

(defclass buffer (owned)
  ((element-type :initarg :element-type :reader buffer-element-type)
   (count :initarg :count :reader buffer-count)))

(defclass library (owned) ())

(defclass metal-function (owned) ())

(defclass pipeline (owned)
  ((execution-width :initarg :execution-width :reader pipeline-execution-width)
   (max-threads :initarg :max-threads :reader pipeline-max-threads)
   (library :initarg :library :reader pipeline-library)))

(defun shim-source ()
  (asdf:system-relative-pathname :chorus "source/apple-silicon/chorus-metal.m"))

(defun shim-library ()
  (let ((directory (merge-pathnames ".cache/chorus/"
                                    (user-homedir-pathname))))
    (ensure-directories-exist directory)
    (merge-pathnames "libchorus-metal.dylib" directory)))

(defun compile-shim ()
  (let* ((source (shim-source))
         (library (shim-library))
         (command (list "xcrun" "clang" "-fobjc-arc" "-dynamiclib"
                        "-framework" "Foundation" "-framework" "Metal"
                        "-o" (namestring library) (namestring source))))
    (multiple-value-bind (output error-output code)
        (uiop:run-program command
                          :output :string
                          :error-output :string
                          :ignore-error-status t
                          :force-shell nil)
      (declare (ignore output))
      (unless (zerop code)
        (error 'metal-error
               :message (format nil "clang failed to build the Metal shim.~%~A"
                                error-output))))
    library))

(defun ensure-shim ()
  (unless *shim-loaded*
    (let ((library (shim-library)))
      (when (or (not (probe-file library))
                (> (file-write-date (shim-source))
                   (file-write-date library)))
        (compile-shim))
      (cffi:load-foreign-library library)
      (setf *shim-loaded* t)))
  *shim-loaded*)

(defun metal-string-error (pointer)
  (unless (cffi:null-pointer-p pointer)
    (unwind-protect
         (cffi:foreign-string-to-lisp pointer :encoding :utf-8)
      (cffi:foreign-funcall "chorus_metal_free_string"
                            :pointer pointer
                            :void))))

(defun object-pointer (object)
  (or (car (object-cell object))
      (error 'metal-error :message "The Metal object has been released.")))

(defun release (object)
  (let* ((cell (object-cell object))
         (pointer (car cell)))
    (when pointer
      (setf (car cell) nil)
      (ensure-shim)
      (cffi:foreign-funcall "chorus_metal_release" :pointer pointer :void)))
  nil)

(defun adopt (class pointer &rest initargs)
  (when (cffi:null-pointer-p pointer)
    (error 'metal-error :message "Metal returned a null object."))
  (let* ((cell (list pointer))
         (object (apply #'make-instance class :cell cell initargs)))
    #+sbcl
    (sb-ext:finalize object
                     (lambda ()
                       (let ((held (car cell)))
                         (when held
                           (setf (car cell) nil)
                           (cffi:foreign-funcall "chorus_metal_release"
                                                 :pointer held
                                                 :void)))))
    object))

(defun make-command-queue (device)
  (ensure-shim)
  (adopt 'command-queue
         (cffi:foreign-funcall "chorus_metal_new_queue"
                               :pointer (device-pointer device)
                               :pointer)))

(defmacro with-device ((var &optional (ordinal 0)) &body body)
  `(let* ((,var (or (nth ,ordinal (devices))
                    (error 'metal-unavailable)))
          (*device* ,var)
          (*command-queue* (make-command-queue ,var)))
     (unwind-protect
          (locally ,@body)
       (release *command-queue*))))

(defun cffi-element-type (type)
  (let ((name (symbol-name type)))
    (cond ((string-equal name "FLOAT") :float)
          ((string-equal name "INT") :int32)
          ((string-equal name "DOUBLE") :double)
          (t (error 'metal-error
                    :message (format nil "Unsupported Metal element type ~A."
                                     type))))))

(defun element-size (type)
  (cffi:foreign-type-size (cffi-element-type type)))

(defun make-buffer (device count element-type)
  (check-type count (integer 1))
  (ensure-shim)
  (let ((bytes (* count (element-size element-type))))
    (adopt 'buffer
           (cffi:foreign-funcall "chorus_metal_new_buffer"
                                 :pointer (device-pointer device)
                                 :unsigned-long bytes
                                 :pointer)
           :element-type element-type
           :count count)))

(defun call-with-buffers (specs function)
  (let ((buffers nil))
    (unwind-protect
         (progn
           (dolist (spec specs)
             (push (make-buffer *device* (second spec) (first spec))
                   buffers))
           (setq buffers (nreverse buffers))
           (apply function buffers))
      (mapc #'release buffers))))

(defmacro with-buffers (bindings &body body)
  `(call-with-buffers
    (list ,@(mapcar (lambda (binding)
                      `(list ',(second binding) ,(third binding)))
                    bindings))
    (lambda ,(mapcar #'first bindings)
      ,@body)))

(defun buffer-contents (buffer)
  (ensure-shim)
  (cffi:foreign-funcall "chorus_metal_buffer_contents"
                        :pointer (object-pointer buffer)
                        :pointer))

(defun buffer-aref (buffer index)
  (cffi:mem-aref (buffer-contents buffer)
                 (cffi-element-type (buffer-element-type buffer))
                 index))

(defun (setf buffer-aref) (value buffer index)
  (setf (cffi:mem-aref (buffer-contents buffer)
                       (cffi-element-type (buffer-element-type buffer))
                       index)
        value))

(defun take-result (pointer error-pointer)
  (let ((message (metal-string-error (cffi:mem-ref error-pointer :pointer))))
    (when message
      (error 'metal-error :message message))
    (when (cffi:null-pointer-p pointer)
      (error 'metal-error :message "Metal returned a null object."))
    pointer))

(defun compile-source (device source)
  (ensure-shim)
  (cffi:with-foreign-object (error-pointer :pointer)
    (setf (cffi:mem-ref error-pointer :pointer) (cffi:null-pointer))
    (adopt 'library
           (take-result
            (cffi:foreign-funcall "chorus_metal_compile"
                                  :pointer (device-pointer device)
                                  :string source
                                  :pointer error-pointer
                                  :pointer)
            error-pointer))))

(defun library-function (library name)
  (ensure-shim)
  (cffi:with-foreign-object (error-pointer :pointer)
    (setf (cffi:mem-ref error-pointer :pointer) (cffi:null-pointer))
    (adopt 'metal-function
           (take-result
            (cffi:foreign-funcall "chorus_metal_function"
                                  :pointer (object-pointer library)
                                  :string name
                                  :pointer error-pointer
                                  :pointer)
            error-pointer))))

(defun make-pipeline (device function)
  (ensure-shim)
  (cffi:with-foreign-object (error-pointer :pointer)
    (setf (cffi:mem-ref error-pointer :pointer) (cffi:null-pointer))
    (let ((pipeline (adopt 'pipeline
                           (take-result
                            (cffi:foreign-funcall
                             "chorus_metal_pipeline"
                             :pointer (device-pointer device)
                             :pointer (object-pointer function)
                             :pointer error-pointer
                             :pointer)
                            error-pointer)
                           :library nil
                           :execution-width 0
                           :max-threads 0)))
      (setf (slot-value pipeline 'execution-width)
            (cffi:foreign-funcall "chorus_metal_execution_width"
                                  :pointer (object-pointer pipeline)
                                  :unsigned-long))
      (setf (slot-value pipeline 'max-threads)
            (cffi:foreign-funcall "chorus_metal_max_threads"
                                  :pointer (object-pointer pipeline)
                                  :unsigned-long))
      pipeline)))

(defun dimension (values axis)
  (or (nth axis values) 1))

(defun default-group (pipeline threads)
  (let* ((width (pipeline-execution-width pipeline))
         (limit (max 1 (pipeline-max-threads pipeline)))
         (needed (max 1 (dimension threads 0)))
         (group (min needed limit)))
    (when (and (> width 1) (>= group width))
      (setq group (* width (floor group width))))
    (list (max 1 group) 1 1)))

(defun coerce-scalar (type value)
  (let ((name (symbol-name type)))
    (cond ((string-equal name "INT") (truncate value))
          ((string-equal name "FLOAT") (float value 1.0))
          ((string-equal name "DOUBLE") (float value 1.0d0))
          (t (error 'metal-error
                    :message (format nil "Unsupported Metal scalar type ~A."
                                     type))))))

(defun launch (pipeline buffers scalars threads threads-per-group)
  (ensure-shim)
  (let* ((group (or threads-per-group (default-group pipeline threads)))
         (buffer-count (length buffers))
         (scalar-count (length scalars))
         (scalar-pointers nil))
    (unwind-protect
         (cffi:with-foreign-objects ((buffer-array :pointer (max 1 buffer-count))
                                     (scalar-array :pointer (max 1 scalar-count))
                                     (length-array :unsigned-long (max 1 scalar-count))
                                     (error-pointer :pointer))
           (loop for buffer in buffers
                 for index from 0
                 do (setf (cffi:mem-aref buffer-array :pointer index)
                          (object-pointer buffer)))
           (loop for (type value) in scalars
                 for index from 0
                 for cffi-type = (cffi-element-type type)
                 for pointer = (cffi:foreign-alloc cffi-type :count 1)
                 do (push pointer scalar-pointers)
                    (setf (cffi:mem-ref pointer cffi-type)
                          (coerce-scalar type value))
                    (setf (cffi:mem-aref scalar-array :pointer index) pointer)
                    (setf (cffi:mem-aref length-array :unsigned-long index)
                          (cffi:foreign-type-size cffi-type)))
           (setf (cffi:mem-ref error-pointer :pointer) (cffi:null-pointer))
           (let ((code (cffi:foreign-funcall
                        "chorus_metal_dispatch"
                        :pointer (object-pointer *command-queue*)
                        :pointer (object-pointer pipeline)
                        :pointer buffer-array
                        :unsigned-long buffer-count
                        :pointer scalar-array
                        :pointer length-array
                        :unsigned-long scalar-count
                        :unsigned-long (dimension threads 0)
                        :unsigned-long (dimension threads 1)
                        :unsigned-long (dimension threads 2)
                        :unsigned-long (dimension group 0)
                        :unsigned-long (dimension group 1)
                        :unsigned-long (dimension group 2)
                        :pointer error-pointer
                        :int)))
             (let ((message (metal-string-error
                             (cffi:mem-ref error-pointer :pointer))))
               (unless (zerop code)
                 (error 'metal-error
                        :message (or message "Metal dispatch failed."))))))
      (mapc #'cffi:foreign-free scalar-pointers)))
  pipeline)

(defvar *pipeline-cache* (make-hash-table :test #'equal))

(defun cached-pipeline (device source function-name)
  (let ((key (list (cffi:pointer-address (device-pointer device))
                   function-name
                   source)))
    (or (gethash key *pipeline-cache*)
        (let* ((library (compile-source device source))
               (function (library-function library function-name)))
          (unwind-protect
               (let ((pipeline (make-pipeline device function)))
                 (setf (slot-value pipeline 'library) library)
                 (setf (gethash key *pipeline-cache*) pipeline))
            (release function))))))

(defun launch-kernel (device queue source function-name buffers scalars
                      threads threads-per-group)
  (unless (and device queue)
    (error 'metal-error
           :message "with-device binds *device* and *command-queue*."))
  (let ((*device* device)
        (*command-queue* queue))
    (launch (cached-pipeline device source function-name)
            buffers scalars threads threads-per-group)))
