#|
  This file is a part of the Chorus project.
  Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
|#

(in-package :chorus/driver-api)

;;;
;;; Types
;;;

;; Opaque handles from cuda.h. CUmemAllocationProp, CUmemAccessDesc,
;; CUmemPoolProps, and the other descriptor structs are passed as :pointer.
;; CUtexObject, CUsurfObject, and CUmemGenericAllocationHandle are
;; unsigned long long, not pointers.
(cffi:defctype cu-array :pointer)
(cffi:defctype cu-link-state :pointer)
(cffi:defctype cu-graph :pointer)
(cffi:defctype cu-graph-node :pointer)
(cffi:defctype cu-graph-exec :pointer)
(cffi:defctype cu-memory-pool :pointer)
(cffi:defctype cu-green-ctx :pointer)
(cffi:defctype cu-dev-resource-desc :pointer)
(cffi:defctype cu-external-memory :pointer)
(cffi:defctype cu-external-semaphore :pointer)
(cffi:defctype cu-tex-object :unsigned-long-long)
(cffi:defctype cu-surf-object :unsigned-long-long)
(cffi:defctype cu-mem-generic-allocation-handle :unsigned-long-long)

;;;
;;; Functions
;;;

;; cuda.h redirects cuFoo to cuFoo_v2, or to __CUDA_API_PTDS(cuFoo_v2) /
;; __CUDA_API_PTSZ(cuFoo_v2). Those PTD macros are the identity unless the
;; per-thread default stream is selected, so the bound symbol is the _v2
;; (or base) export, not a _ptds / _ptsz alias.

;;;
;;; Context and device
;;;

(defcufun (cu-device-primary-ctx-retain "cuDevicePrimaryCtxRetain") cu-result
  (pctx (:pointer cu-context))
  (dev cu-device))

(defcufun (cu-device-primary-ctx-release "cuDevicePrimaryCtxRelease_v2") cu-result
  (dev cu-device))

(defcufun (cu-device-primary-ctx-reset "cuDevicePrimaryCtxReset_v2") cu-result
  (dev cu-device))

(defcufun (cu-device-primary-ctx-set-flags "cuDevicePrimaryCtxSetFlags_v2") cu-result
  (dev cu-device)
  (flags :unsigned-int))

(defcufun (cu-device-primary-ctx-get-state "cuDevicePrimaryCtxGetState") cu-result
  (dev cu-device)
  (flags (:pointer :unsigned-int))
  (active (:pointer :int)))

(defcufun (cu-ctx-set-current "cuCtxSetCurrent") cu-result
  (ctx cu-context))

(defcufun (cu-ctx-get-current "cuCtxGetCurrent") cu-result
  (pctx (:pointer cu-context)))

(defcufun (cu-ctx-push-current "cuCtxPushCurrent_v2") cu-result
  (ctx cu-context))

(defcufun (cu-ctx-pop-current "cuCtxPopCurrent_v2") cu-result
  (pctx (:pointer cu-context)))

(defcufun (cu-ctx-get-device "cuCtxGetDevice") cu-result
  (device (:pointer cu-device)))

(defcufun (cu-ctx-get-api-version "cuCtxGetApiVersion") cu-result
  (ctx cu-context)
  (version (:pointer :unsigned-int)))

(defcufun (cu-device-can-access-peer "cuDeviceCanAccessPeer") cu-result
  (can-access-peer (:pointer :int))
  (dev cu-device)
  (peer-dev cu-device))

(defcufun (cu-ctx-enable-peer-access "cuCtxEnablePeerAccess") cu-result
  (peer-context cu-context)
  (flags :unsigned-int))

(defcufun (cu-ctx-disable-peer-access "cuCtxDisablePeerAccess") cu-result
  (peer-context cu-context))

;; #define cuDeviceGetUuid cuDeviceGetUuid_v2. The argument is CUuuid *.
(defcufun (cu-device-get-uuid "cuDeviceGetUuid_v2") cu-result
  (uuid :pointer)
  (dev cu-device))

