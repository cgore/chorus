#|
  This file is a part of the Chorus project.
  Copyright (c) 2014-2016 Masayuki Takagi (kamonama@gmail.com)
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
|#

(in-package :cl-user)
(defpackage chorus-interop-test
  (:use :cl :prove
        :chorus-interop))
(in-package :chorus-interop-test)

;; needed?
;; (setf *test-result-output* *standard-output*)

(plan nil)


(defclass test-window (glut:window) ()
  (:default-initargs :width 100 :height 100 :pos-x 100 :pos-y 100
                     :mode '(:double :rgb) :title "chorus test window"))

(defmethod glut:display ((w test-window))

  ;; test ALLOC-MEMORY-BLOCK/FREE-MEMORY-BLOCK with OpenGL interoperability
  (chorus-interop:with-cuda (0)
    (let (memory-block)
      (ok (setf memory-block (chorus-interop:alloc-memory-block 'int 1024)))
      (chorus-interop:free-memory-block memory-block)))
  
  ;; test the selectors of memory-block with OpenGL interoperability
  (chorus-interop:with-cuda (0)
    (chorus-interop:with-memory-block (memory-block 'int 1024)
      (chorus-interop:with-memory-block-device-ptr (device-ptr memory-block)
        (ok device-ptr))
      (ok (chorus-interop:memory-block-host-ptr memory-block))
      (ok (chorus-interop:memory-block-vertex-buffer-object memory-block))
      (ok (chorus-interop:memory-block-graphic-resource-ptr memory-block))
      (is (chorus-interop:memory-block-type memory-block) 'int)
      (is (chorus-interop:memory-block-size memory-block) 1024)))
  
  ;; test the accessor of memory-block with OpenGL interoperability
  (chorus-interop:with-cuda (0)
    ;; int array
    (chorus-interop:with-memory-block (x 'int 1)
      (setf (chorus-interop:memory-block-aref x 0) 1)
      (is (chorus-interop:memory-block-aref x 0) 1))
    ;; float array
    (chorus-interop:with-memory-block (x 'float 1)
      (setf (chorus-interop:memory-block-aref x 0) 1.0)
      (is (chorus-interop:memory-block-aref x 0) 1.0))
    ;; float3 array
    (chorus-interop:with-memory-block (x 'float3 1)
      (setf (chorus-interop:memory-block-aref x 0)
            (make-float3 1.0 1.0 1.0))
      (is (chorus-interop:memory-block-aref x 0)
          (make-float3 1.0 1.0 1.0)
          :test #'float3-=))
    ;; float4 array
    (chorus-interop:with-memory-block (x 'float4 1)
      (setf (chorus-interop:memory-block-aref x 0)
            (make-float4 1.0 1.0 1.0 1.0))
      (is (chorus-interop:memory-block-aref x 0)
          (make-float4 1.0 1.0 1.0 1.0)
          :test #'float4-=)))
  
  ;; test SET statement on memory-block with OpenGL interoperability
  (defkernel test-memcpy (void ((x int*) (y float*) (z float3*)))
    (set (aref x 0) (+ (aref x 0) 1))
    (set (aref y 0) (+ (aref y 0) 1.0))
    (set (aref z 0) (+ (aref z 0) (float3 1.0 1.0 1.0))))
  
  (chorus-interop:with-cuda (0)
    (chorus-interop:with-memory-blocks ((x 'int 1)
                                         (y 'float 1)
                                         (z 'float3 1))
      (setf (chorus-interop:memory-block-aref x 0) 1)
      (setf (chorus-interop:memory-block-aref y 0) 1.0)
      (setf (chorus-interop:memory-block-aref z 0)
            (make-float3 1.0 1.0 1.0))
      (chorus-interop:sync-memory-block x :host-to-device)
      (chorus-interop:sync-memory-block y :host-to-device)
      (chorus-interop:sync-memory-block z :host-to-device)
      (test-memcpy x y z :grid-dim '(1 1 1) :block-dim '(1 1 1))
      (chorus-interop:sync-memory-block x :device-to-host)
      (chorus-interop:sync-memory-block y :device-to-host)
      (chorus-interop:sync-memory-block z :device-to-host)
      (is (chorus-interop:memory-block-aref x 0) 2)
      (is (chorus-interop:memory-block-aref y 0) 2.0)
      (is (chorus-interop:memory-block-aref z 0)
          (make-float3 2.0 2.0 2.0)
          :test #'float3-=)))
  
  ;; guidance to quit
  (format t "press 'Q' on the test window to quit~%"))

(defmethod glut:keyboard ((w test-window) key x y)
  (case key
    (#\q (glut:destroy-window (glut:id w))
         (glut:leave-main-loop))))

(let ((glut:*run-main-loop-after-display* t))
  (glut:display-window (make-instance 'test-window)))

(finalize)
