#|
  This file is a part of the Chorus project.
  Copyright (c) 2012-2016 Masayuki Takagi (kamonama@gmail.com)
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
|#

(in-package :cl-user)
(defpackage chorus/lang/data
  (:use :cl)
  (:export ;; Symbol
           :chorus-symbol
           :chorus-symbol-p
           ;; Bool
           :chorus-bool-p
           ;; Int
           :chorus-int-p
           ;; Float
           :chorus-float-p
           ;; Double
           :chorus-double-p
           ;; Float3
           :float3
           :make-float3
           :float3-x
           :float3-y
           :float3-z
           :float3-p
           :float3-=
           :with-float3
           ;; Float4
           :float4
           :make-float4
           :float4-x
           :float4-y
           :float4-z
           :float4-w
           :float4-p
           :float4-=
           :with-float4
           ;; Double3
           :double3
           :make-double3
           :double3-x
           :double3-y
           :double3-z
           :double3-p
           :double3-=
           :with-double3
           ;; Double4
           :double4
           :make-double4
           :double4-x
           :double4-y
           :double4-z
           :double4-w
           :double4-p
           :double4-=
           :with-double4
           :int2
           :make-int2
           :int2-x
           :int2-y
           :int2-p
           :int2-=
           :with-int2
           :int4
           :make-int4
           :int4-x
           :int4-y
           :int4-z
           :int4-w
           :int4-p
           :int4-=
           :with-int4
           :uint2
           :make-uint2
           :uint2-x
           :uint2-y
           :uint2-p
           :uint2-=
           :with-uint2
           :uint4
           :make-uint4
           :uint4-x
           :uint4-y
           :uint4-z
           :uint4-w
           :uint4-p
           :uint4-=
           :with-uint4
           :half2
           :make-half2
           :half2-x
           :half2-y
           :half2-p
           :half2-=
           :with-half2)
  (:import-from :alexandria
                :once-only))
(in-package :chorus/lang/data)


;;;
;;; Symbol
;;;

(deftype chorus-symbol ()
  `(satisfies chorus-symbol-p))

(defun chorus-symbol-p (object)
  (symbolp object))


;;;
;;; Bool
;;;

(defun chorus-bool-p (object)
  (typep object 'boolean))


;;;
;;; Int
;;;

(defun chorus-int-p (object)
  (integerp object))


;;;
;;; Float
;;;

(defun chorus-float-p (object)
  (typep object 'single-float))


;;;
;;; Double
;;;

(defun chorus-double-p (object)
  (typep object 'double-float))


;;;
;;; Float3
;;;

(defstruct (float3 (:constructor make-float3 (x y z)))
  (x 0.0 :type single-float)
  (y 0.0 :type single-float)
  (z 0.0 :type single-float))

(defun float3-= (a b)
  (and (= (float3-x a) (float3-x b))
       (= (float3-y a) (float3-y b))
       (= (float3-z a) (float3-z b))))

(cffi:defcstruct (float3 :class float3-c)
  (x :float)
  (y :float)
  (z :float))

(defmacro with-float3 ((x y z) value &body body)
  (once-only (value)
    `(let ((,x (float3-x ,value))
           (,y (float3-y ,value))
           (,z (float3-z ,value)))
       (declare (ignorable ,x ,y ,z))
       ,@body)))

(defmethod cffi:translate-into-foreign-memory ((value float3)
                                               (type float3-c)
                                               ptr)
  (cffi:with-foreign-slots ((x y z) ptr (:struct float3))
    (setf x (float3-x value)
          y (float3-y value)
          z (float3-z value))))

(defmethod cffi:translate-from-foreign (value (type float3-c))
  (cffi:with-foreign-slots ((x y z) value (:struct float3))
    (make-float3 x y z)))


;;;
;;; Float4
;;;

(defstruct (float4 (:constructor make-float4 (x y z w)))
  (x 0.0 :type single-float)
  (y 0.0 :type single-float)
  (z 0.0 :type single-float)
  (w 0.0 :type single-float))

(defun float4-= (a b)
  (and (= (float4-x a) (float4-x b))
       (= (float4-y a) (float4-y b))
       (= (float4-z a) (float4-z b))
       (= (float4-w a) (float4-w b))))

(cffi:defcstruct (float4 :class float4-c)
  (x :float)
  (y :float)
  (z :float)
  (w :float))

