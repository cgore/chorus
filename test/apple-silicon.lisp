#|
  This file is a part of the Chorus project.
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
|#

(in-package :cl-user)
(defpackage chorus/test/apple-silicon
  (:use :cl :prove))
(in-package :chorus/test/apple-silicon)

(plan nil)

(diag "apple silicon")

#-darwin
(ok t "Metal tests run on Darwin")

#+darwin
(progn
  (chorus/apple-silicon:defkernel vec-add
      (void ((a float*) (b float*) (c float*) (n int)))
    (let ((i (+ thread-idx-x (* block-dim-x block-idx-x))))
      (if (< i n)
          (set (aref c i) (+ (aref a i) (aref b i))))))

  (subtest "shared buffer round trip"
    (chorus/apple-silicon:with-device (device)
      (declare (ignore device))
      (chorus/apple-silicon:with-buffers ((values float 4))
        (setf (chorus/apple-silicon:buffer-aref values 2) 3.5)
        (is (chorus/apple-silicon:buffer-aref values 2) 3.5 :test #'=))))

  (subtest "Metal shading language launch"
    (chorus/apple-silicon:with-device (device)
      (chorus/apple-silicon:with-buffers ((values float 8))
        (dotimes (i 8)
          (setf (chorus/apple-silicon:buffer-aref values i) (float i 1.0)))
        (let* ((library (chorus/apple-silicon:compile-source
                         device
                         "#include <metal_stdlib>
using namespace metal;
kernel void add_one(device float *xs [[buffer(0)]],
                    uint tid [[thread_position_in_grid]]) {
  xs[tid] = xs[tid] + 1.0;
}
"))
               (function (chorus/apple-silicon:library-function library "add_one"))
               (pipeline (chorus/apple-silicon:make-pipeline device function)))
          (unwind-protect
               (chorus/apple-silicon:launch
                pipeline (list values) nil '(8 1 1) '(8 1 1))
            (chorus/apple-silicon:release function)
            (chorus/apple-silicon:release pipeline)
            (chorus/apple-silicon:release library)))
        (is (chorus/apple-silicon:buffer-aref values 0) 1.0 :test #'=)
        (is (chorus/apple-silicon:buffer-aref values 7) 8.0 :test #'=))))

  (subtest "defkernel vector add"
    (chorus/apple-silicon:with-device (device)
      (declare (ignore device))
      (chorus/apple-silicon:with-buffers ((a float 1024)
                                         (b float 1024)
                                         (c float 1024))
        (dotimes (i 1024)
          (setf (chorus/apple-silicon:buffer-aref a i) (float i 1.0))
          (setf (chorus/apple-silicon:buffer-aref b i) 1.0))
        (vec-add a b c 1024 :threads '(1024 1 1) :threads-per-group '(256 1 1))
        (is (chorus/apple-silicon:buffer-aref c 0) 1.0 :test #'=)
        (is (chorus/apple-silicon:buffer-aref c 3) 4.0 :test #'=)
        (is (chorus/apple-silicon:buffer-aref c 1000) 1001.0 :test #'=)))))

(finalize)
