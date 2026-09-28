/**
   This file is a part of the Chorus project.
   Copyright (c) 2013 Masayuki Takagi (kamonama@gmail.com)
   Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
 */

#ifndef CHORUS_DOUBLE_H_
#define CHORUS_DOUBLE_H_

__device__ double double_negate ( double x )
{
  return - x;
}

__device__  double double_recip ( double x )
{
  return (double)1.0 / x;
}

#endif // CHORUS_DOUBLE_H_
