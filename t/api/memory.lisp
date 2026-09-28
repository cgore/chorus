#|
  This file is a part of the Chorus project.
  Copyright (c) 2014 Masayuki Takagi (kamonama@gmail.com)
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
|#

(in-package :cl-user)
(defpackage chorus/test/api/memory
  (:use :cl :prove
        :chorus/api/memory
        :chorus/api/context
        :chorus/lang))
(in-package :chorus/test/api/memory)

(plan nil)


;;;
;;; test ALLOC-MEMORY-BLOCK / FREE-MEMORY-BLOCK function
;;;

(diag "ALLOC-MEMORY-BLOCK / FREE-MEMORY-BLOCK")

(with-cuda (0)
  (let (memory-block)
    (ok (setf memory-block (alloc-memory-block 'int 1024))
        "basic case 1")
    (free-memory-block memory-block)))

(diag "DEVICE-TOTAL-BYTES")

(with-cuda (0)
  (let ((bytes (device-total-bytes *cuda-device*)))
    (ok (integerp bytes) "reports an integer byte count")
    (ok (>= bytes (* 1024 1024 1024))
        "device reports at least 1GB (size_t must be 64-bit on Windows)")))

(with-cuda (0)
  (is-error (alloc-memory-block 'void 1024) simple-error
            "TYPE which is a void type"))

(with-cuda (0)
  (is-error (alloc-memory-block 'int  (* 1024 1024 1024 1024))
            simple-error
            "SIZE which specifies memory larger than available on the gpu"))

(with-cuda (0)
  (is-error (alloc-memory-block 'int 0)
            simple-error
            "SIZE which is zero"))

(with-cuda (0)
  (is-error (alloc-memory-block 'int -1)
            type-error
            "SIZE which is negative"))


;;;
;;; test MEMORY-BLOCK-DEVICE-PTR function
;;;

(diag "MEMORY-BLOCK-DEVICE-PTR")

(with-cuda (0)
  (with-memory-block (a 'int 1)
    (ok (memory-block-device-ptr a)
        "basic case 1")))


;;;
;;; test MEMORY-BLOCK-HOST-PTR function
;;;

(diag "MEMORY-BLOCK-HOST-PTR")

(with-cuda (0)
  (with-memory-block (a 'int 1)
    (ok (memory-block-host-ptr a)
        "basic case 1")))
  

;;;
;;; test MEMORY-BLOCK-TYPE function
;;;

(diag "MEMORY-BLOCK-TYPE")

(with-cuda (0)
  (with-memory-block (a 'int 1)
    (is (memory-block-type a) 'int
        "basic case 1")))


;;;
;;; test MEMORY-BLOCK-SIZE function
;;;

(diag "MEMORY-BLOCK-SIZE")

(with-cuda (0)
  (with-memory-block (a 'int 1)
    (is (memory-block-size a) 1
        "basic case 1")))


;;;
;;; test MEMORY-BLOCK-AREF function
;;;

(diag "MEMORY-BLOCK-AREF")

(with-cuda (0)
  (with-memory-block (a 'int 1)
    (setf (memory-block-aref a 0) 1)
    (is (memory-block-aref a 0) 1
        "basic case 1")))

(with-cuda (0)
  (with-memory-block (a 'float3 1)
    (setf (memory-block-aref a 0) (make-float3 1.0 1.0 1.0))
    (is (memory-block-aref a 0) (make-float3 1.0 1.0 1.0)
        :test #'float3-=
        "basic case 2")))


;;;
;;; test SYNC-MEMORY-BLOCK function
;;;

(diag "SYNC-MEMORY-BLOCK")

(with-cuda (0)
  (with-memory-block (a 'int 1)
    (setf (memory-block-aref a 0) 1)
    (sync-memory-block a :host-to-device)
    (setf (memory-block-aref a 0) 2)
    (sync-memory-block a :device-to-host)
    (is (memory-block-aref a 0) 1
        "basic case 1")))

(diag "DEVICE-TOTAL-* conversions")

(with-cuda (0)
  (let ((bytes (device-total-bytes *cuda-device*)))
    (is (device-total-kbytes *cuda-device*) (/ bytes 1024))
    (is (device-total-mbytes *cuda-device*) (/ bytes 1024 1024))
    (is (device-total-gbytes *cuda-device*) (/ bytes 1024 1024 1024))))

(diag "WITH-MEMORY-BLOCKS / MEMORY-BLOCK-P")

(with-cuda (0)
  (with-memory-blocks ((a 'int 2)
                       (b 'float 3))
    (ok (memory-block-p a))
    (ok (not (memory-block-p 1)))
    (is (memory-block-size a) 2)
    (is (memory-block-type b) 'float)
    (is (memory-block-size b) 3)))

(diag "DOUBLE / BOOL memory-block roundtrip")

(with-cuda (0)
  (with-memory-block (a 'double 2)
    (setf (memory-block-aref a 0) 1.5d0
          (memory-block-aref a 1) -2.25d0)
    (sync-memory-block a :host-to-device)
    (setf (memory-block-aref a 0) 0.0d0
          (memory-block-aref a 1) 0.0d0)
    (sync-memory-block a :device-to-host)
    (is (memory-block-aref a 0) 1.5d0)
    (is (memory-block-aref a 1) -2.25d0)))

(with-cuda (0)
  (with-memory-block (a 'bool 2)
    (setf (memory-block-aref a 0) t
          (memory-block-aref a 1) nil)
    (sync-memory-block a :host-to-device)
    (setf (memory-block-aref a 0) nil
          (memory-block-aref a 1) t)
    (sync-memory-block a :device-to-host)
    (is (memory-block-aref a 0) t)
    (is (memory-block-aref a 1) nil)))

(diag "HOST / DEVICE memory")

(with-cuda (0)
  (with-host-memory (h 'int 1)
    (with-device-memory (d 'int 1)
      (setf (host-memory-aref h 'int 0) 7)
      (memcpy-host-to-device d h 'int 1)
      (setf (host-memory-aref h 'int 0) 0)
      (memcpy-device-to-host h d 'int 1)
      (is (host-memory-aref h 'int 0) 7
          "low-level memcpy roundtrip"))))

(diag "SYNC-MEMORY-BLOCK invalid direction")

(with-cuda (0)
  (with-memory-block (a 'int 1)
    (is-error (sync-memory-block a :sideways)
              type-error
              "direction must be :host-to-device or :device-to-host")))


(finalize)
