#|
  This file is a part of the Chorus project.
  Copyright (c) 2012-2016 Masayuki Takagi (kamonama@gmail.com)
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
|#

(in-package :cl-user)
(defpackage chorus.lang.compiler.compile-data
  (:use :cl
        :chorus.lang.data
        :chorus.lang.util)
  (:export :compile-symbol
           :compile-bool
           :compile-int
           :compile-float
           :compile-double))
(in-package :chorus.lang.compiler.compile-data)


;;;
;;; Symbol
;;;

(defun compile-symbol (expr)
  (unless (chorus-symbol-p expr)
    (error "The value ~S is an invalid expression." expr))
  (c-identifier expr))


;;;
;;; Bool
;;;

(defun compile-bool (expr)
  (unless (chorus-bool-p expr)
    (error "The value ~S is an invalid expression." expr))
  (if expr "true" "false"))


;;;
;;; Int
;;;

(defun compile-int (expr)
  (unless (chorus-int-p expr)
    (error "The value ~S is an invalid expression." expr))
  (princ-to-string expr))


;;;
;;; Float
;;;

(defun compile-float (expr)
  (unless (chorus-float-p expr)
    (error "The value ~S is an invalid expression." expr))
  (format nil "~Ff" expr))


;;;
;;; Double
;;;

(defun compile-double (expr)
  (unless (chorus-double-p expr)
    (error "The value ~S is an invalid expression." expr))
  (format nil "~F" expr))
