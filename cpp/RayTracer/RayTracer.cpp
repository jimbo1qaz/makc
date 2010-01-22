// RayTracer.cpp
// Hybrid of ambient occlusion and environment mapping

#include <atlbase.h> // CComBSTR (also helps gdiplus.h to compile :)
#include <gdiplus.h> // (add gdiplus.lib)

#include <conio.h>
#include <stdio.h>
#include <sys/stat.h>
#include <math.h>
#include <time.h>

#ifndef PI
#define PI 3.1415926535897932384626433832795
#endif

#include "fractals.h"

#define DITHERING true
#define FOV_ATAN 1.5 // 1 = 90 deg, infinity = 180 deg
#define S 666 // tracing SxS bitmap
#define N 7 // rays per ray per generation
#define TTL 2 // generations: rays per pixel should be < N^TTL
#define STEP 0.00002 // 0.0 < STEP << 1.0
#define PRECISION 0.000001 * 0.000001
#define RAYS_EFFICIENCY 0.2 /* expected share of rays that will reach the sky */

struct Pixel {
	unsigned char B;
	unsigned char G;
	unsigned char R;
	unsigned char A;
};

struct Ray {
	int generation;
	double magnitude, x, y, z, dx, dy, dz;
	static void Clear (Ray *r) {
		r->generation = 0; r->magnitude = 1; r->x = 0; r->y = 0; r->z = 0;
	}
	Ray::Ray () {
		Clear (this);
	}
};

bool FileExists(char *filename);
void showSysErrMsg (char *unknown);
#define STRIDE_3ALIGN4(W) (((3*((W)+1))>>2)*4)
void saveBitmap(unsigned char *pBuffer, char *pFileName);
unsigned char *loadBitmap (char *fname);
double random () { return double (rand ()) / RAND_MAX; }



