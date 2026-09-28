#|
  This file is a part of the Chorus project.
  Copyright (c) 2012-2014 Masayuki Takagi (kamonama@gmail.com)
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
|#

(in-package :cl-user)
(defpackage chorus-test.lang.built-in
  (:use :cl :prove
        :chorus.lang.type
        :chorus.lang.built-in))
(in-package :chorus-test.lang.built-in)

(plan nil)


;;;
;;; test BUILT-IN-FUNCTION-RETURN-TYPE function
;;;

(diag "BUILT-IN-FUNCTION-RETURN-TYPE")

(is (built-in-function-return-type '+ '(int int)) 'int
    "basic case 1")

(is (built-in-function-return-type '+ '(float3 float3)) 'float3
    "basic case 2")

(is (built-in-function-return-type '- '(int int)) 'int
    "basic case 3")

(is (built-in-function-return-type 'mod '(int int)) 'int
    "basic case 4")

(is (built-in-function-return-type '+ '(int float)) 'float
    "int + float promotes to float")

(is (built-in-function-return-type '+ '(float int)) 'float
    "float + int promotes to float")

(is (built-in-function-return-type '+ '(int double)) 'double
    "int + double promotes to double")

(is (built-in-function-return-type '+ '(double double)) 'double
    "double + double")

(is (built-in-function-return-type '* '(float3 float)) 'float3
    "float3 scaled by float")

;;;
;;; test BUILT-IN-FUNCTION-INFIX-P function
;;;

(diag "BUILT-IN-FUNCTION-INFIX-P")

(is (built-in-function-infix-p '+ '(int int)) t
    "basic case 1")

(is (built-in-function-infix-p '+ '(float3 float3)) nil
    "basic case 2")

(is (built-in-function-infix-p '- '(int int)) t
    "basic case 3")

(is (built-in-function-infix-p 'mod '(int int)) t
    "basic case 4")

;;;
;;; test BUILT-IN-FUNCTION-C-NAME function
;;;

(diag "BUILT-IN-FUNCTION-C-NAME")

(is (built-in-function-c-name '+ '(int int)) "+"
    "basic case 1")

(is (built-in-function-c-name '+ '(float3 float3)) "float3_add"
    "basic case 2")

(is (built-in-function-c-name '- '(int int)) "-"
    "basic case 3")

(is (built-in-function-c-name 'mod '(int int)) "%"
    "basic case 4")


(finalize)
