#|
  This file is a part of the Chorus project.
  Copyright (c) 2012-2014 Masayuki Takagi (kamonama@gmail.com)
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
|#

(in-package :cl-user)
(defpackage chorus/lang/type
  (:use :cl
        :chorus/driver-api
        :chorus/lang/data)
  (:export ;; Chorus types
           :void
           :bool
           :int
           :float
           :double
           :curand-state-xorwow
           :float3
           :float4
           :double3
           :double4
           :bool*
           :int*
           :float*
           :double*
           :curand-state-xorwow*
           :float3*
           :float4*
           :double3*
           :double4*
           :int8
           :uint8
           :int16
           :uint16
           :uint
           :int64
           :uint64
           :size-t
           :half
           :bfloat16
           :fp8
           :fp4
           :int2
           :int4
           :uint2
           :uint4
           :half2
           :int8*
           :uint8*
           :int16*
           :uint16*
           :uint*
           :int64*
           :uint64*
           :size-t*
           :half*
           :bfloat16*
           :fp8*
           :fp4*
           :int2*
           :int4*
           :uint2*
           :uint4*
           :half2*
           :register-structure-type
           :user-structures
           :extended-float-type-name-p
           ;; Type
           :chorus-type
           :chorus-type-p
           :cffi-type
           :cffi-type-size
           :cuda-type
           :scalar-cuda-type
           ;; Scalar type
           :scalar-type-p
           ;; Structure type
           :structure-type-p
           ;; Structure accessor
           :structure-accessor-p
           :structure-from-accessor
           :structure-accessor-cuda-accessor
           :structure-accessor-return-type
           ;; Array type
           :array-type-p
           :array-type-base
           :array-type-dimension
           :array-type)
  (:import-from :alexandria
                :format-symbol))
(in-package :chorus/lang/type)


;;;
;;; Type
;;;

(deftype chorus-type ()
  `(satisfies chorus-type-p))

(defun chorus-type-p (object)
  (or (scalar-type-p object)
      (structure-type-p object)
      (array-type-p object)))

(defun cffi-type (type)
  (cond
    ((scalar-type-p type) (scalar-cffi-type type))
    ((structure-type-p type) (structure-cffi-type type))
    ((array-type-p type) (array-cffi-type type))
    (t (error "The value ~S is an invalid type." type))))

(defun cffi-type-size (type)
  (cond
    ((scalar-type-p type) (scalar-cffi-type-size type))
    ((structure-type-p type) (structure-cffi-type-size type))
    ((array-type-p type) (array-cffi-type-size type))
    (t (error "The value ~S is an invalid type." type))))

(defun cuda-type (type)
  (cond
    ((scalar-type-p type) (scalar-cuda-type type))
    ((structure-type-p type) (structure-cuda-type type))
    ((array-type-p type) (array-cuda-type type))
    (t (error "The value ~S is an invalid type." type))))


;;;
;;; Scalar type
;;;

(defparameter +scalar-types+
  '((void :void "void")
    (bool (:boolean :int8) "bool")
    (int :int "int")
    (int8 :int8 "signed char")
    (uint8 :uint8 "unsigned char")
    (int16 :int16 "short")
    (uint16 :uint16 "unsigned short")
    (uint :unsigned-int "unsigned int")
    (int64 :int64 "long long")
    (uint64 :uint64 "unsigned long long")
    (size-t size-t "size_t")
    (float :float "float")
    (double :double "double")
    ;; Host storage is the raw bit pattern. Device code uses the CUDA type.
    (half :uint16 "__half")
    (bfloat16 :uint16 "__nv_bfloat16")
    (fp8 :uint8 "__nv_fp8_e4m3")
    (fp4 :uint8 "__nv_fp4_e2m1")
    (curand-state-xorwow (:struct curand-state-xorwow)
                         "curandStateXORWOW_t")))

(defun scalar-type-p (object)
  (and (assoc object +scalar-types+)
       t))

(defun scalar-cffi-type (type)
  (unless (scalar-type-p type)
    (error "The vaue ~S is an invalid type." type))
  (cadr (assoc type +scalar-types+)))

(defun scalar-cffi-type-size (type)
  (cffi:foreign-type-size (scalar-cffi-type type)))

(defun scalar-cuda-type (type)
  (unless (scalar-type-p type)
    (error "The vaue ~S is an invalid type." type))
  (caddr (assoc type +scalar-types+)))


;;;
;;; Structure type
;;;

(defparameter +builtin-structures+
  '((float3 "float3" ((float3-x "x" float)
                      (float3-y "y" float)
                      (float3-z "z" float)))
    (float4 "float4" ((float4-x "x" float)
                      (float4-y "y" float)
                      (float4-z "z" float)
                      (float4-w "w" float)))
    (double3 "double3" ((double3-x "x" double)
                        (double3-y "y" double)
                        (double3-z "z" double)))
    (double4 "double4" ((double4-x "x" double)
                        (double4-y "y" double)
                        (double4-z "z" double)
                        (double4-w "w" double)))
    (int2 "int2" ((int2-x "x" int)
                  (int2-y "y" int)))
    (int4 "int4" ((int4-x "x" int)
                  (int4-y "y" int)
                  (int4-z "z" int)
                  (int4-w "w" int)))
    (uint2 "uint2" ((uint2-x "x" uint)
                    (uint2-y "y" uint)))
    (uint4 "uint4" ((uint4-x "x" uint)
                    (uint4-y "y" uint)
                    (uint4-z "z" uint)
                    (uint4-w "w" uint)))
    (half2 "__half2" ((half2-x "x" half)
                      (half2-y "y" half)))))

(defparameter +user-structures+ nil)

(defparameter +structure-table+ nil)

(defparameter +structure-types+ nil)

(defun structure-type-p (object)
  (and (member object +structure-types+)
       t))

(defun structure-cffi-type (type)
  (unless (structure-type-p type)
    (error "The vaue ~S is an invalid type." type))
  `(:struct ,type))

