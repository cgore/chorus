#|
  This file is a part of the Chorus project.
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
|#

(in-package :chorus/cuda-libs)

(defun path-directories ()
  "Directories listed in PATH, in order. Empty entries are dropped."
  (let ((path (uiop:getenv "PATH")))
    (when path
      (loop for piece in (uiop:split-string path :separator ";")
            unless (zerop (length piece))
            collect (uiop:ensure-directory-pathname piece)))))

(defun cuda-search-directories ()
  "CUDA_PATH/bin/x64, CUDA_PATH/bin, then PATH. CUDA_HOME is accepted if CUDA_PATH is unset."
  (let ((cuda (or (uiop:getenv "CUDA_PATH")
                  (uiop:getenv "CUDA_HOME"))))
    (append
     (when (and cuda (plusp (length cuda)))
       (let ((root (uiop:ensure-directory-pathname cuda)))
         (list (merge-pathnames #P"bin/x64/" root)
               (merge-pathnames #P"bin/" root))))
     (path-directories))))

(defun dll-in-directory (directory filename)
  (handler-case
      (let ((candidate (merge-pathnames filename directory)))
        (when (probe-file candidate)
          (truename candidate)))
    (error ()
      nil)))

(defun find-cuda-dll (filenames)
  "First existing FILENAMES entry in the CUDA search directories."
  (loop for filename in filenames
        do (loop for directory in (cuda-search-directories)
                 for found = (dll-in-directory directory filename)
                 when found
                   do (return-from find-cuda-dll found))))

(defun load-cuda-library (logical-name filenames)
  "Load the first of FILENAMES that exists and loads.
Search each name under CUDA_PATH/bin/x64, then CUDA_PATH/bin, then PATH.
Pass an absolute pathname to cffi:load-foreign-library. LOGICAL-NAME identifies
the toolkit library for the caller. Return T on success, NIL if every candidate
is missing or fails to load. A missing DLL does not signal."
  (check-type logical-name string)
  (check-type filenames list)
  (loop for filename in filenames
        for path = (find-cuda-dll (list filename))
        when path
          do (handler-case
                 (progn
                   (cffi:load-foreign-library path)
                   (return t))
               (error ()
                 nil))))

(defmacro deflibfun ((name c-name &key library not-found (check-status t))
                     return-type &body arguments)
  "Checked wrapper around cffi:defcfun.
If NOT-FOUND is true, NAME signals instead of entering the foreign call.
When CHECK-STATUS is true, a non-zero integer status signals and the
condition includes that status. CHECK-STATUS is NIL for entry points that
do not return a status enum (nppGetLibVersion, cudnnGetVersion)."
  (let ((%name (format-symbol (symbol-package name) "%~A" name))
        (vars (mapcar #'car arguments))
        (status (gensym "STATUS")))
    `(progn
       (cffi:defcfun (,%name ,c-name) ,return-type ,@arguments)
       (defun ,name ,vars
         (when ,not-found
           (error "~A is not available; the ~A library did not load."
                  ',name ,library))
         ,@(if check-status
               `((let ((,status (,%name ,@vars)))
                   (unless (zerop ,status)
                     (error "~A failed with status ~D." ',name ,status))
                   ,status))
               `((,%name ,@vars)))))))
