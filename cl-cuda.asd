#|
  This file is a part of cl-cuda project.
  Copyright (c) 2012 Masayuki Takagi (kamonama@gmail.com)
|#

(defpackage :cl-cuda-asd
  (:use :cl :asdf :uiop))
(in-package :cl-cuda-asd)

;;; CUDA-GROVEL-FILE used to subclass CFFI-GROVEL:GROVEL-FILE so that
;;; types were grovelled from cuda.h. Types are now hardcoded (CFFI :size
;;; for size_t), which is what makes Windows viable. Keep the class name
;;; so other systems that still reference it continue to parse.
(defclass cuda-grovel-file (cl-source-file) ())

;;;
;;; Cl-cuda system definition
;;;

(defsystem "cl-cuda"
  :version "0.1"
  :author "Masayuki Takagi"
  :license "MIT"
  :depends-on ("cffi" "alexandria"
                      "cl-pattern" "split-sequence" "cl-reexport" "cl-ppcre")
  :components ((:module "src"
                        :serial t
                        :components
                        ((:module "driver-api"
                                  :serial t
                                  :components
                                  ((:file "package")
                                   (:file "get-error-string")
                                   (:file "sdk-not-found")
                                   (:file "library")
                                   (:file "type")
                                   (:file "enum")
                                   (:file "function")))
                         (:module "lang"
                                  :serial t
                                  :components
                                  ((:file "util")
                                   (:file "data")
                                   (:file "type")
                                   (:file "syntax")
                                   (:file "environment")
                                   (:file "built-in")
                                   (:file "kernel")
                                   (:file "compiler/compile-data")
                                   (:file "compiler/compile-type")
                                   (:file "compiler/type-of-expression")
                                   (:file "compiler/compile-expression")
                                   (:file "compiler/compile-statement")
                                   (:file "compiler/compile-kernel")
                                   (:file "lang")))
                         (:module "api"
                                  :serial t
                                  :components
                                  ((:file "nvcc")
                                   (:file "kernel-manager")
                                   (:file "memory")
                                   (:file "context")
                                   (:file "defkernel")
                                   (:file "macro")
                                   (:file "timer")
                                   (:file "api")))
                         (:file "cl-cuda"))))
  :description "Cl-cuda is a library to use NVIDIA CUDA in Common Lisp programs."
  :long-description #.(read-file-string (subpathname *load-pathname* "README.markdown"))
  :in-order-to ((test-op (test-op "cl-cuda-test"))))
