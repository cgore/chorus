#|
  This file is a part of the Chorus project.
  Copyright (c) 2012-2019 Masayuki Takagi (kamonama@gmail.com)
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
|#

(defsystem "chorus-test"
  :author "Masayuki Takagi, Christopher Mark Gore"
  :license "MIT"
  :depends-on ("chorus"
               "prove")
  :components ((:module "test"
                :serial t
                :components
                ((:file "platform")
                 (:module "driver-api"
                  :serial t
                  :components
                  ((:file "driver-api")))
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
                   (:file "compiler/compile-kernel")))
                 (:module "api"
                  :serial t
                  :components
                  ((:file "nvcc")
                   (:file "context")
                   (:file "kernel-manager")
                   (:file "memory")
                   (:file "defkernel")
                   (:file "timer")
                   (:file "smoke")
                   (:file "extended")))
                 (:file "backend")
                 (:file "apple-silicon")
                 (:file "apple-silicon-coverage"))))
  :perform (test-op (o c) (symbol-call :asdf :load-system c)))