int main(int argc, char* argv[])
{
	unsigned int t; time ((time_t *)&t); srand (t % RAND_MAX); random ();

	Gdiplus::GdiplusStartupInput gdiplusStartupInput; ULONG_PTR gdiplusToken;
	Gdiplus::GdiplusStartup(&gdiplusToken, &gdiplusStartupInput, NULL);

	// 1st load lightmap
	unsigned char *pLightmapBitmap = loadBitmap ("lightmap.jpg");
	if (pLightmapBitmap == NULL) {
		if (!FileExists ("lightmap.jpg"))
			puts ("lightmap not found :(");
		else
			showSysErrMsg ("random GDI failure :(");

		return 1;
	}

	unsigned char *lightmap = (pLightmapBitmap + (WORD)(((PBITMAPINFOHEADER)pLightmapBitmap)->biSize));
	int lmWidth = ((PBITMAPINFOHEADER) pLightmapBitmap)->biWidth;
	int lmHeight = ((PBITMAPINFOHEADER) pLightmapBitmap)->biHeight;
	int lmStride = STRIDE_3ALIGN4 (lmWidth);

	int SS = S * S;

	int iWidth  = S;
	int iHeight = S;
	int iStride = STRIDE_3ALIGN4 (iWidth);
	int iBufferLength = sizeof (BITMAPINFOHEADER) + iStride * iHeight;
	unsigned char *pCanvasBitmap = new unsigned char [iBufferLength]; ZeroMemory (pCanvasBitmap, iBufferLength);

	PBITMAPINFOHEADER pbih = (PBITMAPINFOHEADER) pCanvasBitmap; ZeroMemory (pbih, sizeof (BITMAPINFOHEADER));
	pbih->biBitCount = 24; pbih->biCompression = BI_RGB; pbih->biHeight = iHeight; pbih->biWidth = iWidth;
	pbih->biPlanes = 1; pbih->biSize = sizeof (BITMAPINFOHEADER); pbih->biSizeImage = iStride * pbih->biHeight;
	pbih->biXPelsPerMeter = pbih->biYPelsPerMeter = 0;

	unsigned char *canvas = (pCanvasBitmap + (WORD)(((PBITMAPINFOHEADER)pCanvasBitmap)->biSize));

	// init raytracer
	double red;
	double green;
	double blue;
	int i, j, k, m = 1, num = 1; for (i = 0; i < TTL; i++) { m *= N; num += m; }

	Ray *rays = new Ray [num];
	Ray *directions = new Ray [N];

	// uniformly distributed directions:
	// Bauer, Robert, "Distribution of Points on a Sphere with Application to Star Catalogs",
	// Journal of Guidance, Control, and Dynamics, January-February 2000, vol.23 no.1 (130-137).
	for (i = 1; i <= N; i++) {
		Ray &d = directions [i - 1];
		double phi = acos ( -1.0 + (2.0 * i -1.0) / N);
		double theta = sqrt (N * PI) * phi;
		d.dx = cos (theta) * sin (phi);
		d.dy = sin (theta) * sin (phi);
		d.dz = cos (phi);
	}

	// select random spot on unit sphere
	k = int (random () * N) % N;
	double camPosX = directions [k].dx;
	double camPosY = directions [k].dy;
	double camPosZ = directions [k].dz;

	// select random camera orientation
	k = int (random () * N) % N;
	double camFwdX = 0.3 * directions [k].dx - camPosX;
	double camFwdY = 0.3 * directions [k].dy - camPosY;
	double camFwdZ = 0.3 * directions [k].dz - camPosZ;
	double camFwdL = 1 / sqrt (camFwdX * camFwdX + camFwdY * camFwdY + camFwdZ * camFwdZ);
	camFwdX *= camFwdL; camFwdY *= camFwdL; camFwdZ *= camFwdL;
	// unless we are extremely unlucky, camFwdZ should be never 0
	double camUpX = 0;
	double camUpY = camFwdZ;
	double camUpZ = -camFwdY;
	double camUpL = 1 / sqrt (camUpX * camUpX + camUpY * camUpY + camUpZ * camUpZ);
	camUpX *= camUpL; camUpY *= camUpL; camUpZ *= camUpL;
	double camSideX = camFwdY * camUpZ - camUpY * camFwdZ;
	double camSideY = camFwdZ * camUpX - camUpZ * camFwdX;
	double camSideZ = camFwdX * camUpY - camUpX * camFwdY;

	// output C++ code to override orientation
	printf ("camPosX = %f;\n", camPosX);
	printf ("camPosY = %f;\n", camPosY);
	printf ("camPosZ = %f;\n", camPosZ);
	printf ("camFwdX = %f;\n", camFwdX);
	printf ("camFwdY = %f;\n", camFwdY);
	printf ("camFwdZ = %f;\n", camFwdZ);
	printf ("camUpX = %f;\n", camUpX);
	printf ("camUpY = %f;\n", camUpY);
	printf ("camUpZ = %f;\n", camUpZ);
	printf ("camSideX = %f;\n", camSideX);
	printf ("camSideY = %f;\n", camSideY);
	printf ("camSideZ = %f;\n", camSideZ);

	if (!false) {
		// to set specific orientation
camPosX = -0.498168;
camPosY = 0.334408;
camPosZ = 0.800000;
camFwdX = 0.454971;
camFwdY = -0.593262;
camFwdZ = -0.664109;
camUpX = 0.000000;
camUpY = -0.745766;
camUpZ = 0.666208;
camSideX = -0.890506;
camSideY = -0.303105;
camSideZ = -0.339302;
	}

	// stats for real RAYS_EFFICIENCY
	// (so that you can run small resolution test and fix it accordingly)
	int rre_r = 0, rre_n = 0;
	double ns = RAYS_EFFICIENCY * num;

	for (i = 0; i < S; i++) {
		for (j = 0; j < S; j++) {
			red = 0; green = 0; blue = 0; rre_n++;

			for (k = 0; k < 1; k++) {
				// generation zero
				Ray &r = rays [0]; Ray::Clear (&r);
				r.x = camPosX; r.dx = camFwdX + ((i - 0.5 * S) * camUpX + (j - 0.5 * S) * camSideX) * FOV_ATAN / S;
				r.y = camPosY; r.dy = camFwdY + ((i - 0.5 * S) * camUpY + (j - 0.5 * S) * camSideY) * FOV_ATAN / S;
				r.z = camPosZ; r.dz = camFwdZ + ((i - 0.5 * S) * camUpZ + (j - 0.5 * S) * camSideZ) * FOV_ATAN / S;
				double rdL = 1 / sqrt (r.dx * r.dx + r.dy * r.dy + r.dz * r.dz);
				r.dx *= rdL; r.dy *= rdL; r.dz *= rdL;

				m = 0; int used = 1;
				while (m < used) {
					// process one ray
					Ray &r = rays [m];

					double step = appDist (r.x, r.y, r.z);
					if (step < STEP) step = STEP;
					double rx0 = r.x, rx1 = r.x + r.dx * step, rx = rx1;
					double ry0 = r.y, ry1 = r.y + r.dy * step, ry = ry1;
					double rz0 = r.z, rz1 = r.z + r.dz * step, rz = rz1;

					if (hitTest (rx, ry, rz)) while (
						(rx1 - rx0) * (rx1 - rx0) +
						(ry1 - ry0) * (ry1 - ry0) +
						(rz1 - rz0) * (rz1 - rz0) > PRECISION) {
						// http://www.codinginstinct.com/2008/11/raytracing-4d-fractals-visualizing-four.html
						rx = 0.5 * (rx0 + rx1); ry = 0.5 * (ry0 + ry1); rz = 0.5 * (rz0 + rz1);
						if (hitTest (rx, ry, rz)) {
							rx1 = rx; ry1 = ry; rz1 = rz;
						} else {
							rx0 = rx; ry0 = ry; rz0 = rz;
						}
					}

					r.x = rx1; r.y = ry1; r.z = rz1;

					if (hitTest (r.x, r.y, r.z)) {
						// we hit something - scatter
						if (r.generation < TTL) {
							for (int n1 = 0; n1 < N; n1++) {
								if (used < num) {
									Ray &r1 = rays [used];
									r1.generation = r.generation + 1;
									r1.x = r.x; r1.y = r.y; r1.z = r.z;
									r1.dx = directions [n1].dx;
									r1.dy = directions [n1].dy;
									r1.dz = directions [n1].dz;
									// this basically defines "material"
									r1.magnitude = r.magnitude * 0.9;

									used++;
								} else {
									// rays pool exhausted :(\n");
									break;
								}
							}
						}

						m++;
					} else {
						double d2 = r.x * r.x + r.y * r.y + r.z * r.z;
						if (d2 > 1.1) {
							// radialize
							r.x += 1e4 * r.dx;
							r.y += 1e4 * r.dy;
							r.z += 1e4 * r.dz;
							d2 = r.x * r.x + r.y * r.y + r.z * r.z;
							// we hit light - get color from lightmap
							// this SHOULD be determined by the way lightmap is made ;)
							d2 = 1 / sqrt (d2); r.x *= d2; r.y *= d2; r.z *= d2;
							int lx = int (lmWidth * 0.25 * ( (r.z > 0) ? 1 + r.x : 3 - r.x ));
								if (lx > lmWidth - 1) lx = lmWidth - 1; else if (lx < 0) lx = 0;
							int ly = int (lmHeight * 0.5 * (1 + r.y));
								if (ly > lmHeight - 1) ly = lmHeight - 1; else if (ly < 0) ly = 0;
							Pixel *c = (Pixel *) &lightmap [lx * 3 + ly * lmStride];
							// sky hack
							if (r.generation == 0) {
								r.magnitude = ns; rre_n--;
							} else {
								rre_r++;
							}
							red += r.magnitude * c->R;
							green += r.magnitude * c->G;
							blue += r.magnitude * c->B;

							m++;
						}
					}
				}
			}

			// set pixel
			int ir = int (red   / ns);
			int ig = int (green / ns);
			int ib = int (blue  / ns);
			if (DITHERING) {
				if (random () < red   / ns - ir) ir++;
				if (random () < green / ns - ig) ig++;
				if (random () < blue  / ns - ib) ib++;
			}
			if (ir > 255) ir = 255;
			if (ig > 255) ig = 255;
			if (ib > 255) ib = 255;
			Pixel *c = (Pixel *) &canvas [i * 3 + j * iStride];
			c->R = unsigned char (ir);
			c->G = unsigned char (ig);
			c->B = unsigned char (ib);
		}

		printf ("\rScanline %d of %d (%d%%)", (i+1), S, int (double(100 * (i+1)) / S));
		if (kbhit()) {
			printf ("\n\nExit [y/n]? ");
			int ch = getchar ();
			if ((ch == 'y') || (ch == 'Y')) break;
		}
	}

	saveBitmap (pCanvasBitmap, "render.bmp");

	printf ("\n\n");
	printf ("Efficient rays per pixel %f (estimate %f) out of possible %d (ratio %f)\n",
		double (rre_r) / rre_n, ns, num, ( double (rre_r) / rre_n ) / num);

	// release stuff
	delete [] directions;
	delete [] rays;
	delete [] pCanvasBitmap;
	delete [] pLightmapBitmap;
	Gdiplus::GdiplusShutdown(gdiplusToken);
	return 0;
}




















