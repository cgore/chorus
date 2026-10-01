/**
   This file is a part of the Chorus project.
   Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
 */

#ifndef CHORUS_CLUSTER_H_
#define CHORUS_CLUSTER_H_

/* Cluster indexes and the cluster barrier are device intrinsics. nvcc
   declares them in an internal header; pull that in so every kernel can
   name __clusterDim and the barrier. */
#if defined(__CUDACC__)
#ifndef __CUDA_INCLUDE_COMPILER_INTERNAL_HEADERS__
#define __CUDA_INCLUDE_COMPILER_INTERNAL_HEADERS__
#define CHORUS_UNDEF_CUDA_INTERNAL_HEADERS
#endif
#include <crt/sm_90_rt.h>
#ifdef CHORUS_UNDEF_CUDA_INTERNAL_HEADERS
#undef __CUDA_INCLUDE_COMPILER_INTERNAL_HEADERS__
#undef CHORUS_UNDEF_CUDA_INTERNAL_HEADERS
#endif
#endif

/* Thread-block cluster barrier. The intrinsics exist on compute capability
   9.0 and newer, which includes the Blackwell sm_120 target. */
__device__ __forceinline__ void chorus_cluster_barrier(void) {
#if defined(__CUDA_ARCH__) && (__CUDA_ARCH__ >= 900)
  __cluster_barrier_arrive();
  __cluster_barrier_wait();
#endif
}

#endif /* CHORUS_CLUSTER_H_ */