(defmacro with-float4 ((x y z w) value &body body)
  (once-only (value)
    `(let ((,x (float4-x ,value))
           (,y (float4-y ,value))
           (,z (float4-z ,value))
           (,w (float4-w ,value)))
       (declare (ignorable ,x ,y ,z ,w))
       ,@body)))

(defmethod cffi:translate-into-foreign-memory ((value float4)
                                               (type float4-c)
                                               ptr)
  (cffi:with-foreign-slots ((x y z w) ptr (:struct float4))
    (setf x (float4-x value)
          y (float4-y value)
          z (float4-z value)
          w (float4-w value))))

(defmethod cffi:translate-from-foreign (value (type float4-c))
  (cffi:with-foreign-slots ((x y z w) value (:struct float4))
    (make-float4 x y z w)))


;;;
;;; Double3
;;;

(defstruct (double3 (:constructor make-double3 (x y z)))
  (x 0.0d0 :type double-float)
  (y 0.0d0 :type double-float)
  (z 0.0d0 :type double-float))

(defun double3-= (a b)
  (and (= (double3-x a) (double3-x b))
       (= (double3-y a) (double3-y b))
       (= (double3-z a) (double3-z b))))

(cffi:defcstruct (double3 :class double3-c)
  (x :double)
  (y :double)
  (z :double))

(defmacro with-double3 ((x y z) value &body body)
  (once-only (value)
    `(let ((,x (double3-x ,value))
           (,y (double3-y ,value))
           (,z (double3-z ,value)))
       (declare (ignorable ,x ,y ,z))
       ,@body)))

(defmethod cffi:translate-into-foreign-memory ((value double3)
                                               (type double3-c)
                                               ptr)
  (cffi:with-foreign-slots ((x y z) ptr (:struct double3))
    (setf x (double3-x value)
          y (double3-y value)
          z (double3-z value))))

(defmethod cffi:translate-from-foreign (value (type double3-c))
  (cffi:with-foreign-slots ((x y z) value (:struct double3))
    (make-double3 x y z)))


;;;
;;; Double4
;;;

(defstruct (double4 (:constructor make-double4 (x y z w)))
  (x 0.0d0 :type double-float)
  (y 0.0d0 :type double-float)
  (z 0.0d0 :type double-float)
  (w 0.0d0 :type double-float))

(defun double4-= (a b)
  (and (= (double4-x a) (double4-x b))
       (= (double4-y a) (double4-y b))
       (= (double4-z a) (double4-z b))
       (= (double4-w a) (double4-w b))))

(cffi:defcstruct (double4 :class double4-c)
  (x :double)
  (y :double)
  (z :double)
  (w :double))

(defmacro with-double4 ((x y z w) value &body body)
  (once-only (value)
    `(let ((,x (double4-x ,value))
           (,y (double4-y ,value))
           (,z (double4-z ,value))
           (,w (double4-w ,value)))
       (declare (ignorable ,x ,y ,z ,w))
       ,@body)))

(defmethod cffi:translate-into-foreign-memory ((value double4)
                                               (type double4-c)
                                               ptr)
  (cffi:with-foreign-slots ((x y z w) ptr (:struct double4))
    (setf x (double4-x value)
          y (double4-y value)
          z (double4-z value)
          w (double4-w value))))

(defmethod cffi:translate-from-foreign (value (type double3-c))
  (cffi:with-foreign-slots ((x y z w) value (:struct double4))
    (make-double4 x y z w)))


;;;
;;; CURAND State XORWOW
;;;

(cffi:defcstruct curand-state-xorwow
  (d :unsigned-int)
  (v :unsigned-int :count 5)
  (boxmuller-flag :int)
  (boxmuller-flag-double :int)
  (boxmuller-extra :float)
  (boxmuller-extra-double :double))


;;;
;;; Int2
;;;

(defstruct (int2 (:constructor make-int2 (x y)))
  (x 0 :type integer)
  (y 0 :type integer))

(defun int2-= (a b)
  (and (= (int2-x a) (int2-x b))
       (= (int2-y a) (int2-y b))))

(cffi:defcstruct (int2 :class int2-c)
  (x :int)
  (y :int))

(defmacro with-int2 ((x y) value &body body)
  (once-only (value)
    `(let ((,x (int2-x ,value))
           (,y (int2-y ,value)))
       (declare (ignorable ,x ,y))
       ,@body)))

(defmethod cffi:translate-into-foreign-memory ((value int2) (type int2-c) ptr)
  (cffi:with-foreign-slots ((x y) ptr (:struct int2))
    (setf x (int2-x value)
          y (int2-y value))))

(defmethod cffi:translate-from-foreign (value (type int2-c))
  (cffi:with-foreign-slots ((x y) value (:struct int2))
    (make-int2 x y)))


;;;
;;; Int4
;;;

(defstruct (int4 (:constructor make-int4 (x y z w)))
  (x 0 :type integer)
  (y 0 :type integer)
  (z 0 :type integer)
  (w 0 :type integer))

(defun int4-= (a b)
  (and (= (int4-x a) (int4-x b))
       (= (int4-y a) (int4-y b))
       (= (int4-z a) (int4-z b))
       (= (int4-w a) (int4-w b))))

