/**
   This file is a part of the Chorus project.
   Copyright (c) 2013 Masayuki Takagi (kamonama@gmail.com)
   Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)
 */

#ifndef CHORUS_FLOAT_H_
#define CHORUS_FLOAT_H_

__device__ float float_negate ( float x )
{
  return - x;
}

__device__  float float_recip ( float x )
{
  return 1.0 / x;
}

#endif // CHORUS_FLOAT_H_
