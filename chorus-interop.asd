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
  ;; A component name is the file's path under interop/src/. ASDF resolves
  ;; :depends-on among siblings, so the directory stays in the name.
  :components ((:module "interop/src"
                :components
                ((:file "driver-api/package")
                 (:file "driver-api/type"
                  :depends-on ("driver-api/package"))
                 (:file "driver-api/enum"
                  :depends-on ("driver-api/package"))
                 (:file "driver-api/function"
                  :depends-on ("driver-api/package"
                               "driver-api/type"))
                 (:file "api/memory"
                  :depends-on ("driver-api/enum"
                               "driver-api/function"
                               "driver-api/package"
                               "driver-api/type"))
                 (:file "api/context"
                  :depends-on ("driver-api/function"
                               "driver-api/package"))
                 (:file "api/defkernel"
                  :depends-on ("api/memory"
                               "driver-api/package"))
                 (:file "api/api"
                  :depends-on ("api/context"
                               "api/defkernel"
                               "api/memory"))
                 (:file "chorus-interop"
                  :depends-on ("api/api"
                               "driver-api/package")))))
  :description "Chorus with OpenGL interoperability."
  ;; :long-description #.(read-file-string (subpathname *load-pathname* "README.md"))
  :in-order-to ((test-op (test-op "chorus-interop-test"))))