(defun structure-cffi-type-size (type)
  (cffi:foreign-type-size (structure-cffi-type type)))

(defun structure-cuda-type (type)
  (unless (structure-type-p type)
    (error "The vaue ~S is an invalid type." type))
  (cadr (assoc type +structure-table+)))

(defun structure-accessors (type)
  (unless (structure-type-p type)
    (error "The vaue ~S is an invalid type." type))
  (caddr (assoc type +structure-table+)))


;;;
;;; Structure type - accessor
;;;

(defparameter +accessor->structure+ nil)

(defun user-structures ()
  +user-structures+)

(defun rebuild-structure-indexes ()
  (setf +structure-table+ (append +builtin-structures+ +user-structures+))
  (setf +structure-types+ (mapcar #'car +structure-table+))
  (setf +accessor->structure+
        (loop for structure in +structure-types+
              append (loop for (accessor nil nil)
                             in (structure-accessors structure)
                           collect (list accessor structure))))
  nil)

(defun register-structure-type (name accessors &key cuda-name builtin)
  "Register a kernel structure. ACCESSORS are (ACCESSOR C-FIELD ELEMENT-TYPE)."
  (unless (and (symbolp name) (every #'consp accessors))
    (error "The value ~S is an invalid structure type." name))
  (let ((cuda (or cuda-name
                  (substitute #\_ #\- (string-downcase (symbol-name name)))))
        (entry nil))
    (setf entry (list name cuda accessors))
    (if builtin
        (setf +builtin-structures+
              (append (remove name +builtin-structures+ :key #'car)
                      (list entry)))
        (setf +user-structures+
              (append (remove name +user-structures+ :key #'car)
                      (list entry))))
    (rebuild-structure-indexes)
    name))

(defparameter +extended-float-type-names+
  '("HALF2" "BFLOAT16" "FP8" "FP4" "HALF"))

(defun extended-float-type-name-p (type)
  (and (symbolp type)
       (let ((name (symbol-name type)))
         (some (lambda (base)
                 (or (string= name base)
                     (and (> (length name) (length base))
                          (string= (subseq name 0 (length base)) base)
                          (every (lambda (char) (char= char #\*))
                                 (subseq name (length base))))))
               +extended-float-type-names+))))

(rebuild-structure-indexes)

(defun %structure-from-accessor (accessor)
  (cadr (assoc accessor +accessor->structure+)))

(defun structure-accessor-p (accessor)
  (and (%structure-from-accessor accessor)
       t))

(defun structure-from-accessor (accessor)
  (or (%structure-from-accessor accessor)
      (error "The value ~S is not a structure accessor." accessor)))

(defun structure-accessor-cuda-accessor (accessor)
  (let ((structure (structure-from-accessor accessor)))
    (second (assoc accessor (structure-accessors structure)))))

(defun structure-accessor-return-type (accessor)
  (let ((structure (structure-from-accessor accessor)))
    (third (assoc accessor (structure-accessors structure)))))


;;;
;;; Array type
;;;

(defparameter +array-type-regex+
  "^([^\\*]+)(\\*+)$")

(defun array-type-p (object)
  (when (symbolp object)
    (let ((package (symbol-package object))
          (object-string (symbol-name object)))
      (cl-ppcre:register-groups-bind (base-string nil)
          (+array-type-regex+ object-string)
        (let ((base (intern (string base-string) package)))
          (chorus-type-p base))))))

(defun array-type-base (type)
  (unless (array-type-p type)
    (error "The value ~S is an invalid type." type))
  ;; The pointer symbol may live in the user's package. Resolve the base
  ;; there so a registered structure is the same symbol the kernel names.
  (let ((type-string (symbol-name type))
        (package (symbol-package type)))
    (cl-ppcre:register-groups-bind (base-string nil)
        (+array-type-regex+ type-string)
      (let ((base (intern (string base-string) package)))
        (if (chorus-type-p base)
            base
            (intern (string base-string) 'chorus/lang/type))))))

(defun array-type-stars (type)
  (unless (array-type-p type)
    (error "The value ~S is an invalid type." type))
  (let ((type-string (symbol-name type)))
    (cl-ppcre:register-groups-bind (_ stars-string)
        (+array-type-regex+ type-string)
      (declare (ignore _))
      (intern (string stars-string) 'chorus/lang/type))))

(defun array-type-dimension (type)
  (length (princ-to-string (array-type-stars type))))

(defun array-cffi-type (type)
  (unless (array-type-p type)
    (error "The value ~S is an invalid type." type))
  'cu-device-ptr)

(defun array-cffi-type-size (type)
  (cffi:foreign-type-size (array-cffi-type type)))

(defun array-cuda-type (type)
  (let ((base (array-type-base type))
        (stars (array-type-stars type)))
    (format nil "~A~A" (cuda-type base) stars)))

(defun array-type (type dimension)
  (unless (and (chorus-type-p type)
               (not (array-type-p type)))
    (error "The value ~S is an invalid type." type))
  (let ((stars (loop repeat dimension collect #\*)))
    (format-symbol 'chorus/lang/type "~A~{~A~}" type stars)))
