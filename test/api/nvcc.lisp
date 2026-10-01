#|
  This file is a part of the Chorus project.
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
|#

(in-package :cl-user)
(defpackage chorus/test/api/nvcc
  (:use :cl :prove
        :chorus/api/nvcc)
  (:import-from :chorus/lang/kernel
                :make-kernel
                :kernel-define-function)
  (:import-from :chorus/lang/compiler/compile-kernel
                :compile-kernel)
  (:import-from :chorus/lang/type :void :int*))
(in-package :chorus/test/api/nvcc)

(plan nil)

(diag "NVCC helpers")

(subtest "nvcc-arch-option"
  (is (nvcc-arch-option 1 3) "-arch=sm_13")
  (is (nvcc-arch-option 2 0) "-arch=sm_20")
  (is (nvcc-arch-option 7 5) "-arch=sm_75")
  (is (nvcc-arch-option 8 6) "-arch=sm_86")
  (is (nvcc-arch-option 8 9) "-arch=sm_89")
  (is (nvcc-arch-option 9 0) "-arch=sm_90")
  (is (nvcc-arch-option 12 0) "-arch=sm_120"
      "Blackwell / RTX 5090")
  (is-error (nvcc-arch-option -1 0) type-error)
  (is-error (nvcc-arch-option 12 10) type-error))

