#|
  This file is a part of the Chorus project.
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
|#

(in-package :chorus/cuda-libs)

;;; nppGetLibVersion (nppcore.h) returns const NppLibraryVersion*, not an
;;; NppStatus. The struct is three ints: major, minor, build. No status check.
;;;
;;; Skipped nppiAdd_32f_C1R. nppi_arithmetic_and_logical_operations.h takes
;;; NppiSize by value, and nppial64_13.dll exports only nppiAdd_32f_C1R_Ctx,
;;; which also takes NppStreamContext by value. CFFI would not match that
;;; calling convention.
;;;
;;; Skipped nppsAdd_32f and nppsSum_32f. CUDA 13.4's headers and npps64_13.dll
;;; do not provide those names. The replacements nppsAdd_32f_Ctx and
;;; nppsSum_32f_Ctx take NppStreamContext by value (pointer, four ints, a
;;; size_t, two more ints, an unsigned int, and a 32-bit workspace word).
;;;
;;; nppc is the library that exports nppGetLibVersion. npps and nppial are
;;; loaded as well; the other nppi*64_13.dll libraries have no bound entry
;;; point and are not loaded.

(defvar *npp-not-found* nil
  "True when nppc64_13.dll, npps64_13.dll, or nppial64_13.dll did not load.")

(setf *npp-not-found*
      (not (and (load-cuda-library "NPP" '("nppc64_13.dll" "nppc64.dll"))
                (load-cuda-library "NPP" '("npps64_13.dll" "npps64.dll"))
                (load-cuda-library "NPP" '("nppial64_13.dll" "nppial64.dll")))))

(deflibfun (npp-get-lib-version "nppGetLibVersion"
            :library "NPP" :not-found *npp-not-found* :check-status nil)
    :pointer)