;;;
;;; Memory
;;;

(defcufun (cu-mem-alloc-host "cuMemAllocHost_v2") cu-result
  (pp (:pointer :pointer))
  (bytesize size-t))

(defcufun (cu-mem-free-host "cuMemFreeHost") cu-result
  (p :pointer))

(defcufun (cu-mem-alloc-managed "cuMemAllocManaged") cu-result
  (dptr (:pointer cu-device-ptr))
  (bytesize size-t)
  (flags :unsigned-int))

(defcufun (cu-mem-alloc-pitch "cuMemAllocPitch_v2") cu-result
  (dptr (:pointer cu-device-ptr))
  (pitch (:pointer size-t))
  (width-in-bytes size-t)
  (height size-t)
  (element-size-bytes :unsigned-int))

(defcufun (cu-memcpy-device-to-device "cuMemcpyDtoD_v2") cu-result
  (dst-device cu-device-ptr)
  (src-device cu-device-ptr)
  (byte-count size-t))

(defcufun (cu-memcpy-device-to-device-async "cuMemcpyDtoDAsync_v2") cu-result
  (dst-device cu-device-ptr)
  (src-device cu-device-ptr)
  (byte-count size-t)
  (hstream cu-stream))

(defcufun (cu-memcpy-peer "cuMemcpyPeer") cu-result
  (dst-device cu-device-ptr)
  (dst-context cu-context)
  (src-device cu-device-ptr)
  (src-context cu-context)
  (byte-count size-t))

(defcufun (cu-memcpy-peer-async "cuMemcpyPeerAsync") cu-result
  (dst-device cu-device-ptr)
  (dst-context cu-context)
  (src-device cu-device-ptr)
  (src-context cu-context)
  (byte-count size-t)
  (hstream cu-stream))

(defcufun (cu-memset-d8 "cuMemsetD8_v2") cu-result
  (dst-device cu-device-ptr)
  (uc :unsigned-char)
  (n size-t))

(defcufun (cu-memset-d16 "cuMemsetD16_v2") cu-result
  (dst-device cu-device-ptr)
  (us :unsigned-short)
  (n size-t))

(defcufun (cu-memset-d32 "cuMemsetD32_v2") cu-result
  (dst-device cu-device-ptr)
  (ui :unsigned-int)
  (n size-t))

(defcufun (cu-memset-d8-async "cuMemsetD8Async") cu-result
  (dst-device cu-device-ptr)
  (uc :unsigned-char)
  (n size-t)
  (hstream cu-stream))

(defcufun (cu-memset-d32-async "cuMemsetD32Async") cu-result
  (dst-device cu-device-ptr)
  (ui :unsigned-int)
  (n size-t)
  (hstream cu-stream))

(defcufun (cu-mem-alloc-async "cuMemAllocAsync") cu-result
  (dptr (:pointer cu-device-ptr))
  (bytesize size-t)
  (hstream cu-stream))

(defcufun (cu-mem-free-async "cuMemFreeAsync") cu-result
  (dptr cu-device-ptr)
  (hstream cu-stream))

(defcufun (cu-device-get-default-mem-pool "cuDeviceGetDefaultMemPool") cu-result
  (pool-out (:pointer cu-memory-pool))
  (dev cu-device))

(defcufun (cu-mem-alloc-from-pool-async "cuMemAllocFromPoolAsync") cu-result
  (dptr (:pointer cu-device-ptr))
  (bytesize size-t)
  (pool cu-memory-pool)
  (hstream cu-stream))

;; pool-props is CUmemPoolProps *.
(defcufun (cu-mem-pool-create "cuMemPoolCreate") cu-result
  (pool (:pointer cu-memory-pool))
  (pool-props :pointer))

(defcufun (cu-mem-pool-destroy "cuMemPoolDestroy") cu-result
  (pool cu-memory-pool))