(subtest "arch-option-p"
  (ok (arch-option-p '("-arch=sm_120")))
  (ok (arch-option-p '("-arch" "sm_120")))
  (ok (arch-option-p '("--gpu-architecture=sm_90")))
  (ok (arch-option-p '("-gencode=arch=compute_120,code=sm_120")))
  (ok (not (arch-option-p '())))
  (ok (not (arch-option-p '("-O3" "-m64"))))
  (is-error (arch-option-p :foo) type-error))

(subtest "temporary directory is writable"
  (let ((dir (chorus/api/nvcc::get-tmp-path)))
    (ok (uiop:directory-exists-p dir))
    (ok (uiop:absolute-pathname-p dir))))

(subtest "find-nvcc"
  (if (nvcc-available-p)
      (let ((nvcc (find-nvcc)))
        (ok nvcc "nvcc discovered")
        (ok (probe-file nvcc) "nvcc path exists")
        (ok (search "nvcc" (string-downcase (namestring nvcc)))))
      (skip 3 "nvcc not installed")))

(defun module-file-ok (path)
  (if (string-equal (pathname-type path) "cubin")
      (with-open-file (in path :element-type '(unsigned-byte 8))
        (plusp (file-length in)))
      (let ((text (uiop:read-file-string path)))
        (and (search ".version" text)
             (or (search ".target sm_" text)
                 (search ".target compute_" text))))))

(subtest "nvcc-compile produces a loadable module"
  (if (nvcc-available-p)
      (let ((module (nvcc-compile
                     "extern \"C\" __global__ void chorus_probe(void) { return; }")))
        (ok (probe-file module) "module file written")
        (ok (module-file-ok module) "module is PTX text or cubin"))
      (skip 2 "nvcc not installed")))

(subtest "toolkit newer than the driver emits cubin"
  (is (chorus/api/nvcc::cuda-version-from-code 13030) '(13 3))
  (is (chorus/api/nvcc::cuda-version-from-code 13040) '(13 4))
  (is (chorus/api/nvcc::cuda-version-from-code 12080) '(12 8))
  (ok (chorus/api/nvcc::emit-cubin-p '(13 4) '(13 3))
      "Toolkit 13.4 on a CUDA 13.3 driver")
  (ok (not (chorus/api/nvcc::emit-cubin-p '(13 4) '(13 4))))
  (ok (not (chorus/api/nvcc::emit-cubin-p '(13 3) '(13 4))))
  (ok (not (chorus/api/nvcc::emit-cubin-p nil '(13 3))))
  (ok (not (chorus/api/nvcc::emit-cubin-p '(13 4) nil)))
  (is (chorus/api/nvcc::directory-component-version "v13.4") '(13 4))
  (ok (null (chorus/api/nvcc::directory-component-version "bin")))
  (is (chorus/api/nvcc::version-from-directory
       (make-pathname :directory '(:absolute "CUDA" "v13.4" "bin")
                      :name "nvcc" :type "exe"))
      '(13 4))
  (is (chorus/api/nvcc::version-from-release-text
       "Cuda compilation tools, release 13.4, V13.4.59")
      '(13 4))
  (let ((driver (chorus/api/nvcc::driver-cuda-version))
        (toolkit (chorus/api/nvcc::active-toolkit-version)))
    (when (and driver toolkit)
      (is (chorus/api/nvcc::module-output-flag)
          (if (chorus/api/nvcc::emit-cubin-p toolkit driver) "-cubin" "-ptx")
          "live toolkit and driver pick one module format"))))

(subtest "option predicates"
  (ok (chorus/api/nvcc::ccbin-option-p '("-ccbin" "cl.exe")))
  (ok (chorus/api/nvcc::ccbin-option-p '("--compiler-bindir=/usr/bin/gcc")))
  (ok (not (chorus/api/nvcc::ccbin-option-p '("-arch=sm_120"))))
  (ok (chorus/api/nvcc::machine-option-p '("-m64")))
  (ok (chorus/api/nvcc::machine-option-p '("-m32" "-O3")))
  (ok (not (chorus/api/nvcc::machine-option-p '("-arch=sm_120"))))
  (is-error (chorus/api/nvcc::ccbin-option-p :foo) type-error)
  (is-error (chorus/api/nvcc::machine-option-p :foo) type-error))

(subtest "version-list>"
  (ok (chorus/api/nvcc::version-list> '(13 3) '(12 8)))
  (ok (chorus/api/nvcc::version-list> '(13 3) '(13 2)))
  (ok (not (chorus/api/nvcc::version-list> '(13 3) '(13 3))))
  (ok (not (chorus/api/nvcc::version-list> '(12 8) '(13 0))))
  (is (chorus/api/nvcc::version-key
       (make-pathname :directory '(:absolute "CUDA" "v13.3")))
      '(13 3)))

(subtest "get-nvcc-options"
  (let* ((cu (make-pathname :name "foo" :type "cu" :defaults (uiop:temporary-directory)))
         (ptx (make-pathname :type "ptx" :defaults cu))
         (opts (chorus/api/nvcc::get-nvcc-options cu ptx)))
    (ok (member (chorus/api/nvcc::module-output-flag) opts :test #'string=)
        "asks for PTX, or cubin when the toolkit is newer than the driver")
    (ok (member "-I" opts :test #'string=) "passes include path")
    (ok (member "-o" opts :test #'string=) "passes output path")
    (ok (arch-option-p opts) "architecture is present")
    (ok (uiop:directory-exists-p (chorus/api/nvcc::get-include-path))
        "chorus include directory exists")
    (when (= 8 (cffi:foreign-type-size :pointer))
      (ok (member "-m64" opts :test #'string=) "64-bit host"))
    (if (uiop:os-windows-p)
        (ok (member "-ccbin" opts :test #'string=) "Windows passes -ccbin")
        (ok (not (member "-ccbin" opts :test #'string=))
            "Unix does not pass -ccbin")))
  (let* ((cu (make-pathname :name "foo" :type "cu" :defaults (uiop:temporary-directory)))
         (ptx (make-pathname :type "ptx" :defaults cu))
         (*nvcc-options* '("-arch=sm_75")))
    (let ((opts (chorus/api/nvcc::get-nvcc-options cu ptx)))
      (ok (member "-arch=sm_75" opts :test #'string=)
          "user -arch is kept")
      (ok (not (member "-arch=native" opts :test #'string=))
          "native fallback is not added when -arch is set")))
  (let* ((cu (make-pathname :name "foo" :type "cu" :defaults (uiop:temporary-directory)))
         (ptx (make-pathname :type "ptx" :defaults cu))
         (*nvcc-options* '("-m32" "-arch=sm_75")))
    (ok (not (member "-m64" (chorus/api/nvcc::get-nvcc-options cu ptx)
                     :test #'string=))
        "user -m32 is not overridden"))
  (let* ((cu (make-pathname :name "foo" :type "cu" :defaults (uiop:temporary-directory)))
         (ptx (make-pathname :type "ptx" :defaults cu))
         (*nvcc-options* '("-ccbin" "cl.exe" "-arch=native")))
    (is (count "-ccbin" (chorus/api/nvcc::get-nvcc-options cu ptx)
               :test #'string=)
        1
        "user -ccbin is not duplicated")))

(subtest "unique stems and path pairing"
  (isnt (chorus/api/nvcc::unique-stem)
        (chorus/api/nvcc::unique-stem)
        "stems differ")
  (let ((cu (chorus/api/nvcc::get-cu-path)))
    (is (pathname-type cu) "cu")
    (is (pathname-type (chorus/api/nvcc::get-ptx-path cu))
        (chorus/api/nvcc::module-extension))
    (is (pathname-name (chorus/api/nvcc::get-ptx-path cu))
        (pathname-name cu))))

(subtest "*nvcc-binary* override"
  (let ((*nvcc-binary* "nvcc"))
    (if (nvcc-available-p)
        (ok (find-nvcc) "\"nvcc\" still auto-detects")
        (skip 1 "nvcc not installed")))
  (let ((found (find-nvcc)))
    (if found
        (let ((*nvcc-binary* (namestring found)))
          (ok (probe-file (find-nvcc)) "absolute override is used"))
        (skip 1 "nvcc not installed"))))

(subtest "*tmp-path* override"
  (if (nvcc-available-p)
      (let* ((dir (merge-pathnames
                   (make-pathname :directory '(:relative "chorus-test-tmp"))
                   (uiop:temporary-directory)))
             (*tmp-path* dir)
             (ptx (nvcc-compile
                   "extern \"C\" __global__ void chorus_tmp(void) { return; }")))
        (ok (probe-file ptx))
        (is (pathname-directory (pathname ptx))
            (pathname-directory (uiop:ensure-directory-pathname dir))
            "ptx was written under *tmp-path*"))
      (skip 2 "nvcc not installed")))

(subtest "nvcc-compile signals on invalid CUDA"
  (if (nvcc-available-p)
      (is-error (nvcc-compile "this is not valid CUDA {")
                error
                "invalid source fails")
      (skip 1 "nvcc not installed")))

(subtest "generated kernel C compiles with nvcc"
  (if (nvcc-available-p)
      (let ((kernel (make-kernel)))
        (kernel-define-function
         kernel 'chorus-roundtrip 'void '((x int*))
         '((set (aref x 0) 1) (return)))
        (let ((module (nvcc-compile (compile-kernel kernel))))
          (ok (probe-file module) "compiler output is accepted by nvcc")
          (ok (module-file-ok module) "module is PTX text or cubin")))
      (skip 2 "nvcc not installed")))

(subtest "find-msvc-cl"
  (if (uiop:os-windows-p)
      (let ((cl (find-msvc-cl)))
        (ok cl "MSVC cl.exe discovered on Windows")
        (ok (probe-file cl) "cl.exe exists")
        (ok (search "cl.exe" (string-downcase (namestring cl)))))
      (ok (null (find-msvc-cl)) "no MSVC host compiler on Unix")))

(finalize)
