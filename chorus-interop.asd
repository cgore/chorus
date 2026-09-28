#|
  This file is a part of the Chorus project.
  Copyright (c) 2014-2019 Masayuki Takagi (kamonama@gmail.com)
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
|#

(defsystem "chorus-interop"
  :version "0.1"
  :author "Masayuki Takagi, Christopher Mark Gore"
  :license "MIT"
  :depends-on (:chorus :cl-opengl :cl-glu :cl-glut)
  :components ((:module "interop/src"
                :serial t
                :components
                ((:module "driver-api"
                  :serial t
                  :components
                  ((:file "package")
                   (:file "type")
                   (:file "enum")
                   (:file "function")))
                 (:module "api"
                  :serial t
                  :components
                  ((:file "memory")
                   (:file "context")
                   (:file "defkernel")
                   (:file "api")))
                 (:file "chorus-interop"))))
  :description "Chorus with OpenGL interoperability."
  ;; :long-description #.(read-file-string (subpathname *load-pathname* "README.markdown"))
  :in-order-to ((test-op (test-op "chorus-interop-test"))))
