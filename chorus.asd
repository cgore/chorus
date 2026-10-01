#|
  This file is a part of the Chorus project.
  Copyright (c) 2012-2019 Masayuki Takagi (kamonama@gmail.com)
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
|#

(defpackage :chorus/asd
  (:use :cl :asdf :uiop))
(in-package :chorus/asd)

;;; CUDA-GROVEL-FILE used to subclass CFFI-GROVEL:GROVEL-FILE so that
;;; types were grovelled from cuda.h. Types are now hardcoded (CFFI :size
;;; for size_t), which is what makes Windows viable. Keep the class name
;;; so other systems that still reference it continue to parse.
(defclass cuda-grovel-file (cl-source-file) ())

;;;
;;; Chorus system definition
;;;

(defsystem "chorus"
  :version "0.1"
  :author "Masayuki Takagi, Christopher Mark Gore"
  :license "MIT"
  :depends-on ("cffi" "alexandria"
                      "cl-pattern" "split-sequence" "cl-reexport" "cl-ppcre")
  :components ((:module "source"
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
                                   (:file "function")
                                   (:file "device-attribute")
                                   (:file "extended")))
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
                         (:module "apple-silicon"
                                  :serial t
                                  :components
                                  ((:file "metal")
                                   (:file "runtime")
                                   (:file "kernel")))
                         (:module "cuda"
                                  :serial t
                                  :components
                                  ((:file "cuda")))
                         (:module "backend"
                                  :serial t
                                  :components
                                  ((:file "backend")))
                         (:file "chorus"))))
  :description "Common Lisp GPU programming for CUDA, Apple silicon, and AMD GPUs."
  :long-description #.(read-file-string (subpathname *load-pathname* "README.md"))
  :in-order-to ((test-op (test-op "chorus-test"))))
