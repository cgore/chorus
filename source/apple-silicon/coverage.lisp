#|
  This file is a part of the Chorus project.
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
|#

(in-package :chorus/apple-silicon)

;;; MTLGPUFamily values from MTLDevice.h. Apple1 through Apple11 are
;;; consecutive. Resource option values are the storage mode shifted by
;;; MTLResourceStorageModeShift, which is 4. MTLCommandBufferStatusCompleted
;;; is 4.
(defconstant +gpu-family-apple1+ 1001)
(defconstant +gpu-family-apple11+ 1011)
(defconstant +gpu-family-metal3+ 5001)
(defconstant +gpu-family-metal4+ 5002)
(defconstant +storage-mode-shared+ 0)
(defconstant +storage-mode-managed+ 1)
(defconstant +storage-mode-private+ 2)
(defconstant +storage-mode-memoryless+ 3)
(defconstant +resource-storage-shared+ 0)
(defconstant +resource-storage-managed+ 16)
(defconstant +resource-storage-private+ 32)
(defconstant +resource-storage-memoryless+ 48)
(defconstant +command-buffer-status-completed+ 4)

(defmacro with-metal-error (&body body)
  "Run BODY. Its first value is a Metal status code. Zero is success.
The remaining values are returned. The body reads ERROR-POINTER."
  `(without-fp-traps
     (ensure-shim)
     (cffi:with-foreign-object (error-pointer :pointer)
       (setf (cffi:mem-ref error-pointer :pointer) (cffi:null-pointer))
       (let ((values (multiple-value-list (progn ,@body))))
         (let ((message (metal-string-error
                         (cffi:mem-ref error-pointer :pointer))))
           (unless (zerop (first values))
             (error 'metal-error
                    :message (or message "Metal call failed.")))
           (values-list (rest values)))))))

(defun read-bytes (pointer count)
  (let ((bytes (make-array count :element-type '(unsigned-byte 8))))
    (dotimes (index count)
      (setf (aref bytes index)
            (cffi:mem-aref pointer :unsigned-char index)))
    bytes))

(defun write-bytes (pointer bytes)
  (dotimes (index (length bytes))
    (setf (cffi:mem-aref pointer :unsigned-char index)
          (aref bytes index)))
  bytes)

(defun split-lines (text)
  (if text
      (delete "" (uiop:split-string text :separator '(#\Newline))
              :test #'string=)
      nil))

(defun protocol-names ()
  (cffi:with-foreign-object (names :pointer)
    (setf (cffi:mem-ref names :pointer) (cffi:null-pointer))
    (with-metal-error
      (let ((status (cffi:foreign-funcall "chorus_metal_copy_protocol_names"
                                          :pointer names
                                          :pointer error-pointer
                                          :int)))
        (if (zerop status)
            (values status (split-lines
                            (metal-string-error
                             (cffi:mem-ref names :pointer))))
            (values status nil))))))

(defun %device-info (pointer)
  (ensure-shim)
  (cffi:with-foreign-objects ((registry :unsigned-long-long)
                              (unified :int)
                              (memory :unsigned-long)
                              (working :unsigned-long-long))
    (cffi:foreign-funcall "chorus_metal_device_info"
                          :pointer pointer
                          :pointer registry
                          :pointer unified
                          :pointer memory
                          :pointer working
                          :void)
    (values (cffi:mem-ref registry :unsigned-long-long)
            (plusp (cffi:mem-ref unified :int))
            (cffi:mem-ref memory :unsigned-long)
            (cffi:mem-ref working :unsigned-long-long))))

(defun device-info (device)
  (%device-info (device-pointer device)))

(defun default-device-registry-id ()
  (ensure-shim)
  (cffi:with-foreign-object (error-pointer :pointer)
    (setf (cffi:mem-ref error-pointer :pointer) (cffi:null-pointer))
    (let ((pointer (take-result
                    (cffi:foreign-funcall "chorus_metal_default_device"
                                          :pointer error-pointer
                                          :pointer)
                    error-pointer)))
      (unwind-protect
           (nth-value 0 (%device-info pointer))
        (cffi:foreign-funcall "chorus_metal_release"
                              :pointer pointer
                              :void)))))

(defun supports-family (device family)
  (ensure-shim)
  (plusp (cffi:foreign-funcall "chorus_metal_device_supports_family"
                               :pointer (device-pointer device)
                               :long family
                               :int)))

(defun command-queue-label (queue)
  (ensure-shim)
  (or (metal-string-error
       (cffi:foreign-funcall "chorus_metal_queue_label"
                             :pointer (object-pointer queue)
                             :pointer))
      ""))

(defun (setf command-queue-label) (label queue)
  (ensure-shim)
  (cffi:foreign-funcall "chorus_metal_queue_set_label"
                        :pointer (object-pointer queue)
                        :string label
                        :void)
  label)

(defun buffer-with-options (device bytes options)
  (check-type bytes (integer 1))
  (ensure-shim)
  (cffi:with-foreign-object (error-pointer :pointer)
    (setf (cffi:mem-ref error-pointer :pointer) (cffi:null-pointer))
    (adopt 'buffer
           (take-result
            (cffi:foreign-funcall "chorus_metal_buffer_with_options"
                                  :pointer (device-pointer device)
                                  :unsigned-long bytes
                                  :unsigned-long options
                                  :pointer error-pointer
                                  :pointer)
            error-pointer)
           :element-type 'unsigned-byte
           :count bytes)))

(defun buffer-storage-mode (buffer)
  (ensure-shim)
  (cffi:foreign-funcall "chorus_metal_buffer_storage_mode"
                        :pointer (object-pointer buffer)
                        :unsigned-long))

(defun buffer-contents-p (buffer)
  (ensure-shim)
  (plusp (cffi:foreign-funcall "chorus_metal_buffer_has_contents"
                               :pointer (object-pointer buffer)
                               :int)))

(defun buffer-byte (buffer index)
  (cffi:mem-aref (buffer-contents buffer) :unsigned-char index))

(defun (setf buffer-byte) (value buffer index)
  (setf (cffi:mem-aref (buffer-contents buffer) :unsigned-char index) value))

(defun blit-fill (queue buffer value size)
  (with-metal-error
    (cffi:foreign-funcall "chorus_metal_blit_fill"
                          :pointer (object-pointer queue)
                          :pointer (object-pointer buffer)
                          :unsigned-char value
                          :unsigned-long size
                          :pointer error-pointer
                          :int)))

(defun blit-copy (queue source destination size)
  (with-metal-error
    (cffi:foreign-funcall "chorus_metal_blit_copy"
                          :pointer (object-pointer queue)
                          :pointer (object-pointer source)
                          :pointer (object-pointer destination)
                          :unsigned-long size
                          :pointer error-pointer
                          :int)))

(defun shim-pointer (name)
  (or (cffi:foreign-symbol-pointer name)
      (error 'metal-error :message (format nil "Metal shim is missing ~A." name))))

(defun call-device-queue-int (c-name device queue)
  (cffi:with-foreign-object (value :int)
    (with-metal-error
      (values
       (cffi:foreign-funcall-pointer (shim-pointer c-name) ()
                                     :pointer (device-pointer device)
                                     :pointer (object-pointer queue)
                                     :pointer value
                                     :pointer error-pointer
                                     :int)
       (cffi:mem-ref value :int)))))

(defun private-roundtrip (device queue)
  (call-device-queue-int "chorus_metal_private_roundtrip" device queue))

(defun managed-roundtrip (device queue)
  (cffi:with-foreign-objects ((mode :unsigned-long)
                              (value :int))
    (with-metal-error
      (values
       (cffi:foreign-funcall "chorus_metal_managed_roundtrip"
                             :pointer (device-pointer device)
                             :pointer (object-pointer queue)
                             :pointer mode
                             :pointer value
                             :pointer error-pointer
                             :int)
       (cffi:mem-ref mode :unsigned-long)
       (cffi:mem-ref value :int)))))

(defun texture-roundtrip (device pixel)
  (cffi:with-foreign-object (foreign :unsigned-char 4)
    (write-bytes foreign pixel)
    (with-metal-error
      (values
       (cffi:foreign-funcall "chorus_metal_texture_roundtrip"
                             :pointer (device-pointer device)
                             :pointer foreign
                             :pointer error-pointer
                             :int)
       (read-bytes foreign 4)))))

(defun heap-used-size (device)
  (cffi:with-foreign-object (used :unsigned-long)
    (with-metal-error
      (values
       (cffi:foreign-funcall "chorus_metal_heap_used"
                             :pointer (device-pointer device)
                             :pointer used
                             :pointer error-pointer
                             :int)
       (cffi:mem-ref used :unsigned-long)))))

(defun sampler-and-depth-states (device)
  (with-metal-error
    (cffi:foreign-funcall "chorus_metal_make_states"
                          :pointer (device-pointer device)
                          :pointer error-pointer
                          :int)))

(defun render-triangle (device queue width height)
  (let ((count (* width height 4))
        (pixels (cffi:foreign-alloc :unsigned-char :count (* width height 4))))
    (unwind-protect
         (cffi:with-foreign-object (writes :unsigned-int)
           (with-metal-error
             (values
              (cffi:foreign-funcall "chorus_metal_render_triangle"
                                    :pointer (device-pointer device)
                                    :pointer (object-pointer queue)
                                    :pointer pixels
                                    :unsigned-long width
                                    :unsigned-long height
                                    :pointer writes
                                    :pointer error-pointer
                                    :int)
              (read-bytes pixels count)
              (cffi:mem-ref writes :unsigned-int))))
      (cffi:foreign-free pixels))))

(defun timed-dispatch (device queue)
  (cffi:with-foreign-objects ((ran :int)
                              (status :int)
                              (start :double)
                              (end :double))
    (with-metal-error
      (values
       (cffi:foreign-funcall "chorus_metal_timed_dispatch"
                             :pointer (device-pointer device)
                             :pointer (object-pointer queue)
                             :pointer ran
                             :pointer status
                             :pointer start
                             :pointer end
                             :pointer error-pointer
                             :int)
       (plusp (cffi:mem-ref ran :int))
       (cffi:mem-ref status :int)
       (cffi:mem-ref start :double)
       (cffi:mem-ref end :double)))))

(defun fence-order (device queue)
  (call-device-queue-int "chorus_metal_fence_order" device queue))

(defun shared-event-order (device)
  (cffi:with-foreign-object (value :int)
    (with-metal-error
      (values
       (cffi:foreign-funcall "chorus_metal_shared_event_order"
                             :pointer (device-pointer device)
                             :pointer value
                             :pointer error-pointer
                             :int)
       (cffi:mem-ref value :int)))))

(defun indirect-dispatch (device queue)
  (call-device-queue-int "chorus_metal_indirect_dispatch" device queue))

(defun indirect-commands (device queue)
  (call-device-queue-int "chorus_metal_indirect_commands" device queue))

(defun argument-buffer (device queue)
  (call-device-queue-int "chorus_metal_argument_buffer" device queue))

(defun function-constant (device queue constant)
  (cffi:with-foreign-object (value :int)
    (with-metal-error
      (values
       (cffi:foreign-funcall "chorus_metal_function_constant"
                             :pointer (device-pointer device)
                             :pointer (object-pointer queue)
                             :int constant
                             :pointer value
                             :pointer error-pointer
                             :int)
       (cffi:mem-ref value :int)))))

(defun threadgroup-sum (device queue)
  (call-device-queue-int "chorus_metal_threadgroup" device queue))

(defun sample-texture (device queue)
  (cffi:with-foreign-object (value :float)
    (with-metal-error
      (values
       (cffi:foreign-funcall "chorus_metal_sample_texture"
                             :pointer (device-pointer device)
                             :pointer (object-pointer queue)
                             :pointer value
                             :pointer error-pointer
                             :int)
       (cffi:mem-ref value :float)))))

(defun call-pixel (c-name device queue)
  (cffi:with-foreign-object (pixel :unsigned-char 4)
    (with-metal-error
      (values
       (cffi:foreign-funcall-pointer (shim-pointer c-name) ()
                                     :pointer (device-pointer device)
                                     :pointer (object-pointer queue)
                                     :pointer pixel
                                     :pointer error-pointer
                                     :int)
       (read-bytes pixel 4)))))

(defun mipmap-pixel (device queue)
  (call-pixel "chorus_metal_mipmap" device queue))

(defun trace-ray (device queue)
  (cffi:with-foreign-object (distance :float)
    (with-metal-error
      (values
       (cffi:foreign-funcall "chorus_metal_trace_ray"
                             :pointer (device-pointer device)
                             :pointer (object-pointer queue)
                             :pointer distance
                             :pointer error-pointer
                             :int)
       (cffi:mem-ref distance :float)))))

(defun metal4-compute (device)
  (cffi:with-foreign-objects ((value :int)
                              (learning :int))
    (with-metal-error
      (values
       (cffi:foreign-funcall "chorus_metal4_compute"
                             :pointer (device-pointer device)
                             :pointer value
                             :pointer learning
                             :pointer error-pointer
                             :int)
       (cffi:mem-ref value :int)
       (plusp (cffi:mem-ref learning :int))))))

(defun residency-count (device)
  (cffi:with-foreign-object (count :unsigned-long)
    (with-metal-error
      (values
       (cffi:foreign-funcall "chorus_metal_residency_count"
                             :pointer (device-pointer device)
                             :pointer count
                             :pointer error-pointer
                             :int)
       (cffi:mem-ref count :unsigned-long)))))

(defun tensor-extents (device)
  (cffi:with-foreign-objects ((extent0 :long)
                              (extent1 :long))
    (with-metal-error
      (values
       (cffi:foreign-funcall "chorus_metal_tensor"
                             :pointer (device-pointer device)
                             :pointer extent0
                             :pointer extent1
                             :pointer error-pointer
                             :int)
       (cffi:mem-ref extent0 :long)
       (cffi:mem-ref extent1 :long)))))

(defun shader-log (device queue)
  (cffi:with-foreign-object (message :pointer)
    (setf (cffi:mem-ref message :pointer) (cffi:null-pointer))
    (with-metal-error
      (let ((status (cffi:foreign-funcall "chorus_metal_shader_log"
                                          :pointer (device-pointer device)
                                          :pointer (object-pointer queue)
                                          :pointer message
                                          :pointer error-pointer
                                          :int)))
        (if (zerop status)
            (values status (or (metal-string-error
                                (cffi:mem-ref message :pointer))
                               ""))
            (values status ""))))))

(defun capture-trace (device queue path)
  (cffi:with-foreign-object (supported :int)
    (with-metal-error
      (values
       (cffi:foreign-funcall "chorus_metal_capture"
                             :pointer (device-pointer device)
                             :pointer (object-pointer queue)
                             :string path
                             :pointer supported
                             :pointer error-pointer
                             :int)
       (plusp (cffi:mem-ref supported :int))))))

(defun counter-sample (device queue)
  (cffi:with-foreign-objects ((supported :int)
                              (bytes :unsigned-long))
    (with-metal-error
      (values
       (cffi:foreign-funcall "chorus_metal_counter"
                             :pointer (device-pointer device)
                             :pointer (object-pointer queue)
                             :pointer supported
                             :pointer bytes
                             :pointer error-pointer
                             :int)
       (plusp (cffi:mem-ref supported :int))
       (cffi:mem-ref bytes :unsigned-long)))))

(defun io-load (device path size)
  (let ((bytes (cffi:foreign-alloc :unsigned-char :count size)))
    (unwind-protect
         (with-metal-error
           (values
            (cffi:foreign-funcall "chorus_metal_io_load"
                                  :pointer (device-pointer device)
                                  :string path
                                  :unsigned-long size
                                  :pointer bytes
                                  :pointer error-pointer
                                  :int)
            (read-bytes bytes size)))
      (cffi:foreign-free bytes))))

(defun binary-archive (device queue path)
  (cffi:with-foreign-object (value :int)
    (with-metal-error
      (values
       (cffi:foreign-funcall "chorus_metal_binary_archive"
                             :pointer (device-pointer device)
                             :pointer (object-pointer queue)
                             :string path
                             :pointer value
                             :pointer error-pointer
                             :int)
       (cffi:mem-ref value :int)))))

(defun compile-async (device)
  (cffi:with-foreign-object (found :int)
    (with-metal-error
      (values
       (cffi:foreign-funcall "chorus_metal_compile_async"
                             :pointer (device-pointer device)
                             :pointer found
                             :pointer error-pointer
                             :int)
       (plusp (cffi:mem-ref found :int))))))

(defun drawable-pixel (device queue)
  (call-pixel "chorus_metal_drawable" device queue))

(defun tile-pixel (device queue)
  (call-pixel "chorus_metal_tile" device queue))

(defun mesh-pixel (device queue)
  (call-pixel "chorus_metal_mesh" device queue))

(defun memoryless-storage-mode (device)
  (cffi:with-foreign-object (mode :unsigned-long)
    (with-metal-error
      (values
       (cffi:foreign-funcall "chorus_metal_memoryless"
                             :pointer (device-pointer device)
                             :pointer mode
                             :pointer error-pointer
                             :int)
       (cffi:mem-ref mode :unsigned-long)))))
