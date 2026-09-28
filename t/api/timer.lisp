#|
  This file is a part of the Chorus project.
  Copyright (c) 2014 Masayuki Takagi (kamonama@gmail.com)
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
|#

(in-package :cl-user)
(defpackage chorus-test.api.timer
  (:use :cl :prove
        :chorus.api.timer
        :chorus.api.context))
(in-package :chorus-test.api.timer)

(plan nil)


;;;
;;; test TIMER
;;;

(diag "TIMER")

(with-cuda (0)
  (with-timer (timer)
    ;; start timer
    (start-timer timer)
    ;; sleep
    (sleep 1)
    ;; stop and shnchronize timer
    (stop-timer timer)
    (synchronize-timer timer)
    ;; get elapsed time
    (ok (elapsed-time timer))))


(finalize)
