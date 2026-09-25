;;; Load this file after Quicklisp to run the local cl-cuda-test suite.
;;; Example:
;;;   sbcl --load ~/quicklisp/setup.lisp --load t/run.lisp

(setf *debugger-hook*
      (lambda (c h)
        (declare (ignore h))
        (format *error-output* "~%~%UNHANDLED ERROR: ~A~%~%" c)
        (uiop:print-backtrace :stream *error-output* :count 50)
        (uiop:quit 1)))

(let ((root (uiop:pathname-parent-directory-pathname
             (uiop:pathname-directory-pathname *load-truename*))))
  (pushnew root asdf:*central-registry* :test #'equal)
  (asdf:load-asd (merge-pathnames "cl-cuda.asd" root))
  (asdf:load-asd (merge-pathnames "cl-cuda-test.asd" root)))

(ql:quickload '(:cffi :prove :cl-cuda) :silent nil)
(format t "~%=== cl-cuda loaded ===~%")
(format t "*sdk-not-found* => ~S~%" cl-cuda:*sdk-not-found*)
(format t "find-nvcc => ~S~%" (cl-cuda:find-nvcc))
(format t "nvcc-available-p => ~S~%" (cl-cuda:nvcc-available-p))
(format t "find-msvc-cl => ~S~%" (cl-cuda.api.nvcc:find-msvc-cl))
(format t "size_t bytes => ~D~%" (cffi:foreign-type-size 'cl-cuda.driver-api:size-t))

(ql:quickload :cl-cuda-test)
(format t "~%All test files loaded.~%")
(uiop:quit 0))