(defcufun (cu-mem-address-reserve "cuMemAddressReserve") cu-result
  (ptr (:pointer cu-device-ptr))
  (size size-t)
  (alignment size-t)
  (addr cu-device-ptr)
  (flags :unsigned-long-long))

(defcufun (cu-mem-address-free "cuMemAddressFree") cu-result
  (ptr cu-device-ptr)
  (size size-t))

;; prop is CUmemAllocationProp *.
(defcufun (cu-mem-create "cuMemCreate") cu-result
  (handle (:pointer cu-mem-generic-allocation-handle))
  (size size-t)
  (prop :pointer)
  (flags :unsigned-long-long))

(defcufun (cu-mem-release "cuMemRelease") cu-result
  (handle cu-mem-generic-allocation-handle))

(defcufun (cu-mem-map "cuMemMap") cu-result
  (ptr cu-device-ptr)
  (size size-t)
  (offset size-t)
  (handle cu-mem-generic-allocation-handle)
  (flags :unsigned-long-long))

(defcufun (cu-mem-unmap "cuMemUnmap") cu-result
  (ptr cu-device-ptr)
  (size size-t))

;; desc is CUmemAccessDesc *.
(defcufun (cu-mem-set-access "cuMemSetAccess") cu-result
  (ptr cu-device-ptr)
  (size size-t)
  (desc :pointer)
  (count size-t))

;; prop is CUmemAllocationProp *. option is CUmemAllocationGranularity_flags.
(defcufun (cu-mem-get-allocation-granularity "cuMemGetAllocationGranularity") cu-result
  (granularity (:pointer size-t))
  (prop :pointer)
  (option :int))

;;;
;;; 2D and 3D copies. The parameter block is CUDA_MEMCPY2D / CUDA_MEMCPY3D.
;;;

(cffi:defcstruct cuda-memcpy-2d
  (src-x-in-bytes size-t)
  (src-y size-t)
  (src-memory-type :unsigned-int)
  (src-host :pointer)
  (src-device cu-device-ptr)
  (src-array cu-array)
  (src-pitch size-t)
  (dst-x-in-bytes size-t)
  (dst-y size-t)
  (dst-memory-type :unsigned-int)
  (dst-host :pointer)
  (dst-device cu-device-ptr)
  (dst-array cu-array)
  (dst-pitch size-t)
  (width-in-bytes size-t)
  (height size-t))

(defconstant cu-memory-type-host 1)
(defconstant cu-memory-type-device 2)
(defconstant cu-memory-type-array 3)
(defconstant cu-memory-type-unified 4)

(defcufun (cu-memcpy-2d "cuMemcpy2D_v2") cu-result
  (copy :pointer))

(defcufun (cu-memcpy-3d "cuMemcpy3D_v2") cu-result
  (copy :pointer))

(defcufun (cu-memcpy-2d-async "cuMemcpy2DAsync_v2") cu-result
  (copy :pointer)
  (hstream cu-stream))

(defcufun (cu-memcpy-3d-async "cuMemcpy3DAsync_v2") cu-result
  (copy :pointer)
  (hstream cu-stream))

(defun %zero-foreign (ptr type)
  (dotimes (i (cffi:foreign-type-size type))
    (setf (cffi:mem-aref ptr :unsigned-char i) 0)))