// misc. boring func-s

bool FileExists(char *filename) { 
  struct stat stFileInfo; 
  bool blnReturn; 
  int intStat; 

  intStat = stat(filename, &stFileInfo); 
  if(intStat == 0) { 
    blnReturn = true; 
  } else { 
    // We were not able to get the file attributes. 
    // This may mean that we don't have permission to 
    // access the folder which contains this file.
    blnReturn = false; 
  } 
   
  return(blnReturn); 
}

void showSysErrMsg (char *unknown) {
#define EC_MAXCHARS 1024
	char msgSysInfo [EC_MAXCHARS + 1]; SecureZeroMemory (msgSysInfo, sizeof (msgSysInfo));
	DWORD sysErrCode = GetLastError ();
	if (sysErrCode != ERROR_SUCCESS) {
		LPVOID lpMsgBuf;
		if (FormatMessage (
			FORMAT_MESSAGE_ALLOCATE_BUFFER | 
			FORMAT_MESSAGE_FROM_SYSTEM | 
			FORMAT_MESSAGE_IGNORE_INSERTS,
			NULL,
			sysErrCode,
			MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), // Default language
			(LPTSTR) &lpMsgBuf,
			0,
			NULL ) == 0) {
			// no message found for sysErrCode, put the code itself in msgSysInfo
			_snprintf (msgSysInfo, EC_MAXCHARS, "Last error code value was %d.", sysErrCode);
		} else {
			// copy lpMsgBuf to msgSysInfo and release memory
			_snprintf (msgSysInfo, EC_MAXCHARS, "Error %d: %s", sysErrCode, (LPCTSTR)lpMsgBuf);
			LocalFree (lpMsgBuf);
		}
		puts (msgSysInfo);
	} else {
		puts (unknown);
	}
