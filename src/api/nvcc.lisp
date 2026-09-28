#|
  This file is a part of the Chorus project.
  Copyright (c) 2014-2016 Masayuki Takagi (kamonama@gmail.com)
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
|#

(in-package :cl-user)
(defpackage chorus.api.nvcc
  (:use :cl)
  (:export :*tmp-path*
           :*nvcc-options*
           :*nvcc-binary*
           :nvcc-compile
           :find-nvcc
           :find-msvc-cl
           :nvcc-available-p
           :nvcc-arch-option
           :arch-option-p))
(in-package :chorus.api.nvcc)


;;;
;;; Paths and user configuration
;;;

(defvar *tmp-path* nil
  "Directory for temporary .cu and .ptx files.
   NIL means UIOP's temporary-directory (portable across Windows and Unix).")

(defvar *nvcc-options* nil
  "Additional command line options passed to nvcc.")

(defvar *nvcc-binary* nil
  "Path to nvcc. NIL or \"nvcc\" means auto-detect (PATH, CUDA_PATH, and
   well-known toolkit locations on Windows and Unix).")

(defun pathname-string (path)
  (uiop:native-namestring path))

(defun get-tmp-path ()
  (let ((path (or *tmp-path* (uiop:temporary-directory))))
    (ensure-directories-exist (uiop:ensure-directory-pathname path))))

(defun unique-stem ()
  (format nil "chorus-~A-~A-~A"
          (get-universal-time)
          (get-internal-real-time)
          (random 1000000000)))

(defun get-cu-path ()
  (make-pathname :name (unique-stem)
                 :type "cu"
                 :defaults (get-tmp-path)))

(defun get-ptx-path (cu-path)
  (make-pathname :type "ptx" :defaults cu-path))

(defun get-include-path ()
  (asdf:system-relative-pathname :chorus #P"include/"))


;;;
;;; Architecture helpers
;;;

(defun nvcc-arch-option (major minor)
  "Return an nvcc -arch=sm_XY option for compute capability MAJOR.MINOR.
   Compute capability 12.0 (Blackwell, e.g. RTX 5090) becomes sm_120."
  (check-type major (integer 0))
  (check-type minor (integer 0 9))
  (format nil "-arch=sm_~D~D" major minor))

(defun option-has-prefix-p (option prefix)
  (and (stringp option)
       (eql 0 (search prefix option))))

(defun arch-option-p (options)
  "True if OPTIONS already contains an architecture selector."
  (check-type options list)
  (some (lambda (option)
          (let ((text (if (stringp option)
                          option
                          (princ-to-string option))))
            (or (string= text "-arch")
                (string= text "--gpu-architecture")
                (option-has-prefix-p text "-arch=")
                (option-has-prefix-p text "--gpu-architecture=")
                (option-has-prefix-p text "-gencode")
                (string= text "-gencode"))))
        options))

(defun ccbin-option-p (options)
  (check-type options list)
  (some (lambda (option)
          (let ((text (if (stringp option)
                          option
                          (princ-to-string option))))
            (or (string= text "-ccbin")
                (string= text "--compiler-bindir")
                (option-has-prefix-p text "-ccbin=")
                (option-has-prefix-p text "--compiler-bindir="))))
        options))

(defun machine-option-p (options)
  (check-type options list)
  (some (lambda (option)
          (member (if (stringp option) option (princ-to-string option))
                  '("-m32" "-m64")
                  :test #'string=))
        options))


;;;
;;; Discover nvcc and the Windows host compiler
;;;

(defun path-separator ()
  (if (uiop:os-windows-p) ";" ":"))

(defun split-path-env ()
  (let ((path (uiop:getenv "PATH")))
    (when path
      (remove-if (lambda (s) (or (null s) (string= s "")))
                 (uiop:split-string path :separator (path-separator))))))

(defun probe-nvcc (directory)
  (when directory
    (let* ((dir (uiop:ensure-directory-pathname directory))
           (name (if (uiop:os-windows-p) "nvcc.exe" "nvcc"))
           (candidate (merge-pathnames name (merge-pathnames "bin/" dir)))
           (direct (merge-pathnames name dir)))
      (or (probe-file candidate)
          (probe-file direct)))))

(defun find-nvcc-on-path ()
  (let ((name (if (uiop:os-windows-p) "nvcc.exe" "nvcc")))
    (dolist (dir (split-path-env))
      (let ((candidate (merge-pathnames name
                                        (uiop:ensure-directory-pathname dir))))
        (when (probe-file candidate)
          (return (truename candidate)))))))

(defun env-cuda-roots ()
  (remove nil
          (list (uiop:getenv "CUDA_PATH")
                (uiop:getenv "CUDA_HOME")
                (uiop:getenv "CUDA_PATH_V13_3")
                (uiop:getenv "CUDA_PATH_V13_4")
                (uiop:getenv "CUDA_PATH_V13_0")
                (uiop:getenv "CUDA_PATH_V12_8"))))

(defun version-key (pathname)
  "Sort key for toolkit directories named like v13.3."
  (let* ((name (car (last (pathname-directory pathname))))
         (trimmed (if (and name (eql (char name 0) #\v))
                      (subseq name 1)
                      (or name ""))))
    (or (ignore-errors
         (mapcar #'parse-integer
                 (uiop:split-string trimmed :separator ".")))
        '(0))))

(defun windows-toolkit-nvccs ()
  (let ((root #P"C:/Program Files/NVIDIA GPU Computing Toolkit/CUDA/"))
    (when (uiop:directory-exists-p root)
      (loop for dir in (uiop:subdirectories root)
            for nvcc = (probe-nvcc dir)
            when nvcc
              collect (cons (version-key dir) nvcc)))))

(defun unix-toolkit-nvccs ()
  (remove nil
          (append (list (probe-file "/usr/local/cuda/bin/nvcc")
                        (probe-file "/opt/cuda/bin/nvcc")
                        (probe-file "/usr/bin/nvcc"))
                  (loop for dir in (append
                                    (ignore-errors
                                     (directory "/usr/local/cuda-*/"))
                                    (ignore-errors
                                     (directory "/opt/cuda-*/")))
                        collect (probe-nvcc dir)))))

(defun version-list> (a b)
  (cond
    ((null a) nil)
    ((null b) t)
    ((> (car a) (car b)) t)
    ((< (car a) (car b)) nil)
    (t (version-list> (cdr a) (cdr b)))))

(defun find-nvcc ()
  "Return the absolute path of nvcc, or NIL if it cannot be found."
  (let ((override *nvcc-binary*))
    (cond
      ((and override
            (not (member override '("nvcc" "nvcc.exe") :test #'string-equal))
            (probe-file override))
       (truename override))
      (t
       (or (find-nvcc-on-path)
           (loop for root in (env-cuda-roots)
                 thereis (probe-nvcc root))
           (let ((found (windows-toolkit-nvccs)))
             (when found
               (cdr (first (sort (copy-list found) #'version-list>
                                 :key #'car)))))
           (first (unix-toolkit-nvccs)))))))

(defun nvcc-command ()
  (or (when (and *nvcc-binary*
                 (not (member *nvcc-binary* '("nvcc" "nvcc.exe")
                              :test #'string-equal)))
        (pathname-string *nvcc-binary*))
      (let ((found (find-nvcc)))
        (when found
          (pathname-string found)))
      "nvcc"))

(defun nvcc-available-p ()
  (and (find-nvcc) t))

(defun find-msvc-cl-vswhere ()
  (let ((vswhere #P"C:/Program Files (x86)/Microsoft Visual Studio/Installer/vswhere.exe"))
    (when (probe-file vswhere)
      (multiple-value-bind (output error-output exit-code)
          (uiop:run-program
           (list (pathname-string vswhere)
                 "-latest"
                 "-products" "*"
                 "-requires" "Microsoft.VisualStudio.Component.VC.Tools.x86.x64"
                 "-find" "VC/Tools/MSVC/*/bin/Hostx64/x64/cl.exe")
           :output :string
           :error-output :string
           :ignore-error-status t)
        (declare (ignore error-output))
        (when (and exit-code (zerop exit-code))
          (let* ((lines (remove-if (lambda (s)
                                     (string= (string-trim '(#\Space #\Tab) s) ""))
                                   (uiop:split-string output
                                                      :separator '(#\Newline #\Return))))
                 (newest (first (sort (copy-list lines) #'string>)))
                 (trimmed (and newest (string-trim '(#\Space #\Tab) newest))))
            (when (and trimmed (plusp (length trimmed)) (probe-file trimmed))
              (truename trimmed))))))))

(defun find-msvc-cl-glob ()
  (let ((roots (list #P"C:/Program Files/Microsoft Visual Studio/2022/"
                     #P"C:/Program Files/Microsoft Visual Studio/2019/"
                     #P"C:/Program Files (x86)/Microsoft Visual Studio/2019/"
                     #P"C:/Program Files (x86)/Microsoft Visual Studio/2022/")))
    (loop for root in roots
          when (uiop:directory-exists-p root)
            nconc (directory
                   (merge-pathnames
                    "**/VC/Tools/MSVC/*/bin/Hostx64/x64/cl.exe"
                    root))
              into found
          finally (return (first (sort found #'string>
                                       :key #'namestring))))))

(defun find-msvc-cl ()
  "Return the absolute path of MSVC cl.exe on Windows, or NIL."
  (when (uiop:os-windows-p)
    (or (find-msvc-cl-vswhere)
        (find-msvc-cl-glob))))


;;;
;;; Compiling with NVCC
;;;

(defun arch-fallback-options ()
  (unless (arch-option-p *nvcc-options*)
    ;; CUDA 11.6+; required on CUDA 13 where the old default arch is gone.
    (list "-arch=native")))

(defun ccbin-options ()
  (when (and (uiop:os-windows-p)
             (not (ccbin-option-p *nvcc-options*)))
    (let ((cl (find-msvc-cl)))
      (when cl
        (list "-ccbin" (pathname-string cl))))))

(defun machine-options ()
  (unless (machine-option-p *nvcc-options*)
    (when (= 8 (cffi:foreign-type-size :pointer))
      (list "-m64"))))

(defun windows-compat-options ()
  (when (and (uiop:os-windows-p)
             (not (member "--allow-unsupported-compiler" *nvcc-options*
                          :test #'string=)))
    (list "--allow-unsupported-compiler")))

(defun get-nvcc-options (cu-path ptx-path)
  (let ((include-path (get-include-path)))
    (append *nvcc-options*
            (arch-fallback-options)
            (ccbin-options)
            (machine-options)
            (windows-compat-options)
            (list "-I" (pathname-string include-path)
                  "-ptx"
                  "-o" (pathname-string ptx-path)
                  (pathname-string cu-path)))))

(defun output-cuda-code (cu-path cuda-code)
  (with-open-file (out cu-path :direction :output
                               :if-exists :supersede
                               :if-does-not-exist :create)
    (princ cuda-code out)))

(defun print-nvcc-command (binary options)
  (format t "~A~{ ~A~}~%" binary options))

(defun run-nvcc-command (cu-path ptx-path)
  (let* ((binary (nvcc-command))
         (options (get-nvcc-options cu-path ptx-path))
         (command (cons binary options)))
    (print-nvcc-command binary options)
    (multiple-value-bind (stdout stderr exit-code)
        (uiop:run-program command
                          :output :string
                          :error-output :string
                          :ignore-error-status t)
      (unless (and (integerp exit-code) (zerop exit-code))
        (error "nvcc exits with code: ~A~%~A~%~A"
               exit-code
               stdout
               stderr))
      (pathname-string ptx-path))))

(defun nvcc-compile (cuda-code)
  (let* ((cu-path (get-cu-path))
         (ptx-path (get-ptx-path cu-path)))
    (output-cuda-code cu-path cuda-code)
    (run-nvcc-command cu-path ptx-path)))
