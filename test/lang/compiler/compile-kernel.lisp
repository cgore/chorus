#|
  This file is a part of the Chorus project.
  Copyright (c) 2012-2016 Masayuki Takagi (kamonama@gmail.com)
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
|#

(in-package :cl-user)
(defpackage chorus/test/lang/compiler/compile-kernel
  (:use :cl :prove
        :chorus/lang/type
        :chorus/lang/kernel
        :chorus/lang/compiler/compile-kernel))
(in-package :chorus/test/lang/compiler/compile-kernel)

(plan nil)


;;;
;;; test COMPILE-KERNEL funcition
;;;

(diag "COMPILE-KERNEL")

(let ((kernel (make-kernel)))
  (kernel-define-global kernel 'a '(:device :constant) 1)
  (kernel-define-global kernel 'b :device 1.0)
  (kernel-define-function kernel 'foo 'void '((x int*))
                                 '((set (aref x 0) (bar 1))
                                   (return)))
  (kernel-define-function kernel 'bar 'int '((x int)) '((return x)))
  (kernel-define-function kernel 'baz 'void '() '((return)))
  (is (compile-kernel kernel)
      "#include \"int.h\"
#include \"float.h\"
#include \"float3.h\"
#include \"float4.h\"
#include \"double.h\"
#include \"double3.h\"
#include \"double4.h\"
#include \"curand.h\"
#include \"chorus-cluster.h\"


/**
 *  Kernel globals
 */

__device__ __constant__ static int chorus_test_lang_compiler_compile_kernel_a = 1;
__device__ static float chorus_test_lang_compiler_compile_kernel_b = 1.0f;


/**
 *  Kernel function prototypes
 */

extern \"C\" __global__ void chorus_test_lang_compiler_compile_kernel_foo( int* x );
extern \"C\" __device__ int chorus_test_lang_compiler_compile_kernel_bar( int x );
extern \"C\" __global__ void chorus_test_lang_compiler_compile_kernel_baz();


/**
 *  Kernel function definitions
 */

__global__ void chorus_test_lang_compiler_compile_kernel_foo( int* x )
{
  x[0] = chorus_test_lang_compiler_compile_kernel_bar( 1 );
  return;
}

__device__ int chorus_test_lang_compiler_compile_kernel_bar( int x )
{
  return x;
}

__global__ void chorus_test_lang_compiler_compile_kernel_baz()
{
  return;
}
"
      "basic case 1"))

(let ((kernel (make-kernel)))
  (kernel-define-function kernel 'bounded 'void '((x int* :restrict))
                          '((declare (launch-bounds 256 4))
                            (return)))
  (let ((code (compile-kernel kernel)))
    (ok (search "__restrict__" code) "restrict argument")
    (ok (search "__launch_bounds__(256, 4)" code) "launch bounds")))


(finalize)