#undef EC_MAXCHARS
}

void saveBitmap(unsigned char *pBuffer, char *pFileName) {
	PBITMAPINFOHEADER pbih = (PBITMAPINFOHEADER) pBuffer;
	DWORD dwTmp;

	HANDLE hf = CreateFile(pFileName, 
               GENERIC_READ | GENERIC_WRITE, 
               (DWORD) 0, 
               NULL, 
               CREATE_ALWAYS, 
               FILE_ATTRIBUTE_NORMAL, 
               (HANDLE) NULL); 
	if (hf == INVALID_HANDLE_VALUE)
		return/*throw 0*/;

	BITMAPFILEHEADER hdr;
	hdr.bfType = 0x4d42; // 0x42 = "B" 0x4d = "M"
	hdr.bfSize = (DWORD) (sizeof(BITMAPFILEHEADER) + 
             pbih->biSize + pbih->biClrUsed 
             * sizeof(RGBQUAD) + pbih->biSizeImage);
	hdr.bfReserved1 = hdr.bfReserved2 = 0;
	hdr.bfOffBits = (DWORD) sizeof(BITMAPFILEHEADER) + 
             pbih->biSize + pbih->biClrUsed 
             * sizeof (RGBQUAD);
	if (!WriteFile(hf, (LPVOID) &hdr, sizeof(BITMAPFILEHEADER), (LPDWORD) &dwTmp,  NULL))
		return/*throw 0*/;
	if (!WriteFile(hf, (LPVOID) pbih, sizeof(BITMAPINFOHEADER) + pbih->biClrUsed * sizeof (RGBQUAD), (LPDWORD) &dwTmp, NULL))
		return/*throw 0*/;

	LPBYTE lpBits = ((LPBYTE)pbih + (WORD)(pbih->biSize));
	if (!WriteFile(hf, (LPSTR) lpBits, (int) pbih->biSizeImage, (LPDWORD) &dwTmp, NULL))
		return/*throw 0*/;

	if (FAILED(CloseHandle(hf)))
		return/*throw 0*/;
}

