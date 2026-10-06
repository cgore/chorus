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
;;; A component name is the file's path under source/. ASDF resolves
;;; :depends-on among siblings, so the directory stays in the name.

(defsystem "chorus"
  :version "0.1"
  :author "Masayuki Takagi, Christopher Mark Gore"
  :license "MIT"
  :depends-on ("cffi" "alexandria"
                      "cl-pattern" "split-sequence" "cl-reexport" "cl-ppcre")
  :components
  ((:module "source"
    :components
    ((:file "driver-api/package")
     (:file "driver-api/sdk-not-found"
      :depends-on ("driver-api/package"))
     (:file "driver-api/library"
      :depends-on ("driver-api/package"
                   "driver-api/sdk-not-found"))
     (:file "driver-api/get-error-string"
      :depends-on ("driver-api/package"))
     (:file "driver-api/type"
      :depends-on ("driver-api/package"))
     (:file "driver-api/enum"
      :depends-on ("driver-api/package"))
     (:file "driver-api/device-attribute"
      :depends-on ("driver-api/package"))
     (:file "driver-api/function"
      :depends-on ("driver-api/get-error-string"
                   "driver-api/library"
                   "driver-api/package"
                   "driver-api/sdk-not-found"
                   "driver-api/type"))
     (:file "driver-api/extended"
      :depends-on ("driver-api/function"
                   "driver-api/package"
                   "driver-api/type"))
     (:file "lang/util")
     (:file "lang/data")
     (:file "lang/type"
      :depends-on ("driver-api/package"
                   "driver-api/type"
                   "lang/data"))
     (:file "lang/syntax"
      :depends-on ("lang/data"
                   "lang/type"))
     (:file "lang/environment"
      :depends-on ("lang/data"
                   "lang/type"
                   "lang/util"))
     (:file "lang/built-in"
      :depends-on ("lang/type"))
     (:file "lang/kernel"
      :depends-on ("lang/data"
                   "lang/syntax"
                   "lang/type"
                   "lang/util"))
     (:file "lang/compiler/compile-data"
      :depends-on ("lang/data"
                   "lang/util"))
     (:file "lang/compiler/compile-type"
      :depends-on ("lang/type"))
     (:file "lang/compiler/type-of-expression"
      :depends-on ("lang/built-in"
                   "lang/environment"
                   "lang/syntax"
                   "lang/type"))
     (:file "lang/compiler/compile-expression"
      :depends-on ("lang/built-in"
                   "lang/compiler/compile-data"
                   "lang/compiler/type-of-expression"
                   "lang/environment"
                   "lang/syntax"
                   "lang/type"))
     (:file "lang/compiler/compile-statement"
      :depends-on ("lang/compiler/compile-data"
                   "lang/compiler/compile-expression"
                   "lang/compiler/compile-type"
                   "lang/compiler/type-of-expression"
                   "lang/environment"
                   "lang/syntax"
                   "lang/type"
                   "lang/util"))
     (:file "lang/compiler/compile-kernel"
      :depends-on ("lang/compiler/compile-data"
                   "lang/compiler/compile-expression"
                   "lang/compiler/compile-statement"
                   "lang/compiler/compile-type"
                   "lang/compiler/type-of-expression"
                   "lang/environment"
                   "lang/kernel"
                   "lang/syntax"
                   "lang/type"
                   "lang/util"))
     (:file "lang/lang"
      :depends-on ("lang/built-in"
                   "lang/data"
                   "lang/syntax"
                   "lang/type"))
     (:file "api/nvcc"
      :depends-on ("driver-api/function"
                   "driver-api/package"
                   "driver-api/sdk-not-found"))
     (:file "api/timer"
      :depends-on ("driver-api/enum"
                   "driver-api/function"
                   "driver-api/package"
                   "driver-api/type"))
     (:file "api/memory"
      :depends-on ("driver-api/extended"
                   "driver-api/function"
                   "driver-api/package"
                   "driver-api/type"
                   "lang/type"))
     (:file "api/kernel-manager"
      :depends-on ("api/nvcc"
                   "driver-api/function"
                   "driver-api/package"
                   "driver-api/type"
                   "lang/compiler/compile-kernel"
                   "lang/kernel"))
     (:file "api/context"
      :depends-on ("api/kernel-manager"
                   "api/nvcc"
                   "driver-api/device-attribute"
                   "driver-api/extended"
                   "driver-api/function"
                   "driver-api/package"
                   "driver-api/type"))
     (:file "api/defkernel"
      :depends-on ("api/context"
                   "api/kernel-manager"
                   "api/memory"
                   "driver-api/function"
                   "driver-api/package"
                   "lang/syntax"
                   "lang/type"))
     (:file "api/macro"
      :depends-on ("api/defkernel"))
     (:file "api/api"
      :depends-on ("api/context"
                   "api/defkernel"
                   "api/macro"
                   "api/memory"
                   "api/nvcc"
                   "api/timer"))
     (:file "apple-silicon/metal")
     (:file "apple-silicon/runtime"
      :depends-on ("apple-silicon/metal"))
     (:file "apple-silicon/kernel"
      :depends-on ("apple-silicon/metal"
                   "apple-silicon/runtime"))
     (:file "apple-silicon/coverage"
      :depends-on ("apple-silicon/metal"
                   "apple-silicon/runtime"))
     (:file "cuda/cuda"
      :depends-on ("api/api"
                   "api/context"
                   "driver-api/function"
                   "driver-api/package"
                   "driver-api/sdk-not-found"))
     (:file "backend/backend"
      :depends-on ("apple-silicon/metal"
                   "cuda/cuda"))
     (:file "chorus"
      :depends-on ("api/api"
                   "backend/backend"
                   "driver-api/package"
                   "lang/lang")))))
  :description "Common Lisp GPU programming for CUDA, Apple silicon, and AMD GPUs."
  :long-description #.(read-file-string (subpathname *load-pathname* "README.md"))
  :in-order-to ((test-op (test-op "chorus-test"))))
