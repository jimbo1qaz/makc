#include <math.h>

#define MENGER3D_ORDER 5

bool hitTestMenger3D (double x, double y, double z) {
	// Menger sponge by Daniel White:
	// http://www.fractalforums.com/3d-fractal-generation/revenge-of-the-half-eaten-menger-sponge/
	x += 0.5;
	y += 0.5;
	z += 0.5;

	if ((x<0)||(x>1)||(y<0)||(y>1)||(z<0)||(z>1)) return false;
	double p = 3;
	for (int m = 1; m < MENGER3D_ORDER; m++) {
		double xa = fmod (x*p, 3);
		double ya = fmod (y*p, 3);
		double za = fmod (z*p, 3);
		if (/* any two coordinates */
			((xa > 1.0) && (xa < 2.0)   &&   (ya > 1.0) && (ya < 2.0)) ||
			((ya > 1.0) && (ya < 2.0)   &&   (za > 1.0) && (za < 2.0)) ||
			((xa > 1.0) && (xa < 2.0)   &&   (za > 1.0) && (za < 2.0))
			) return false;
		p *= 3;
	}
	return true;
}

double appDistMenger3D (double x, double y, double z) {
	x += 0.5;
	y += 0.5;
	z += 0.5;

	double d = -1;
	if (x < 0) if ((d < 0)||(-x < d)) d = -x;
	if (x > 1) if ((d < 0)||(x-1 < d)) d = x-1;
	if (y < 0) if ((d < 0)||(-y < d)) d = -y;
	if (y > 1) if ((d < 0)||(y-1 < d)) d = y-1;
	if (z < 0) if ((d < 0)||(-z < d)) d = -z;
	if (z > 1) if ((d < 0)||(z-1 < d)) d = z-1;
	if (d > 0) return d;

	double p = 3;
	for (int m = 1; m < MENGER3D_ORDER; m++) {
		double xa = fmod (x*p, 3);
		double ya = fmod (y*p, 3);
		double za = fmod (z*p, 3);
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
		if (d > 0) return d / p;
		p *= 3;
	}
	return 0;
}
