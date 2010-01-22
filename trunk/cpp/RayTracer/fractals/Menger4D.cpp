#include <math.h>

#define MENGER4D_ORDER 8
#define MENGER4D_W(X,Y,Z) 1.5 +X -Y -Z

bool hitTestMenger4D (double x, double y, double z) {
	// 4D Menger sponge
	x += 0.5;
	y += 0.5;
	z += 0.5;

	double w = MENGER4D_W (x, y, z);

	if ((x<0)||(x>1)||(y<0)||(y>1)||(z<0)||(z>1)||(w<0)||(w>1)) return false;
	double p = 3;
	for (int m = 1; m < MENGER4D_ORDER; m++) {
		double xa = fmod (x*p, 3);
		double ya = fmod (y*p, 3);
		double za = fmod (z*p, 3);
		double wa = fmod (w*p, 3);
		if (/* any two coordinates */
			((xa > 1.0) && (xa < 2.0)   &&   (ya > 1.0) && (ya < 2.0)) ||
			((ya > 1.0) && (ya < 2.0)   &&   (za > 1.0) && (za < 2.0)) ||
			((xa > 1.0) && (xa < 2.0)   &&   (za > 1.0) && (za < 2.0)) ||
			((xa > 1.0) && (xa < 2.0)   &&   (wa > 1.0) && (wa < 2.0)) ||
			((ya > 1.0) && (ya < 2.0)   &&   (wa > 1.0) && (wa < 2.0)) ||
			((wa > 1.0) && (wa < 2.0)   &&   (za > 1.0) && (za < 2.0))
			) return false;
		p *= 3;
	}
	return true;
}

double appDistMenger4D (double x, double y, double z) {
	x += 0.5;
	y += 0.5;
	z += 0.5;

	double w = MENGER4D_W (x, y, z);

	double d = -1;
	if (x < 0) if ((d < 0)||(-x < d)) d = -x;
	if (x > 1) if ((d < 0)||(x-1 < d)) d = x-1;
	if (y < 0) if ((d < 0)||(-y < d)) d = -y;
	if (y > 1) if ((d < 0)||(y-1 < d)) d = y-1;
	if (z < 0) if ((d < 0)||(-z < d)) d = -z;
	if (z > 1) if ((d < 0)||(z-1 < d)) d = z-1;
	if (w < 0) if ((d < 0)||(-w < d)) d = -w;
	if (w > 1) if ((d < 0)||(w-1 < d)) d = w-1;
	if (d > 0) return d;

	double p = 3;
	for (int m = 1; m < MENGER4D_ORDER; m++) {
		double xa = fmod (x*p, 3);
		double ya = fmod (y*p, 3);
		double za = fmod (z*p, 3);
		double wa = fmod (w*p, 3);
		d = -1;
		if ((xa > 1.0) && (xa < 2.0)   &&   (ya > 1.0) && (ya < 2.0)) {
			if ((d < 0)||(xa-1 < d)) d = xa-1;
			if ((d < 0)||(2-xa < d)) d = 2-xa;
			if ((d < 0)||(ya-1 < d)) d = ya-1;
			if ((d < 0)||(2-ya < d)) d = 2-ya;
		}
		if ((za > 1.0) && (za < 2.0)   &&   (ya > 1.0) && (ya < 2.0)) {
			if ((d < 0)||(za-1 < d)) d = za-1;
			if ((d < 0)||(2-za < d)) d = 2-za;
			if ((d < 0)||(ya-1 < d)) d = ya-1;
			if ((d < 0)||(2-ya < d)) d = 2-ya;
		}
		if ((xa > 1.0) && (xa < 2.0)   &&   (za > 1.0) && (za < 2.0)) {
			if ((d < 0)||(xa-1 < d)) d = xa-1;
			if ((d < 0)||(2-xa < d)) d = 2-xa;
			if ((d < 0)||(za-1 < d)) d = za-1;
			if ((d < 0)||(2-za < d)) d = 2-za;
		}
		if ((xa > 1.0) && (xa < 2.0)   &&   (wa > 1.0) && (wa < 2.0)) {
			if ((d < 0)||(xa-1 < d)) d = xa-1;
			if ((d < 0)||(2-xa < d)) d = 2-xa;
			if ((d < 0)||(wa-1 < d)) d = wa-1;
			if ((d < 0)||(2-wa < d)) d = 2-wa;
		}
		if ((wa > 1.0) && (wa < 2.0)   &&   (ya > 1.0) && (ya < 2.0)) {
			if ((d < 0)||(wa-1 < d)) d = wa-1;
			if ((d < 0)||(2-wa < d)) d = 2-wa;
			if ((d < 0)||(ya-1 < d)) d = ya-1;
			if ((d < 0)||(2-ya < d)) d = 2-ya;
		}
		if ((wa > 1.0) && (wa < 2.0)   &&   (za > 1.0) && (za < 2.0)) {
			if ((d < 0)||(wa-1 < d)) d = wa-1;
			if ((d < 0)||(2-wa < d)) d = 2-wa;
			if ((d < 0)||(za-1 < d)) d = za-1;
			if ((d < 0)||(2-za < d)) d = 2-za;
		}
		if (d > 0) return d / p;
		p *= 3;
	}
	return 0;
}
