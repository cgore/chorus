#|
  This file is a part of the Chorus project.
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
|#

;;; Load this file after Quicklisp to run the local chorus-test suite.
;;; Example:
;;;   sbcl --load ~/quicklisp/setup.lisp --load test/run.lisp

(setf *debugger-hook*
      (lambda (c h)
        (declare (ignore h))
        (format *error-output* "~%~%UNHANDLED ERROR: ~A~%~%" c)
        (uiop:print-backtrace :stream *error-output* :count 50)
        (uiop:quit 1)))

(let ((root (uiop:pathname-parent-directory-pathname
             (uiop:pathname-directory-pathname *load-truename*))))
  (pushnew root asdf:*central-registry* :test #'equal)
  (asdf:load-asd (merge-pathnames "chorus.asd" root))
  (asdf:load-asd (merge-pathnames "chorus-test.asd" root)))

(ql:quickload '(:cffi :prove :chorus) :silent nil)
(format t "~%=== chorus loaded ===~%")
(format t "*sdk-not-found* => ~S~%" chorus:*sdk-not-found*)
(format t "find-nvcc => ~S~%" (chorus:find-nvcc))
(format t "nvcc-available-p => ~S~%" (chorus:nvcc-available-p))
(format t "find-msvc-cl => ~S~%" (chorus/api/nvcc:find-msvc-cl))
(format t "size_t bytes => ~D~%" (cffi:foreign-type-size 'chorus/driver-api:size-t))

(ql:quickload :chorus-test)
(format t "~%All test files loaded.~%")
(uiop:quit 0)
