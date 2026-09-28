#|
  This file is a part of the Chorus project.
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
|#

(in-package :cl-user)
(defpackage chorus/test/backend
  (:use :cl :prove
        :chorus))
(in-package :chorus/test/backend)

(plan nil)

(diag "generic backend")

(subtest "native packages stay reachable"
  (ok (fboundp 'chorus/cuda:cu-init) "chorus/cuda:cu-init")
  (ok (fboundp 'chorus/cuda:with-cuda) "chorus/cuda:with-cuda")
  (ok (fboundp 'chorus/cuda:defkernel) "chorus/cuda:defkernel")
  (ok (fboundp 'chorus/apple-silicon:devices) "chorus/apple-silicon:devices"))

(subtest "cuda availability follows the driver"
  (is (chorus/cuda:available-p)
      (not chorus/driver-api:*sdk-not-found*)))

(subtest "an unavailable backend signals"
  (cond
    ((chorus/cuda:available-p)
     (ok (chorus:list-devices :cuda) "cuda devices"))
    (t
     (is-error (chorus:list-devices :cuda)
               'backend-unavailable))))

#+darwin
(subtest "apple silicon lists Metal devices"
  (ok (chorus/apple-silicon:available-p) "Metal is available")
  (let ((native (chorus/apple-silicon:devices))
        (generic (let ((*backend* nil))
                   (chorus:list-devices))))
    (ok native "at least one Metal device")
    (is (backend-name (current-backend)) :apple-silicon)
    (is (length generic) (length native))
    (dolist (device native)
      (ok (plusp (length (chorus/apple-silicon:device-name device)))
          (format nil "device name ~A"
                  (chorus/apple-silicon:device-name device)))
      (ok (not (cffi:null-pointer-p
                (chorus/apple-silicon:device-pointer device)))
          "device pointer is live"))
    (dolist (device generic)
      (is (backend-name (device-backend device)) :apple-silicon)
      (ok (plusp (length (device-name device))))
      (ok (not (cffi:null-pointer-p (device-native device)))))))

(subtest "with-backend binds *backend*"
  (let ((name (if (chorus/apple-silicon:available-p)
                  :apple-silicon
                  :cuda)))
    (with-backend (name)
      (is (backend-name (current-backend)) name)
      (ok (list-devices)))))

(finalize)
