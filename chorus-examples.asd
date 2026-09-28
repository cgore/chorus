#|
  This file is a part of the Chorus project.
  Copyright (c) 2012-2019 Masayuki Takagi (kamonama@gmail.com)
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
|#

(defsystem "chorus-examples"
  :author "Masayuki Takagi, Christopher Mark Gore"
  :license "MIT"
  :depends-on ("chorus"
               "imago")
  :components ((:module "examples"
                :components
                ((:file "diffuse0")
                 (:file "diffuse1")
                 ; (:file "shared-memory")
                 (:file "vector-add")
                 (:file "defglobal")
                 (:file "sph")
                 (:file "sph-cpu")))))
