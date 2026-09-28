#|
  This file is a part of the Chorus project.
  Copyright (c) 2012-2014 Masayuki Takagi (kamonama@gmail.com)
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
|#

(in-package :cl-user)
(defpackage chorus-test.lang.compiler.compile-type
  (:use :cl :prove
        :chorus.lang.type
        :chorus.lang.compiler.compile-type))
(in-package :chorus-test.lang.compiler.compile-type)

(plan nil)


;;;
;;; test COMPILE-TYPE function
;;;

(diag "COMPILE-TYPE")

(is (compile-type 'int) "int"
    "basic case 1")



(finalize)