(defun memcpy-2d-device (dst dst-pitch src src-pitch width-in-bytes height)
  (cffi:with-foreign-object (copy '(:struct cuda-memcpy-2d))
    (%zero-foreign copy '(:struct cuda-memcpy-2d))
    (setf (cffi:foreign-slot-value copy '(:struct cuda-memcpy-2d)
                                   'src-memory-type)
          cu-memory-type-device
          (cffi:foreign-slot-value copy '(:struct cuda-memcpy-2d) 'src-device)
          src
          (cffi:foreign-slot-value copy '(:struct cuda-memcpy-2d) 'src-pitch)
          src-pitch
          (cffi:foreign-slot-value copy '(:struct cuda-memcpy-2d)
                                   'dst-memory-type)
          cu-memory-type-device
          (cffi:foreign-slot-value copy '(:struct cuda-memcpy-2d) 'dst-device)
          dst
          (cffi:foreign-slot-value copy '(:struct cuda-memcpy-2d) 'dst-pitch)
          dst-pitch
          (cffi:foreign-slot-value copy '(:struct cuda-memcpy-2d)
                                   'width-in-bytes)
          width-in-bytes
          (cffi:foreign-slot-value copy '(:struct cuda-memcpy-2d) 'height)
          height)
    (cu-memcpy-2d copy)))

;;;
;;; Modules and link
;;;

(defcufun (cu-module-load-data "cuModuleLoadData") cu-result
  (module (:pointer cu-module))
  (image :pointer))

(defcufun (cu-module-load-data-ex "cuModuleLoadDataEx") cu-result
  (module (:pointer cu-module))
  (image :pointer)
  (num-options :unsigned-int)
  (options :pointer)
  (option-values :pointer))

(defcufun (cu-link-create "cuLinkCreate_v2") cu-result
  (num-options :unsigned-int)
  (options :pointer)
  (option-values :pointer)
  (state-out (:pointer cu-link-state)))

(defcufun (cu-link-add-data "cuLinkAddData_v2") cu-result
  (state cu-link-state)
  (input-type :int)
  (data :pointer)
  (size size-t)
  (name :string)
  (num-options :unsigned-int)
  (options :pointer)
  (option-values :pointer))

(defcufun (cu-link-add-file "cuLinkAddFile_v2") cu-result
  (state cu-link-state)
  (input-type :int)
  (path :string)
  (num-options :unsigned-int)
  (options :pointer)
  (option-values :pointer))

(defcufun (cu-link-complete "cuLinkComplete") cu-result
  (state cu-link-state)
  (cubin-out (:pointer :pointer))
  (size-out (:pointer size-t)))

(defcufun (cu-link-destroy "cuLinkDestroy") cu-result
  (state cu-link-state))

;;;
;;; Launch and occupancy
;;;

(defcufun (cu-launch-kernel-ex "cuLaunchKernelEx") cu-result
  (config :pointer)
  (f cu-function)
  (kernel-params :pointer)
  (extra :pointer))

(defcufun (cu-occupancy-max-active-blocks-per-multiprocessor "cuOccupancyMaxActiveBlocksPerMultiprocessor") cu-result
  (num-blocks (:pointer :int))
  (func cu-function)
  (block-size :int)
  (dynamic-smem-size size-t))

;; block-size-to-dynamic-smem-size is the CUoccupancyB2DSize callback.
(defcufun (cu-occupancy-max-potential-block-size "cuOccupancyMaxPotentialBlockSize") cu-result
  (min-grid-size (:pointer :int))
  (block-size (:pointer :int))
  (func cu-function)
  (block-size-to-dynamic-smem-size :pointer)
  (dynamic-smem-size size-t)
  (block-size-limit :int))

(defcufun (cu-occupancy-available-dynamic-smem-per-block "cuOccupancyAvailableDynamicSMemPerBlock") cu-result
  (dynamic-smem-size (:pointer size-t))
  (func cu-function)
  (num-blocks :int)
  (block-size :int))

(defcufun (cu-func-set-attribute "cuFuncSetAttribute") cu-result
  (hfunc cu-function)
  (attrib :int)
  (value :int))

(defcufun (cu-func-get-attribute "cuFuncGetAttribute") cu-result
  (value (:pointer :int))
  (attrib :int)
  (hfunc cu-function))

(defcufun (cu-func-set-cache-config "cuFuncSetCacheConfig") cu-result
  (hfunc cu-function)
  (config :int))

;;;
;;; Graphs
;;;

(defcufun (cu-graph-create "cuGraphCreate") cu-result
  (ph-graph (:pointer cu-graph))
  (flags :unsigned-int))

(defcufun (cu-graph-destroy "cuGraphDestroy") cu-result
  (h-graph cu-graph))

(defcufun (cu-graph-add-kernel-node "cuGraphAddKernelNode_v2") cu-result
  (ph-graph-node (:pointer cu-graph-node))
  (h-graph cu-graph)
  (dependencies (:pointer cu-graph-node))
  (num-dependencies size-t)
  (node-params :pointer))

(defcufun (cu-graph-add-memcpy-node "cuGraphAddMemcpyNode") cu-result
  (ph-graph-node (:pointer cu-graph-node))
  (h-graph cu-graph)
  (dependencies (:pointer cu-graph-node))
  (num-dependencies size-t)
  (copy-params :pointer)
  (ctx cu-context))

(defcufun (cu-graph-add-memset-node "cuGraphAddMemsetNode") cu-result
  (ph-graph-node (:pointer cu-graph-node))
  (h-graph cu-graph)
  (dependencies (:pointer cu-graph-node))
  (num-dependencies size-t)
  (memset-params :pointer)
  (ctx cu-context))

;; #define cuGraphInstantiate cuGraphInstantiateWithFlags.
;; The legacy export takes an error node and a log buffer; this is the flags form.
(defcufun (cu-graph-instantiate "cuGraphInstantiateWithFlags") cu-result
  (ph-graph-exec (:pointer cu-graph-exec))
  (h-graph cu-graph)
  (flags :unsigned-long-long))

(defcufun (cu-graph-launch "cuGraphLaunch") cu-result
  (h-graph-exec cu-graph-exec)
  (hstream cu-stream))

(defcufun (cu-graph-exec-destroy "cuGraphExecDestroy") cu-result
  (h-graph-exec cu-graph-exec))

(defcufun (cu-stream-begin-capture "cuStreamBeginCapture_v2") cu-result
  (hstream cu-stream)
  (mode :int))

(defcufun (cu-stream-end-capture "cuStreamEndCapture") cu-result
  (hstream cu-stream)
  (ph-graph (:pointer cu-graph)))

(defcufun (cu-stream-is-capturing "cuStreamIsCapturing") cu-result
  (hstream cu-stream)
  (capture-status (:pointer :int)))

;;;
;;; Green contexts
;;;

;; CUdevResourceDesc is typedef struct CUdevResourceDesc_st *, an opaque
;; pointer, not a struct passed by value.
(defcufun (cu-green-ctx-create "cuGreenCtxCreate") cu-result
  (ph-ctx (:pointer cu-green-ctx))
  (desc cu-dev-resource-desc)
  (dev cu-device)
  (flags :unsigned-int))

(defcufun (cu-green-ctx-destroy "cuGreenCtxDestroy") cu-result
  (h-ctx cu-green-ctx))

(defcufun (cu-ctx-from-green-ctx "cuCtxFromGreenCtx") cu-result
  (p-context (:pointer cu-context))
  (h-ctx cu-green-ctx))

;;;
;;; Checkpoint
;;;

(defcufun (cu-checkpoint-process-lock "cuCheckpointProcessLock") cu-result
  (pid :int)
  (args :pointer))

(defcufun (cu-checkpoint-process-unlock "cuCheckpointProcessUnlock") cu-result
  (pid :int)
  (args :pointer))

(defcufun (cu-checkpoint-process-checkpoint "cuCheckpointProcessCheckpoint") cu-result
  (pid :int)
  (args :pointer))

(defcufun (cu-checkpoint-process-restore "cuCheckpointProcessRestore") cu-result
  (pid :int)
  (args :pointer))

(defcufun (cu-checkpoint-process-get-state "cuCheckpointProcessGetState") cu-result
  (pid :int)
  (state (:pointer :int)))

;;;
;;; Textures and arrays
;;;

(defcufun (cu-array-create "cuArrayCreate_v2") cu-result
  (p-handle (:pointer cu-array))
  (allocate-array :pointer))

(defcufun (cu-array-3d-create "cuArray3DCreate_v2") cu-result
  (p-handle (:pointer cu-array))
  (allocate-array :pointer))

(defcufun (cu-array-destroy "cuArrayDestroy") cu-result
  (h-array cu-array))

(defcufun (cu-tex-object-create "cuTexObjectCreate") cu-result
  (p-tex-object (:pointer cu-tex-object))
  (res-desc :pointer)
  (tex-desc :pointer)
  (res-view-desc :pointer))

(defcufun (cu-tex-object-destroy "cuTexObjectDestroy") cu-result
  (tex-object cu-tex-object))

(defcufun (cu-tex-object-get-resource-desc "cuTexObjectGetResourceDesc") cu-result
  (res-desc :pointer)
  (tex-object cu-tex-object))

(defcufun (cu-surf-object-create "cuSurfObjectCreate") cu-result
  (p-surf-object (:pointer cu-surf-object))
  (res-desc :pointer))

(defcufun (cu-surf-object-destroy "cuSurfObjectDestroy") cu-result
  (surf-object cu-surf-object))

;;;
;;; External memory and semaphores
;;;

(defcufun (cu-import-external-memory "cuImportExternalMemory") cu-result
  (ext-mem-out (:pointer cu-external-memory))
  (mem-handle-desc :pointer))

(defcufun (cu-external-memory-get-mapped-buffer "cuExternalMemoryGetMappedBuffer") cu-result
  (dev-ptr (:pointer cu-device-ptr))
  (ext-mem cu-external-memory)
  (buffer-desc :pointer))

(defcufun (cu-destroy-external-memory "cuDestroyExternalMemory") cu-result
  (ext-mem cu-external-memory))

(defcufun (cu-import-external-semaphore "cuImportExternalSemaphore") cu-result
  (ext-sem-out (:pointer cu-external-semaphore))
  (sem-handle-desc :pointer))

(defcufun (cu-signal-external-semaphores-async "cuSignalExternalSemaphoresAsync") cu-result
  (ext-sem-array (:pointer cu-external-semaphore))
  (params-array :pointer)
  (num-ext-sems :unsigned-int)
  (stream cu-stream))

(defcufun (cu-wait-external-semaphores-async "cuWaitExternalSemaphoresAsync") cu-result
  (ext-sem-array (:pointer cu-external-semaphore))
  (params-array :pointer)
  (num-ext-sems :unsigned-int)
  (stream cu-stream))

(defcufun (cu-destroy-external-semaphore "cuDestroyExternalSemaphore") cu-result
  (ext-sem cu-external-semaphore))

;;;
;;; Tensor maps
;;;

;; CUtensorMap is caller-allocated; the argument is CUtensorMap *.
(defcufun (cu-tensor-map-encode-tiled "cuTensorMapEncodeTiled") cu-result
  (tensor-map :pointer)
  (tensor-data-type :int)
  (tensor-rank :unsigned-int)
  (global-address :pointer)
  (global-dim :pointer)
  (global-strides :pointer)
  (box-dim :pointer)
  (element-strides :pointer)
  (interleave :int)
  (swizzle :int)
  (l2-promotion :int)
  (oob-fill :int))

(defcufun (cu-tensor-map-encode-im2col "cuTensorMapEncodeIm2col") cu-result
  (tensor-map :pointer)
  (tensor-data-type :int)
  (tensor-rank :unsigned-int)
  (global-address :pointer)
  (global-dim :pointer)
  (global-strides :pointer)
  (pixel-box-lower-corner :pointer)
  (pixel-box-upper-corner :pointer)
  (channels-per-pixel :unsigned-int)
  (pixels-per-column :unsigned-int)
  (element-strides :pointer)
  (interleave :int)
  (swizzle :int)
  (l2-promotion :int)
  (oob-fill :int))

;;;
;;; D3D11
;;;

;; IDXGIAdapter * and ID3D11Resource * are :pointer.
(defcufun (cu-d3d11-get-device "cuD3D11GetDevice") cu-result
  (p-cuda-device (:pointer cu-device))
  (p-adapter :pointer))

(defcufun (cu-graphics-d3d11-register-resource "cuGraphicsD3D11RegisterResource") cu-result
  (p-cuda-resource (:pointer cu-graphics-resource))
  (p-d3d-resource :pointer)
  (flags :unsigned-int))

;;;
;;; EXPORTS:
;;; cu-device-primary-ctx-retain
;;; cu-device-primary-ctx-release
;;; cu-device-primary-ctx-reset
;;; cu-device-primary-ctx-set-flags
;;; cu-device-primary-ctx-get-state
;;; cu-ctx-set-current
;;; cu-ctx-get-current
;;; cu-ctx-push-current
;;; cu-ctx-pop-current
;;; cu-ctx-get-device
;;; cu-ctx-get-api-version
;;; cu-device-can-access-peer
;;; cu-ctx-enable-peer-access
;;; cu-ctx-disable-peer-access
;;; cu-device-get-uuid
;;; cu-mem-alloc-host
;;; cu-mem-free-host
;;; cu-mem-alloc-managed
;;; cu-mem-alloc-pitch
;;; cu-memcpy-device-to-device
;;; cu-memcpy-device-to-device-async
;;; cu-memcpy-peer
;;; cu-memcpy-peer-async
;;; cu-memset-d8
;;; cu-memset-d16
;;; cu-memset-d32
;;; cu-memset-d8-async
;;; cu-memset-d32-async
;;; cu-mem-alloc-async
;;; cu-mem-free-async
;;; cu-device-get-default-mem-pool
;;; cu-mem-alloc-from-pool-async
;;; cu-mem-pool-create
;;; cu-mem-pool-destroy
;;; cu-mem-address-reserve
;;; cu-mem-address-free
;;; cu-mem-create
;;; cu-mem-release
;;; cu-mem-map
;;; cu-mem-unmap
;;; cu-mem-set-access
;;; cu-mem-get-allocation-granularity
;;; cu-module-load-data
;;; cu-module-load-data-ex
;;; cu-link-create
;;; cu-link-add-data
;;; cu-link-add-file
;;; cu-link-complete
;;; cu-link-destroy
;;; cu-launch-kernel-ex
;;; cu-occupancy-max-active-blocks-per-multiprocessor
;;; cu-occupancy-max-potential-block-size
;;; cu-occupancy-available-dynamic-smem-per-block
;;; cu-func-set-attribute
;;; cu-func-get-attribute
;;; cu-func-set-cache-config
;;; cu-graph-create
;;; cu-graph-destroy
;;; cu-graph-add-kernel-node
;;; cu-graph-add-memcpy-node
;;; cu-graph-add-memset-node
;;; cu-graph-instantiate
;;; cu-graph-launch
;;; cu-graph-exec-destroy
;;; cu-stream-begin-capture
;;; cu-stream-end-capture
;;; cu-stream-is-capturing
;;; cu-green-ctx-create
;;; cu-green-ctx-destroy
;;; cu-ctx-from-green-ctx
;;; cu-checkpoint-process-lock
;;; cu-checkpoint-process-unlock
;;; cu-checkpoint-process-checkpoint
;;; cu-checkpoint-process-restore
;;; cu-checkpoint-process-get-state
;;; cu-array-create
;;; cu-array-3d-create
;;; cu-array-destroy
;;; cu-tex-object-create
;;; cu-tex-object-destroy
;;; cu-tex-object-get-resource-desc
;;; cu-surf-object-create
;;; cu-surf-object-destroy
;;; cu-import-external-memory
;;; cu-external-memory-get-mapped-buffer
;;; cu-destroy-external-memory
;;; cu-import-external-semaphore
;;; cu-signal-external-semaphores-async
;;; cu-wait-external-semaphores-async
;;; cu-destroy-external-semaphore
;;; cu-tensor-map-encode-tiled
;;; cu-tensor-map-encode-im2col
;;; cu-d3d11-get-device
;;; cu-graphics-d3d11-register-resource
;;; MISSING:
;;; cu-dev-resource-create — cuda.h has no cuDevResourceCreate. A green context is created with cuGreenCtxCreate; the descriptor comes from cuDevResourceGenerateDesc.

(export '(cu-array cu-link-state cu-graph cu-graph-node cu-graph-exec cu-memory-pool cu-green-ctx cu-dev-resource-desc cu-external-memory cu-external-semaphore cu-tex-object cu-surf-object cu-mem-generic-allocation-handle cu-memory-type-host cu-memory-type-device cu-memory-type-array cu-memory-type-unified cu-device-primary-ctx-retain cu-device-primary-ctx-release cu-device-primary-ctx-reset cu-device-primary-ctx-set-flags cu-device-primary-ctx-get-state cu-ctx-set-current cu-ctx-get-current cu-ctx-push-current cu-ctx-pop-current cu-ctx-get-device cu-ctx-get-api-version cu-device-can-access-peer cu-ctx-enable-peer-access cu-ctx-disable-peer-access cu-device-get-uuid cu-mem-alloc-host cu-mem-free-host cu-mem-alloc-managed cu-mem-alloc-pitch cu-memcpy-device-to-device cu-memcpy-device-to-device-async cu-memcpy-peer cu-memcpy-peer-async cu-memset-d8 cu-memset-d16 cu-memset-d32 cu-memset-d8-async cu-memset-d32-async cu-mem-alloc-async cu-mem-free-async cu-device-get-default-mem-pool cu-mem-alloc-from-pool-async cu-mem-pool-create cu-mem-pool-destroy cu-mem-address-reserve cu-mem-address-free cu-mem-create cu-mem-release cu-mem-map cu-mem-unmap cu-mem-set-access cu-mem-get-allocation-granularity cu-memcpy-2d cu-memcpy-3d cu-memcpy-2d-async cu-memcpy-3d-async cu-module-load-data cu-module-load-data-ex cu-link-create cu-link-add-data cu-link-add-file cu-link-complete cu-link-destroy cu-launch-kernel-ex cu-occupancy-max-active-blocks-per-multiprocessor cu-occupancy-max-potential-block-size cu-occupancy-available-dynamic-smem-per-block cu-func-set-attribute cu-func-get-attribute cu-func-set-cache-config cu-graph-create cu-graph-destroy cu-graph-add-kernel-node cu-graph-add-memcpy-node cu-graph-add-memset-node cu-graph-instantiate cu-graph-launch cu-graph-exec-destroy cu-stream-begin-capture cu-stream-end-capture cu-stream-is-capturing cu-green-ctx-create cu-green-ctx-destroy cu-ctx-from-green-ctx cu-checkpoint-process-lock cu-checkpoint-process-unlock cu-checkpoint-process-checkpoint cu-checkpoint-process-restore cu-checkpoint-process-get-state cu-array-create cu-array-3d-create cu-array-destroy cu-tex-object-create cu-tex-object-destroy cu-tex-object-get-resource-desc cu-surf-object-create cu-surf-object-destroy cu-import-external-memory cu-external-memory-get-mapped-buffer cu-destroy-external-memory cu-import-external-semaphore cu-signal-external-semaphores-async cu-wait-external-semaphores-async cu-destroy-external-semaphore cu-tensor-map-encode-tiled cu-tensor-map-encode-im2col cu-d3d11-get-device cu-graphics-d3d11-register-resource memcpy-2d-device))
