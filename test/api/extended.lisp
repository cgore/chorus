#|
  This file is a part of the Chorus project.
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
|#

(in-package :cl-user)
(defpackage chorus/test/api/extended
  (:use :cl :prove
        :chorus/api/defkernel
        :chorus/api/context
        :chorus/api/memory
        :chorus/lang)
  (:import-from :chorus/api/kernel-manager
                :ensure-kernel-function-loaded
                :*kernel-manager*))
(in-package :chorus/test/api/extended)

(plan nil)

(diag "extended kernel language and driver API")

(defkernel-struct chorus-ext-pair
  (x int)
  (y int))

(defkernel ext-while (void ((a int*) (n int)))
  (let ((i 0))
    (while (< i n)
      (set (aref a i) i)
      (set i (+ i 1)))))

(defkernel ext-for (void ((a int*) (n int)))
  (for (i 0 (< i n) (+ i 1))
    (set (aref a i) (+ i 1))))

(defkernel ext-break (void ((a int*)))
  (set (aref a 0) 0)
  (for (i 0 (< i 10) (+ i 1))
    (set (aref a 0) i)
    (if (= i 2)
        (break))))

(defkernel ext-continue (void ((a int*)))
  (for (i 0 (< i 4) (+ i 1))
    (if (= i 1)
        (continue))
    (set (aref a i) 1)))

(defkernel ext-switch (void ((a int*) (b int*)))
  (switch (aref a 0)
    (1 (set (aref b 0) 10))
    (2 (set (aref b 0) 20))
    (t (set (aref b 0) 30))))

(defkernel ext-dynamic (void ((a int*)))
  (with-dynamic-shared-memory ((s int))
    (set (aref s thread-idx-x) thread-idx-x)
    (syncthreads)
    (set (aref a thread-idx-x) (aref s thread-idx-x))))

(defkernel ext-restrict (void ((x int* :restrict)))
  (set (aref x 0) 7))

(defkernel ext-cas (void ((a int*)))
  (atomic-cas a 0 1))

(defkernel ext-cas64 (void ((a uint64*)))
  (atomic-cas a (uint64 0) (uint64 1)))

(defkernel ext-shfl (void ((a int*)))
  (set (aref a thread-idx-x)
       (shfl-sync (uint -1) thread-idx-x 1 32)))

(defkernel ext-printf (void ())
  (printf "chorus %d" 7))

(defkernel ext-fma (void ((a float*)))
  (set (aref a 0) (fma 2.0 3.0 4.0)))

(defkernel ext-half (void ((a half*) (b half*) (c half*)))
  (set (aref c 0) (+ (aref a 0) (aref b 0))))

(defkernel ext-bf16 (void ((a bfloat16*) (b bfloat16*) (c bfloat16*)))
  (set (aref c 0) (+ (aref a 0) (aref b 0))))

(defkernel ext-fp (void ((a fp8*) (b fp4*)))
  (set (aref a 0) (aref a 0))
  (set (aref b 0) (aref b 0)))

(defkernel ext-int2 (void ((a int2*)))
  (set (aref a 0) (int2 3 4)))

(defkernel ext-pair (void ((a chorus-ext-pair*)))
  (set (chorus-ext-pair-x (aref a 0)) 3)
  (set (chorus-ext-pair-y (aref a 0)) 4))

(defkernel ext-stream (void ((a int*)))
  (set (aref a 0) 5))

(defkernel ext-asm (void ((a int*)))
  (let ((x 0))
    (cuda-asm "asm volatile(\"mov.s32 %0, 7;\" : \"=r\"(x));")
    (set (aref a 0) x)))

(defkernel ext-cluster (void ((a int*)))
  (set (aref a 0) cluster-dim-x))

(defkernel ext-managed (void ((a int*)))
  (set (aref a 0) 9))

(defkernel ext-empty (void ())
  (return))

(defun ext-driver-error-p (thunk)
  (handler-case
      (progn (funcall thunk) nil)
    (simple-error (condition)
      (not (null (search "failed with driver API"
                         (princ-to-string condition)))))))

