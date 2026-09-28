#|
  This file is a part of the Chorus project.
  Copyright (c) 2012-2016 Masayuki Takagi (kamonama@gmail.com)
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
|#

(in-package :cl-user)
(defpackage chorus-test.lang.compiler.compile-data
  (:use :cl :prove
        :chorus.lang.compiler.compile-data))
(in-package :chorus-test.lang.compiler.compile-data)

(plan nil)


;;;
;;; test COMPILE-SYMBOL function
;;;

(diag "COMPILE-SYMBOL")

(is (compile-symbol 'x) "x"
    "basic case 1")
(is (compile-symbol 'vec-add-kernel) "vec_add_kernel"
    "basic case 2")


;;;
;;; test COMPILE-BOOL function
;;;

(diag "COMPILE-BOOL")

(is (compile-bool t) "true"
    "basic case 1")
(is (compile-bool nil) "false"
    "basic case 2")


;;;
;;; test COMPILE-INT function
;;;

(diag "COMPILE-INT")

(is (compile-int 1) "1"
    "basic case 1")


;;;
;;; test COMPILE-FLOAT function
;;;

(diag "COMPILE-FLOAT")

(is (compile-float 1.0) "1.0f"
    "basic case 1")


;;;
;;; test COMPILE-DOUBLE function
;;;

(diag "COMPILE-DOUBLE")

(is (compile-double 1.0d0) "1.0"
    "basic case 1")

(is (compile-double 1.23456789012345d0) "1.23456789012345"
    "basic case 2")


(finalize)
