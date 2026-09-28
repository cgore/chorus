/**
   This file is a part of the Chorus project.
   Copyright (c) 2013 Masayuki Takagi (kamonama@gmail.com)
   Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
 */

#ifndef CHORUS_INT_H_
#define CHORUS_INT_H_

__device__ int int_negate ( int x )
{
  return -x;
}

__device__ int int_recip ( int x )
{
  return 1 / x;
}

#endif // CHORUS_INT_H_
