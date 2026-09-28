#|
  This file is a part of the Chorus project.
  Copyright (c) 2012-2014 Masayuki Takagi (kamonama@gmail.com)
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
|#

(in-package :cl-user)
(defpackage chorus.lang.compiler.compile-type
  (:use :cl
        :chorus.lang.type)
  (:export :compile-type))
(in-package :chorus.lang.compiler.compile-type)


;;;
;;; Type
;;;

(defun compile-type (type)
  (unless (chorus-type-p type)
    (error "The value ~S is an invalid chorus type." type))
  (cuda-type type))