(cffi:defcstruct (int4 :class int4-c)
  (x :int)
  (y :int)
  (z :int)
  (w :int))

(defmacro with-int4 ((x y z w) value &body body)
  (once-only (value)
    `(let ((,x (int4-x ,value))
           (,y (int4-y ,value))
           (,z (int4-z ,value))
           (,w (int4-w ,value)))
       (declare (ignorable ,x ,y ,z ,w))
       ,@body)))

(defmethod cffi:translate-into-foreign-memory ((value int4) (type int4-c) ptr)
  (cffi:with-foreign-slots ((x y z w) ptr (:struct int4))
    (setf x (int4-x value)
          y (int4-y value)
          z (int4-z value)
          w (int4-w value))))

(defmethod cffi:translate-from-foreign (value (type int4-c))
  (cffi:with-foreign-slots ((x y z w) value (:struct int4))
    (make-int4 x y z w)))


;;;
;;; Uint2
;;;

(defstruct (uint2 (:constructor make-uint2 (x y)))
  (x 0 :type (unsigned-byte 32))
  (y 0 :type (unsigned-byte 32)))

(defun uint2-= (a b)
  (and (= (uint2-x a) (uint2-x b))
       (= (uint2-y a) (uint2-y b))))

(cffi:defcstruct (uint2 :class uint2-c)
  (x :unsigned-int)
  (y :unsigned-int))

(defmacro with-uint2 ((x y) value &body body)
  (once-only (value)
    `(let ((,x (uint2-x ,value))
           (,y (uint2-y ,value)))
       (declare (ignorable ,x ,y))
       ,@body)))

(defmethod cffi:translate-into-foreign-memory ((value uint2) (type uint2-c) ptr)
  (cffi:with-foreign-slots ((x y) ptr (:struct uint2))
    (setf x (uint2-x value)
          y (uint2-y value))))

(defmethod cffi:translate-from-foreign (value (type uint2-c))
  (cffi:with-foreign-slots ((x y) value (:struct uint2))
    (make-uint2 x y)))


;;;
;;; Uint4
;;;

(defstruct (uint4 (:constructor make-uint4 (x y z w)))
  (x 0 :type (unsigned-byte 32))
  (y 0 :type (unsigned-byte 32))
  (z 0 :type (unsigned-byte 32))
  (w 0 :type (unsigned-byte 32)))

(defun uint4-= (a b)
  (and (= (uint4-x a) (uint4-x b))
       (= (uint4-y a) (uint4-y b))
       (= (uint4-z a) (uint4-z b))
       (= (uint4-w a) (uint4-w b))))

(cffi:defcstruct (uint4 :class uint4-c)
  (x :unsigned-int)
  (y :unsigned-int)
  (z :unsigned-int)
  (w :unsigned-int))

(defmacro with-uint4 ((x y z w) value &body body)
  (once-only (value)
    `(let ((,x (uint4-x ,value))
           (,y (uint4-y ,value))
           (,z (uint4-z ,value))
           (,w (uint4-w ,value)))
       (declare (ignorable ,x ,y ,z ,w))
       ,@body)))

(defmethod cffi:translate-into-foreign-memory ((value uint4) (type uint4-c) ptr)
  (cffi:with-foreign-slots ((x y z w) ptr (:struct uint4))
    (setf x (uint4-x value)
          y (uint4-y value)
          z (uint4-z value)
          w (uint4-w value))))

(defmethod cffi:translate-from-foreign (value (type uint4-c))
  (cffi:with-foreign-slots ((x y z w) value (:struct uint4))
    (make-uint4 x y z w)))


;;;
;;; Half2 — two raw IEEE half bit patterns
;;;

(defstruct (half2 (:constructor make-half2 (x y)))
  (x 0 :type (unsigned-byte 16))
  (y 0 :type (unsigned-byte 16)))

(defun half2-= (a b)
  (and (= (half2-x a) (half2-x b))
       (= (half2-y a) (half2-y b))))

(cffi:defcstruct (half2 :class half2-c)
  (x :uint16)
  (y :uint16))

(defmacro with-half2 ((x y) value &body body)
  (once-only (value)
    `(let ((,x (half2-x ,value))
           (,y (half2-y ,value)))
       (declare (ignorable ,x ,y))
       ,@body)))

(defmethod cffi:translate-into-foreign-memory ((value half2) (type half2-c) ptr)
  (cffi:with-foreign-slots ((x y) ptr (:struct half2))
    (setf x (half2-x value)
          y (half2-y value))))

(defmethod cffi:translate-from-foreign (value (type half2-c))
  (cffi:with-foreign-slots ((x y) value (:struct half2))
    (make-half2 x y)))
