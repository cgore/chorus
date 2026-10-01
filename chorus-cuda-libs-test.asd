#|
  This file is a part of the Chorus project.
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
|#

(defsystem "chorus-cuda-libs-test"
  :author "Masayuki Takagi, Christopher Mark Gore"
  :license "MIT"
  :depends-on ("chorus-cuda-libs" "prove")
  :components ((:module "test"
                :components
                ((:file "cuda-libs"))))
  :perform (test-op (o c) (symbol-call :asdf :load-system c)))
