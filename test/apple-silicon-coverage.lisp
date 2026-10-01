#|
  This file is a part of the Chorus project.
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
|#

(in-package :cl-user)
(defpackage chorus/test/apple-silicon-coverage
  (:use :cl :prove :chorus/apple-silicon))
(in-package :chorus/test/apple-silicon-coverage)

(plan nil)

(diag "apple silicon coverage")

(defun near (left right)
  (< (abs (- left right)) 0.05))

(defun pixel-at (pixels width x y)
  (let ((start (* (+ (* y width) x) 4)))
    (subseq pixels start (+ start 4))))

(defun metal-header-directory ()
  (let ((sdk (string-trim '(#\Newline #\Return #\Space)
                          (uiop:run-program '("xcrun" "--show-sdk-path")
                                            :output :string))))
    (uiop:ensure-directory-pathname
     (format nil "~A/System/Library/Frameworks/Metal.framework/Headers/"
             sdk))))

(defun header-protocol-name (line)
  (let ((start (search "@protocol" line)))
    (when start
      (let* ((rest (string-left-trim '(#\Space #\Tab)
                                     (subseq line (+ start 9))))
             (end (position-if-not (lambda (character)
                                     (or (alphanumericp character)
                                         (char= character #\_)))
                                   rest))
             (token (subseq rest 0 (or end (length rest)))))
        (when (and (>= (length token) 3)
                   (string= "MTL" token :end2 3))
          token)))))

(defun prefix-p (prefix text)
  (and (>= (length text) (length prefix))
       (string= prefix text :end2 (length prefix))))

(defun macos-major ()
  (parse-integer
   (string-trim '(#\Newline #\Return #\Space)
                (uiop:run-program '("sw_vers" "-productVersion") :output :string))
   :junk-allowed t))

(defun macos-version-in-line (line)
  (let ((start (search "macos(" line)))
    (when start
      (parse-integer line :start (+ start 6) :junk-allowed t))))

(defun comment-line-p (line)
  (let ((trimmed (string-left-trim '(#\Space #\Tab) line)))
    (or (zerop (length trimmed))
        (prefix-p "//" trimmed)
        (prefix-p "/*" trimmed)
        (prefix-p "*" trimmed)
        (prefix-p "*/" trimmed))))

(defun preceding-macos-version (lines index)
  (loop for cursor from (1- index) downto 0
        for line = (aref lines cursor)
        for trimmed = (string-left-trim '(#\Space #\Tab) line)
        do (cond ((or (prefix-p "API_AVAILABLE" trimmed)
                      (prefix-p "API_UNAVAILABLE" trimmed)
                      (prefix-p "MTL_EXPORT" trimmed)
                      (prefix-p "MTL_EXTERN" trimmed))
                  (return (macos-version-in-line line)))
                 ((comment-line-p line))
                 (t (return nil)))))

(defun header-protocol-names (major)
  (let ((names nil)
        (directory (metal-header-directory)))
    (dolist (file (uiop:directory-files directory))
      (when (string-equal (pathname-type file) "h")
        (let ((lines (coerce
                      (with-open-file (stream file)
                        (loop for line = (read-line stream nil)
                              while line
                              collect line))
                      'vector)))
          (loop for index from 0 below (length lines)
                for name = (header-protocol-name (aref lines index))
                for version = (and name (preceding-macos-version lines index))
                when (and name (or (null version) (<= version major)))
                  do (push name names)))))
    (remove-duplicates names :test #'string=)))

#-darwin
(ok t "Metal coverage tests run on Darwin")

#+darwin
(progn
  (subtest "protocol names"
    (let* ((runtime (protocol-names))
           (headers (header-protocol-names (macos-major)))
           (missing (set-difference headers runtime :test #'string=)))
      (diag (format nil "~A header protocols, ~A runtime protocols"
                    (length headers) (length runtime)))
      (ok (member "MTLDevice" runtime :test #'string=))
      (ok headers)
      (is missing nil :test #'equal)))

  (with-device (device)
    (subtest "device and command queue"
      (multiple-value-bind (registry unified memory working)
          (device-info device)
        (ok (plusp registry))
        (ok unified)
        (ok (plusp memory))
        (ok (plusp working))
        (is (default-device-registry-id) registry :test #'=))
      (ok (supports-family device +gpu-family-apple1+))
      (ok (supports-family device +gpu-family-metal3+))
      (ok (supports-family device +gpu-family-metal4+))
      (let ((seen-gap nil))
        (loop for family from +gpu-family-apple1+ to +gpu-family-apple11+
              for supported = (supports-family device family)
              do (when seen-gap
                   (ok (not supported)))
                 (unless supported
                   (setq seen-gap t))))
      (setf (command-queue-label *command-queue*) "chorus-queue")
      (is (command-queue-label *command-queue*) "chorus-queue" :test #'string=))

    (subtest "resources"
      (let ((shared (buffer-with-options device 4 +resource-storage-shared+))
            (private (buffer-with-options device 16 +resource-storage-private+)))
        (unwind-protect
             (progn
               (is (buffer-storage-mode shared) +storage-mode-shared+)
               (ok (buffer-contents-p shared))
               (is (buffer-storage-mode private) +storage-mode-private+)
               (diag (format nil "private buffer contents ~A"
                             (buffer-contents-p private))))
          (release shared)
          (release private)))
      (multiple-value-bind (mode value) (managed-roundtrip device *command-queue*)
        (ok (or (= mode +storage-mode-shared+)
                (= mode +storage-mode-managed+)))
        (is value 19))
      (is (private-roundtrip device *command-queue*) 42)
      (is (memoryless-storage-mode device) +storage-mode-memoryless+)
      (is (texture-roundtrip device #(10 20 30 40)) #(10 20 30 40)
          :test #'equalp)
      (let ((used (heap-used-size device)))
        (ok (<= 1 used 4096)))
      (let ((count (residency-count device)))
        (ok (>= count 1)))
      (multiple-value-bind (extent0 extent1) (tensor-extents device)
        (is extent0 3)
        (is extent1 2)))

    (subtest "blit, fences, and events"
      (let ((source (buffer-with-options device 4 +resource-storage-shared+))
            (destination (buffer-with-options device 4 +resource-storage-shared+)))
        (unwind-protect
             (progn
               (blit-fill *command-queue* source 21 4)
               (blit-copy *command-queue* source destination 4)
               (is (buffer-byte destination 0) 21)
               (is (buffer-byte destination 3) 21))
          (release source)
          (release destination)))
      (is (fence-order device *command-queue*) 9)
      (is (shared-event-order device) 8))

    (subtest "compute encoders"
      (is (indirect-dispatch device *command-queue*) 1)
      (is (indirect-commands device *command-queue*) 2)
      (is (argument-buffer device *command-queue*) 11)
      (is (function-constant device *command-queue* 7) 7)
      (is (threadgroup-sum device *command-queue*) 6)
      (ok (> (sample-texture device *command-queue*) 0.9))
      (is (mipmap-pixel device *command-queue*) #(255 255 255 255) :test #'equalp)
      (ok (compile-async device))
      (let ((archive (format nil "/tmp/chorus-metal-archive-~A.metallib"
                             (random 1000000))))
        (unwind-protect
             (is (binary-archive device *command-queue* archive) 6)
          (uiop:delete-file-if-exists archive)))
      (multiple-value-bind (ran status start end)
          (timed-dispatch device *command-queue*)
        (ok ran)
        (is status +command-buffer-status-completed+)
        (ok (>= end start))))

    (subtest "render, tile, and mesh"
      (finish-output)
      (sampler-and-depth-states device)
      (diag "render triangle")
      (finish-output)
      (multiple-value-bind (pixels writes) (render-triangle device *command-queue* 8 8)
        (ok (plusp writes))
        (is (pixel-at pixels 8 4 4) #(255 0 0 255) :test #'equalp))
      (diag "tile")
      (finish-output)
      (is (tile-pixel device *command-queue*) #(0 255 0 255) :test #'equalp)
      (diag "mesh")
      (finish-output)
      (is (mesh-pixel device *command-queue*) #(0 0 255 255) :test #'equalp))

    (subtest "ray tracing"
      (is (trace-ray device *command-queue*) 1.0 :test #'near))

    (subtest "Metal 4"
      (multiple-value-bind (value learning) (metal4-compute device)
        (diag (format nil "machine learning encoder ~A" learning))
        (is value 5)))

    (subtest "shader log"
      (ok (search "chorus-log-token" (shader-log device *command-queue*))))

    (subtest "IO"
      (let ((path (format nil "/tmp/chorus-metal-io-~A.bin" (random 1000000))))
        (unwind-protect
             (progn
               (with-open-file (stream path :direction :output
                                       :if-exists :supersede
                                       :element-type '(unsigned-byte 8))
                 (write-byte 77 stream)
                 (write-byte 88 stream))
               (is (io-load device path 2) #(77 88) :test #'equalp))
          (uiop:delete-file-if-exists path))))

    (subtest "counters"
      (finish-output)
      (multiple-value-bind (supported bytes)
          (counter-sample device *command-queue*)
        (diag (format nil "counter sampling ~A, ~A bytes" supported bytes))
        (if supported
            (ok (typep bytes '(integer 0 *)))
            (ok t "counter sampling is not supported on this device"))))

    (subtest "capture"
      (finish-output)
      (let ((path (format nil "/tmp/chorus-metal-capture-~A.gputrace"
                          (random 1000000))))
        (unwind-protect
             (let ((supported (capture-trace device *command-queue* path)))
               (diag (format nil "capture supported ~A" supported))
               (if supported
                   (ok (probe-file path))
                   (ok t "GPU trace capture is not supported on this device")))
          (uiop:delete-file-if-exists path))))

    (subtest "drawable"
      (finish-output)
      (is (drawable-pixel device *command-queue*) #(0 0 255 255) :test #'equalp))))

(finalize)
