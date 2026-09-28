#|
  This file is a part of the Chorus project.
  Copyright (c) 2012-2014 Masayuki Takagi (kamonama@gmail.com)
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
|#

(in-package :cl-user)
(eval-when (:compile-toplevel :load-toplevel :execute)
  (locally
      (declare #+sbcl
               (sb-ext:muffle-conditions sb-kernel::package-at-variance))
    (handler-bind
        (#+sbcl (sb-kernel::package-at-variance #'muffle-warning))
      (defpackage chorus
        (:use :cl :cl-reexport)))))
(in-package :chorus)

(reexport-from :chorus/backend)
(reexport-from :chorus/driver-api
               :include '(:*show-messages*
                          :*sdk-not-found*))
(reexport-from :chorus/lang)
(reexport-from :chorus/api)