(defun ext-read-bytes (path)
  (with-open-file (in path :element-type '(unsigned-byte 8))
    (let ((bytes (make-array (file-length in)
                             :element-type '(unsigned-byte 8))))
      (read-sequence bytes in)
      bytes)))

(defun ext-device-int (device-ptr)
  (cffi:with-foreign-object (host :int)
    (chorus/driver-api:cu-memcpy-device-to-host
     host device-ptr (cffi:foreign-type-size :int))
    (cffi:mem-ref host :int)))

(with-cuda (0)
  (subtest "while"
    (with-memory-block (a 'int 4)
      (dotimes (i 4)
        (setf (memory-block-aref a i) -1))
      (sync-memory-block a :host-to-device)
      (ext-while a 4 :grid-dim '(1 1 1) :block-dim '(1 1 1))
      (synchronize-context)
      (sync-memory-block a :device-to-host)
      (is (memory-block-aref a 0) 0)
      (is (memory-block-aref a 3) 3)))

  (subtest "for"
    (with-memory-block (a 'int 4)
      (dotimes (i 4)
        (setf (memory-block-aref a i) 0))
      (sync-memory-block a :host-to-device)
      (ext-for a 4 :grid-dim '(1 1 1) :block-dim '(1 1 1))
      (synchronize-context)
      (sync-memory-block a :device-to-host)
      (is (memory-block-aref a 0) 1)
      (is (memory-block-aref a 3) 4)))

  (subtest "break"
    (with-memory-block (a 'int 1)
      (setf (memory-block-aref a 0) 0)
      (sync-memory-block a :host-to-device)
      (ext-break a :grid-dim '(1 1 1) :block-dim '(1 1 1))
      (synchronize-context)
      (sync-memory-block a :device-to-host)
      (is (memory-block-aref a 0) 2)))

  (subtest "continue"
    (with-memory-block (a 'int 4)
      (dotimes (i 4)
        (setf (memory-block-aref a i) 0))
      (sync-memory-block a :host-to-device)
      (ext-continue a :grid-dim '(1 1 1) :block-dim '(1 1 1))
      (synchronize-context)
      (sync-memory-block a :device-to-host)
      (is (memory-block-aref a 0) 1)
      (is (memory-block-aref a 1) 0)
      (is (memory-block-aref a 3) 1)))

  (subtest "switch"
    (with-memory-blocks ((a 'int 1) (b 'int 1))
      (setf (memory-block-aref a 0) 2
            (memory-block-aref b 0) 0)
      (sync-memory-block a :host-to-device)
      (sync-memory-block b :host-to-device)
      (ext-switch a b :grid-dim '(1 1 1) :block-dim '(1 1 1))
      (synchronize-context)
      (sync-memory-block b :device-to-host)
      (is (memory-block-aref b 0) 20)))

  (subtest "dynamic shared memory"
    (with-memory-block (a 'int 32)
      (dotimes (i 32)
        (setf (memory-block-aref a i) -1))
      (sync-memory-block a :host-to-device)
      (ext-dynamic a :grid-dim '(1 1 1) :block-dim '(32 1 1)
                     :shared-mem (* 32 4))
      (synchronize-context)
      (sync-memory-block a :device-to-host)
      (is (memory-block-aref a 0) 0)
      (is (memory-block-aref a 31) 31)))

  (subtest "restrict"
    (with-memory-block (a 'int 1)
      (setf (memory-block-aref a 0) 0)
      (sync-memory-block a :host-to-device)
      (ext-restrict a :grid-dim '(1 1 1) :block-dim '(1 1 1))
      (synchronize-context)
      (sync-memory-block a :device-to-host)
      (is (memory-block-aref a 0) 7)))

  (subtest "atomic-cas"
    (with-memory-block (a 'int 1)
      (setf (memory-block-aref a 0) 0)
      (sync-memory-block a :host-to-device)
      (ext-cas a :grid-dim '(1 1 1) :block-dim '(1 1 1))
      (synchronize-context)
      (sync-memory-block a :device-to-host)
      (is (memory-block-aref a 0) 1)))

  (subtest "atomic-cas uint64"
    (with-memory-block (a 'uint64 1)
      (setf (memory-block-aref a 0) 0)
      (sync-memory-block a :host-to-device)
      (ext-cas64 a :grid-dim '(1 1 1) :block-dim '(1 1 1))
      (synchronize-context)
      (sync-memory-block a :device-to-host)
      (is (memory-block-aref a 0) 1)))

  (subtest "shfl-sync"
    (with-memory-block (a 'int 32)
      (dotimes (i 32)
        (setf (memory-block-aref a i) -1))
      (sync-memory-block a :host-to-device)
      (ext-shfl a :grid-dim '(1 1 1) :block-dim '(32 1 1))
      (synchronize-context)
      (sync-memory-block a :device-to-host)
      (is (memory-block-aref a 0) 1)
      (is (memory-block-aref a 31) 1)))

  (subtest "printf"
    (is (ext-printf :grid-dim '(1 1 1) :block-dim '(1 1 1)) nil)
    (synchronize-context))

  (subtest "fma"
    (with-memory-block (a 'float 1)
      (setf (memory-block-aref a 0) 0.0)
      (sync-memory-block a :host-to-device)
      (ext-fma a :grid-dim '(1 1 1) :block-dim '(1 1 1))
      (synchronize-context)
      (sync-memory-block a :device-to-host)
      (is (memory-block-aref a 0) 10.0)))

  (subtest "half add"
    (with-memory-blocks ((a 'half 1) (b 'half 1) (c 'half 1))
      (setf (memory-block-aref a 0) #x3C00
            (memory-block-aref b 0) #x3C00
            (memory-block-aref c 0) 0)
      (sync-memory-block a :host-to-device)
      (sync-memory-block b :host-to-device)
      (ext-half a b c :grid-dim '(1 1 1) :block-dim '(1 1 1))
      (synchronize-context)
      (sync-memory-block c :device-to-host)
      (is (memory-block-aref c 0) #x4000)))

  (subtest "bfloat16 add"
    (with-memory-blocks ((a 'bfloat16 1) (b 'bfloat16 1) (c 'bfloat16 1))
      (setf (memory-block-aref a 0) #x3F80
            (memory-block-aref b 0) #x3F80
            (memory-block-aref c 0) 0)
      (sync-memory-block a :host-to-device)
      (sync-memory-block b :host-to-device)
      (ext-bf16 a b c :grid-dim '(1 1 1) :block-dim '(1 1 1))
      (synchronize-context)
      (sync-memory-block c :device-to-host)
      (is (memory-block-aref c 0) #x4000)))

  (subtest "fp8 and fp4"
    (with-memory-blocks ((a 'fp8 1) (b 'fp4 1))
      (setf (memory-block-aref a 0) #x38
            (memory-block-aref b 0) #x2)
      (sync-memory-block a :host-to-device)
      (sync-memory-block b :host-to-device)
      (ext-fp a b :grid-dim '(1 1 1) :block-dim '(1 1 1))
      (synchronize-context)
      (sync-memory-block a :device-to-host)
      (sync-memory-block b :device-to-host)
      (is (memory-block-aref a 0) #x38)
      (is (memory-block-aref b 0) #x2)))

  (subtest "int2"
    (with-memory-block (a 'int2 1)
      (setf (memory-block-aref a 0) (make-int2 0 0))
      (sync-memory-block a :host-to-device)
      (ext-int2 a :grid-dim '(1 1 1) :block-dim '(1 1 1))
      (synchronize-context)
      (sync-memory-block a :device-to-host)
      (ok (int2-= (memory-block-aref a 0) (make-int2 3 4)))))

  (subtest "defkernel-struct"
    (with-memory-block (a 'chorus-ext-pair 1)
      (setf (memory-block-aref a 0) (make-chorus-ext-pair 0 0))
      (sync-memory-block a :host-to-device)
      (ext-pair a :grid-dim '(1 1 1) :block-dim '(1 1 1))
      (synchronize-context)
      (sync-memory-block a :device-to-host)
      (let ((pair (memory-block-aref a 0)))
        (is (chorus-ext-pair-x pair) 3)
        (is (chorus-ext-pair-y pair) 4))))

  (subtest "launch stream"
    (with-memory-block (a 'int 1)
      (setf (memory-block-aref a 0) 0)
      (sync-memory-block a :host-to-device)
      (cffi:with-foreign-object (stream 'chorus/driver-api:cu-stream)
        (chorus/driver-api:cu-stream-create stream 0)
        (let ((handle (cffi:mem-ref stream 'chorus/driver-api:cu-stream)))
          (unwind-protect
               (progn
                 (ext-stream a :stream handle
                               :grid-dim '(1 1 1) :block-dim '(1 1 1))
                 (chorus/driver-api:cu-stream-synchronize handle))
            (chorus/driver-api:cu-stream-destroy handle))))
      (sync-memory-block a :device-to-host)
      (is (memory-block-aref a 0) 5)))

  (subtest "cuda-asm"
    (with-memory-block (a 'int 1)
      (setf (memory-block-aref a 0) 0)
      (sync-memory-block a :host-to-device)
      (ext-asm a :grid-dim '(1 1 1) :block-dim '(1 1 1))
      (synchronize-context)
      (sync-memory-block a :device-to-host)
      (is (memory-block-aref a 0) 7)))

  (subtest "cluster index"
    (with-memory-block (a 'int 1)
      (setf (memory-block-aref a 0) -1)
      (sync-memory-block a :host-to-device)
      (ext-cluster a :grid-dim '(1 1 1) :block-dim '(1 1 1))
      (synchronize-context)
      (sync-memory-block a :device-to-host)
      (ok (integerp (memory-block-aref a 0)) "cluster launch completed")))

  (subtest "memset and device to device"
    (with-memory-blocks ((a 'uint8 16) (b 'uint8 16))
      (dotimes (i 16)
        (setf (memory-block-aref a i) 0
              (memory-block-aref b i) 0))
      (sync-memory-block a :host-to-device)
      (sync-memory-block b :host-to-device)
      (memset-device (memory-block-device-ptr a) 7 16 :width 8)
      (memcpy-device-to-device (memory-block-device-ptr b)
                               (memory-block-device-ptr a)
                               16)
      (synchronize-context)
      (sync-memory-block b :device-to-host)
      (is (memory-block-aref b 0) 7)
      (is (memory-block-aref b 15) 7)))

  (subtest "pitched 2D copy"
    (with-memory-blocks ((src 'uint8 32) (dst 'uint8 32))
      (dotimes (i 32)
        (setf (memory-block-aref src i) 3
              (memory-block-aref dst i) 0))
      (sync-memory-block src :host-to-device)
      (sync-memory-block dst :host-to-device)
      (memcpy-device-to-device-2d (memory-block-device-ptr dst) 16
                                  (memory-block-device-ptr src) 16
                                  16 2)
      (synchronize-context)
      (sync-memory-block dst :device-to-host)
      (is (memory-block-aref dst 0) 3)
      (is (memory-block-aref dst 31) 3)))

  (subtest "pinned memory"
    (with-pinned-memory (ptr 4)
      (setf (cffi:mem-ref ptr :int) 11)
      (is (cffi:mem-ref ptr :int) 11)))

  (subtest "managed memory"
    (let ((ptr (alloc-managed-memory 'int 1)))
      (unwind-protect
           (progn
             (ext-managed ptr :grid-dim '(1 1 1) :block-dim '(1 1 1))
             (synchronize-context)
             (is (ext-device-int ptr) 9))
        (free-managed-memory ptr))))

  (subtest "function attribute"
    (ext-empty :grid-dim '(1 1 1) :block-dim '(1 1 1))
    (let ((hfunc (ensure-kernel-function-loaded *kernel-manager* 'ext-empty)))
      (cffi:with-foreign-object (value :int)
        (chorus/driver-api:cu-func-get-attribute value 0 hfunc)
        (ok (> (cffi:mem-ref value :int) 0)))))

  (subtest "module load data"
    (let* ((path (chorus/api/nvcc:nvcc-compile
                  "extern \"C\" __global__ void chorus_ext_probe() {}
"))
           (bytes (ext-read-bytes path)))
      (cffi:with-foreign-object (image :unsigned-char (length bytes))
        (loop for byte across bytes
              for index from 0
              do (setf (cffi:mem-aref image :unsigned-char index) byte))
        (cffi:with-foreign-objects ((module 'chorus/driver-api:cu-module)
                                    (function 'chorus/driver-api:cu-function))
          (chorus/driver-api:cu-module-load-data module image)
          (let ((loaded (cffi:mem-ref module 'chorus/driver-api:cu-module)))
            (unwind-protect
                 (progn
                   (chorus/driver-api:cu-module-get-function
                    function loaded "chorus_ext_probe")
                   (ok (not (cffi:null-pointer-p
                             (cffi:mem-ref function
                                           'chorus/driver-api:cu-function)))))
              (chorus/driver-api:cu-module-unload loaded)))))))

  (subtest "graph create"
    (cffi:with-foreign-object (graph 'chorus/driver-api:cu-graph)
      (chorus/driver-api:cu-graph-create graph 0)
      (chorus/driver-api:cu-graph-destroy
       (cffi:mem-ref graph 'chorus/driver-api:cu-graph))
      (ok t)))

  (subtest "tensor map encode"
    ;; Rank 2, float32. The inner box is 4 elements (16 bytes) and the
    ;; global stride is 16 * 4 bytes. Both are multiples of 16, which
    ;; cuTensorMapEncodeTiled requires for an uninterleaved map.
    (with-memory-block (buf 'float 64)
      (let* ((raw (cffi:foreign-alloc :unsigned-char :count 256))
             (map (cffi:make-pointer
                   (logand (+ (cffi:pointer-address raw) 127)
                           (lognot 127)))))
        (unwind-protect
             (cffi:with-foreign-objects ((dim :uint64 2)
                                         (global-stride :uint64 1)
                                         (box :uint32 2)
                                         (elem-stride :uint32 2))
               (setf (cffi:mem-aref dim :uint64 0) 16
                     (cffi:mem-aref dim :uint64 1) 4
                     (cffi:mem-ref global-stride :uint64) 64
                     (cffi:mem-aref box :uint32 0) 4
                     (cffi:mem-aref box :uint32 1) 1
                     (cffi:mem-aref elem-stride :uint32 0) 1
                     (cffi:mem-aref elem-stride :uint32 1) 1)
               (chorus/driver-api:cu-tensor-map-encode-tiled
                map 7 2
                (cffi:make-pointer (memory-block-device-ptr buf))
                dim global-stride box elem-stride
                0 0 0 0)
               (ok t))
          (cffi:foreign-free raw)))))

  (subtest "D3D11 and external memory reject a null handle"
    (ok (ext-driver-error-p
         (lambda ()
           (cffi:with-foreign-object (device 'chorus/driver-api:cu-device)
             (chorus/driver-api:cu-d3d11-get-device
              device (cffi:null-pointer))))))
    (ok (ext-driver-error-p
         (lambda ()
           (cffi:with-foreign-object (memory 'chorus/driver-api:cu-external-memory)
             (chorus/driver-api:cu-import-external-memory
              memory (cffi:null-pointer))))))))

(subtest "primary context and warp size"
  (with-primary-cuda (0)
    (is (device-attribute
         *cuda-device*
         chorus/driver-api:cu-device-attribute-warp-size)
        32)
    (is (device-attribute
         *cuda-device*
         chorus/driver-api:cu-device-attribute-compute-capability-major)
        12)))

(finalize)
