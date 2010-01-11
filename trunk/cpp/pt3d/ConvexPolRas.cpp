/////////////////////////////////////////////////////////////////////////////////////////////////////
//
//	FileName:	ConvexPolRas.cpp
//	Author	:	Michael Y. Polyakov
//	email	:	myp@andrew.cmu.edu	or  mikepolyakov@hotmail.com
//	Website	:	www.angelfire.com/linux/myp
//	Date	:	7/29/2002
//
//	Rasterizes a convex polygon. x/y - arrays of vertices of size num.
//	drawPoint - function which draws a point at (x,y). Should be provided before hand.
//	Shceck out the tutorial on my website.
//////////////////////////////////////////////////////////////////////////////////////////////////////

#include "ConvexPolRas.h"

#include <limits.h>	//for INT_MIN and INT_MAX

//used to save begginning and end x values of each horizontal line
struct ScanLine {
	int small_x, large_x;
};


void mpConvexPolRas(int *x, int *y, int num, mpDRAWPOINT drawPoint)
{
	int small_y = y[0], large_y = y[0];	//small and large y's
	int xc, yc;							//current x/y points
	ScanLine *sl;						//array of structs - contain small/large x for each y that is drawn
	int delta_y;						//large_y - small_y + 1 (size of the above array)
	int i, j, ind;
	//line information (see LineRas.cpp for details)
	int dx, dy, shortD, longD;
	int incXH, incXL, incYH, incYL;
	int d, incDL, incDH;

	/* Step 1: find small and large y's of all the vertices */
	for(i=1; i < num; i++) {
		if(y[i] < small_y) small_y = y[i];
		else if(y[i] > large_y) large_y = y[i];
	}
	
	/* Step 2: array that contains small_x and large_x values for each y. */
	delta_y = large_y - small_y + 1;	
	sl = new ScanLine[delta_y];			//allocate enough memory to save all y values, including large/small
	
	for(i=0; i < delta_y; i++) {		//initialize the ScanLine array
		sl[i].small_x = INT_MAX;		//INT_MAX because all initial values are less
		sl[i].large_x = INT_MIN;		//INT_MIN because all initial values are greater
	}
	

	/* Step 3: go through all the lines in this polygon and build min/max x array. */
	for(i=0; i < num; i++) {
		ind = (i+1)%num;				//last line will link last vertex with the first (index num-1 to 0)
		if(y[ind]-y[i]) 
		{
			//initializing current line data (see tutorial on line rasterization for details)
			dx = x[ind] - x[i]; dy = y[ind] - y[i];
			if(dx >= 0) incXH = incXL = 1; else { dx = -dx; incXH = incXL = -1; }
			if(dy >= 0) incYH = incYL = 1; else { dy = -dy; incYH = incYL = -1; }
			if(dx >= dy) { longD = dx;  shortD = dy;  incYL = 0; }
			else		 { longD = dy;  shortD = dx;  incXL = 0; }
			d = 2*shortD - longD;
			incDL = 2*shortD;
			incDH = 2*shortD - 2*longD;
			
			xc = x[i]; yc = y[i];		//initial current x/y values
			for(j=0; j <= longD; j++) {	//step through the current line and remember min/max values at each y
				ind = yc - small_y;
				if(xc < sl[ind].small_x) sl[ind].small_x = xc;	//initial contains INT_MAX so any value is less
				if(xc > sl[ind].large_x) sl[ind].large_x = xc;	//initial contains INT_MIN so any value is greater
				//finding next point on the line ...
				if(d >= 0)	{ xc += incXH; yc += incYH; d += incDH; }	//H-type
				else		{ xc += incXL; yc += incYL; d += incDL; }	//L-type
			}
		} //end if
	} //end i for loop

	/* Step 4: drawing horizontal line for each y from small_x to large_x including. */
	for(i=0; i < delta_y; i++)
		for(j=sl[i].small_x; j <= sl[i].large_x; j++)
			drawPoint(j, i+small_y);

	delete [] sl;	//previously allocated space for ScanLine array
}

