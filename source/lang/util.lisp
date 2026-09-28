#|
  This file is a part of the Chorus project.
  Copyright (c) 2014 Masayuki Takagi (kamonama@gmail.com)
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
|#

(in-package :cl-user)
(defpackage chorus/lang/util
  (:use :cl)
  (:export :c-identifier
           :lines
           :unlines
           :indent))
(in-package chorus/lang/util)


(defun %c-identifier (object)
  (substitute-if #\_ (lambda (char)
                       (and (not (alphanumericp char))
                            (not (char= #\_ char))
                            (not (char= #\* char))))
                 (string-downcase object)))

(defun c-identifier (symbol &optional package-p)
  (let ((symbol-name (%c-identifier
                       (symbol-name symbol))))
    (if package-p
        (let ((package-name (%c-identifier
                              (package-name
                                (symbol-package symbol)))))
          (concatenate 'string package-name "_" symbol-name))
        symbol-name)))

(defun lines (str)
  (split-sequence:split-sequence #\LineFeed str :remove-empty-subseqs t))

(defun unlines (&rest args)
  (format nil "~{~A~%~}" args))

(defun indent (n str)
  (labels ((aux (x)
             (format nil "~vT~A" n x)))
    (apply #'unlines (mapcar #'aux (lines str)))))


