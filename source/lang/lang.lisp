#|
  This file is a part of the Chorus project.
  Copyright (c) 2012-2016 Masayuki Takagi (kamonama@gmail.com)
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
|#

(in-package :cl-user)
(eval-when (:compile-toplevel :load-toplevel :execute)
  (locally
      (declare #+sbcl
               (sb-ext:muffle-conditions sb-kernel::package-at-variance))
    (handler-bind
        (#+sbcl (sb-kernel::package-at-variance #'muffle-warning))
      (defpackage :chorus/lang
        (:use :cl
              :cl-reexport)))))

(in-package :chorus/lang)

;; reexport symbols of data structures chorus provides
(reexport-from :chorus/lang/data
               :include '(;; Float3
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
                          :int2 :make-int2 :int2-x :int2-y :int2-p :int2-=
                          :with-int2
                          :int4 :make-int4 :int4-x :int4-y :int4-z :int4-w
                          :int4-p :int4-= :with-int4
                          :uint2 :make-uint2 :uint2-x :uint2-y :uint2-p
                          :uint2-= :with-uint2
                          :uint4 :make-uint4 :uint4-x :uint4-y :uint4-z
                          :uint4-w :uint4-p :uint4-= :with-uint4
                          :half2 :make-half2 :half2-x :half2-y :half2-p
                          :half2-= :with-half2))

;; reexport symbols of chorus types
(reexport-from :chorus/lang/type
               :include '(:void
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
                          :float3*
                          :float4*
                          :double3*
                          :double4*
                          :curand-state-xorwow*
                          :int8 :uint8 :int16 :uint16 :uint :int64 :uint64
                          :size-t :half :bfloat16 :fp8 :fp4
                          :int2 :int4 :uint2 :uint4 :half2
                          :int8* :uint8* :int16* :uint16* :uint* :int64*
                          :uint64* :size-t* :half* :bfloat16* :fp8* :fp4*
                          :int2* :int4* :uint2* :uint4* :half2*
                          :cffi-type))

;; reexport symbols of chorus syntax except the ones exported
;; from COMMON-LISP package
(reexport-from :chorus/lang/syntax
               :include '(:grid-dim-x :grid-dim-y :grid-dim-z
                          :block-dim-x :block-dim-y :block-dim-z
                          :block-idx-x :block-idx-y :block-idx-z
                          :thread-idx-x :thread-idx-y :thread-idx-z
                          :with-shared-memory
                          :set
                          :cluster-dim-x :cluster-dim-y :cluster-dim-z
                          :cluster-idx-x :cluster-idx-y :cluster-idx-z
                          :block-in-cluster-x :block-in-cluster-y
                          :block-in-cluster-z
                          :while :for :continue :switch :printf :cuda-asm
                          :with-dynamic-shared-memory
                          :launch-bounds))

;; reexport symbols of chorus built-in functions except the ones
;; exported from COMMON-LISP package
(reexport-from :chorus/lang/built-in
               :include '(:xor
                          :shl
                          :shr
                          :rsqrt
                          :__exp
                          :__divide
                          :atomic-add
                          :pointer
                          :syncthreads
                          :double-to-int-rn
                          :dot
                          :curand-init-xorwow
                          :curand-uniform-float-xorwow
                          :curand-uniform-double-xorwow
                          :curand-normal-float-xorwow
                          :curand-normal-double-xorwow
                          :shfl-sync :shfl-up-sync :shfl-down-sync
                          :shfl-xor-sync
                          :ballot-sync :all-sync :any-sync :activemask
                          :match-any-sync :match-all-sync :syncwarp
                          :reduce-add-sync :reduce-min-sync :reduce-max-sync
                          :reduce-and-sync :reduce-or-sync :reduce-xor-sync
                          :atomic-cas :atomic-exch :atomic-min :atomic-max
                          :fma :erf :erfc :clz :popc :brev :ffs
                          :__sin :__cos :__log2 :__saturate
                          :float-to-half :half-to-float
                          :float-to-bfloat16 :bfloat16-to-float
                          :cluster-barrier :threadfence-cluster :cluster-rank
                          :uint :int8 :uint8 :int16 :uint16 :int64 :uint64
                          :size-t :half :bfloat16))