unsigned char *loadBitmap (char *fname) {
	// Create initial Bitmap object
	CComBSTR bstrfname (fname);
	Gdiplus::Bitmap *pBitmap = Gdiplus::Bitmap::FromFile (bstrfname);
	if (pBitmap == NULL) {
		return NULL;
	}

	// Get bitmap data in RGB-24 format (do we really need to initialize bd here ?)
	Gdiplus::BitmapData bd; bd.Scan0 = NULL; bd.PixelFormat = PixelFormat24bppRGB;
	bd.Width = pBitmap->GetWidth (); bd.Height = pBitmap->GetHeight (); bd.Stride = STRIDE_3ALIGN4 (bd.Width);
	Gdiplus::Rect rect (0, 0, (INT)bd.Width, (INT)bd.Height);
	Gdiplus::Status res = pBitmap->LockBits (&rect, Gdiplus::ImageLockModeRead, bd.PixelFormat, &bd);
	if ((res != Gdiplus::Ok) || (bd.PixelFormat != PixelFormat24bppRGB)) {
		return NULL;
	}

	// construct valid BITMAPINFOHEADER in pBuffer and append bd data there
	unsigned char *pBuffer;
	try {
		pBuffer = new unsigned char [sizeof (BITMAPINFOHEADER) + STRIDE_3ALIGN4 (bd.Width) * bd.Height];
	} catch (...) {
		// swallow any allocation errors here to return NULL
	}

	if (pBuffer == NULL) {
		return NULL;
	}

	PBITMAPINFOHEADER pbih = (PBITMAPINFOHEADER) pBuffer; ZeroMemory (pbih, sizeof (BITMAPINFOHEADER));
	pbih->biBitCount = 24; pbih->biCompression = BI_RGB; pbih->biHeight = bd.Height; pbih->biWidth = bd.Width;
	pbih->biPlanes = 1; pbih->biSize = sizeof (BITMAPINFOHEADER); pbih->biSizeImage = STRIDE_3ALIGN4 (pbih->biWidth) * pbih->biHeight;
	pbih->biXPelsPerMeter = pbih->biYPelsPerMeter = 0; // TODO: aspect ???

	memcpy ((LPBYTE)pbih + (WORD)(pbih->biSize), bd.Scan0, pbih->biSizeImage);

	// Release GDI+ stuff
	pBitmap->UnlockBits (&bd); delete pBitmap;

	return pBuffer;
}