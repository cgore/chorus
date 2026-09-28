#|
  This file is a part of the Chorus project.
  Copyright (c) 2014 Masayuki Takagi (kamonama@gmail.com)
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
|#

(in-package :cl-user)
(defpackage :chorus.api.macro
  (:use :cl
        :chorus.api.defkernel)
  (:export :let*
           :when
           :unless))
(in-package :chorus.api.macro)


(defkernelmacro let* (bindings &body body)
  (if bindings
      `(let (,(car bindings))
         (let* (,@(cdr bindings))
           ,@body))
      `(progn ,@body)))

(defkernelmacro when (test &body body)
  `(if ,test
       (progn ,@body)))

(defkernelmacro unless (test &body body)
  `(if (not ,test)
       (progn ,@body)))
