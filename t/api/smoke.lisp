#|
  This file is a part of the Chorus project.
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
|#

(in-package :cl-user)
(defpackage chorus-test.api.smoke
  (:use :cl :prove
        :chorus.api.defkernel
        :chorus.api.context
        :chorus.api.memory
        :chorus.lang)
  (:shadowing-import-from :chorus.api.macro
                          :let* :when :unless))
(in-package :chorus-test.api.smoke)

(plan nil)

(diag "end-to-end kernels")

(defkernel smoke-vec-add (void ((a float*) (b float*) (c float*) (n int)))
  (let ((i (+ (* block-dim-x block-idx-x) thread-idx-x)))
    (if (< i n)
        (set (aref c i)
             (+ (aref a i) (aref b i))))))

(defkernel smoke-shared (void ((a float*)))
  (let ((i (+ (* block-dim-x block-idx-x) thread-idx-x)))
    (with-shared-memory ((s float 256))
      (set (aref s thread-idx-x) (aref a i))
      (syncthreads)
      (set (aref a i) (+ (aref s thread-idx-x) 1.0)))))

(defkernel smoke-double (void ((a double*)))
  (set (aref a 0) (* (aref a 0) 2.0d0)))

(defkernel smoke-macros (void ((a int*)))
  (let* ((x 1)
         (y (+ x 2)))
    (when t
      (set (aref a 0) y))
    (unless nil
      (set (aref a 1) 4))))

(subtest "vector-add (non-multiple of block size)"
  (let* ((n 1000)
         (threads-per-block 256)
         (blocks-per-grid (ceiling n threads-per-block)))
    (with-cuda (0)
      (with-memory-blocks ((a 'float n)
                           (b 'float n)
                           (c 'float n))
        (dotimes (i n)
          (setf (memory-block-aref a i) (float i 1.0)
                (memory-block-aref b i) 1.0
                (memory-block-aref c i) 0.0))
        (sync-memory-block a :host-to-device)
        (sync-memory-block b :host-to-device)
        (smoke-vec-add a b c n
                       :grid-dim (list blocks-per-grid 1 1)
                       :block-dim (list threads-per-block 1 1))
        (synchronize-context)
        (sync-memory-block c :device-to-host)
        (let ((ok-count 0))
          (dotimes (i n)
            (when (= (memory-block-aref c i) (+ (float i 1.0) 1.0))
              (incf ok-count)))
          (is ok-count n "every element is a[i]+b[i]"))))))

(subtest "shared memory + syncthreads"
  (let ((n 256))
    (with-cuda (0)
      (with-memory-block (a 'float n)
        (dotimes (i n)
          (setf (memory-block-aref a i) (float i 1.0)))
        (sync-memory-block a :host-to-device)
        (smoke-shared a :grid-dim '(1 1 1) :block-dim '(256 1 1))
        (synchronize-context)
        (sync-memory-block a :device-to-host)
        (is (memory-block-aref a 0) 1.0)
        (is (memory-block-aref a 255) 256.0)))))

(subtest "double precision"
  (with-cuda (0)
    (with-memory-block (a 'double 1)
      (setf (memory-block-aref a 0) 1.25d0)
      (sync-memory-block a :host-to-device)
      (smoke-double a :grid-dim '(1 1 1) :block-dim '(1 1 1))
      (synchronize-context)
      (sync-memory-block a :device-to-host)
      (is (memory-block-aref a 0) 2.5d0))))

(subtest "let* / when / unless kernel macros"
  (with-cuda (0)
    (with-memory-block (a 'int 2)
      (setf (memory-block-aref a 0) 0
            (memory-block-aref a 1) 0)
      (sync-memory-block a :host-to-device)
      (smoke-macros a :grid-dim '(1 1 1) :block-dim '(1 1 1))
      (synchronize-context)
      (sync-memory-block a :device-to-host)
      (is (memory-block-aref a 0) 3)
      (is (memory-block-aref a 1) 4))))

(finalize)
