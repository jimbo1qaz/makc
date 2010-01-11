/////////////////////////////////////////////////////////////////////////////////////////////////////
//
//	FileName:	ConvexPolRas.h
//	Author	:	Michael Y. Polyakov
//	email	:	myp@andrew.cmu.edu	or  mikepolyakov@hotmail.com
//	Website	:	www.angelfire.com/linux/myp
//	Date	:	7/29/2002
//
//	Rasterizes a convex polygon.
//	See tutorial on website for details.
//////////////////////////////////////////////////////////////////////////////////////////////////////

#ifndef CONVEXPOLRAS_H_
#define CONVEXPOLRAS_H_

#ifndef MP_DRAWPOINT
#define MP_DRAWPOINT
//pointer to a function which will draw a point at position (x, y)
typedef void (*mpDRAWPOINT)(int x, int y);
#endif

void mpConvexPolRas(int *x, int *y, int num, mpDRAWPOINT drawPoint);

#endif

