#|
  This file is a part of the Chorus project.
  Copyright (c) 2012-2019 Masayuki Takagi (kamonama@gmail.com)
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
|#

(defsystem "chorus-interop-test"
  :author "Masayuki Takagi, Christopher Mark Gore"
  :license "MIT"
  :depends-on ("chorus-interop" "prove")
  :components ((:module "interop/t"
                :components
                ((:file "chorus-interop")))))
