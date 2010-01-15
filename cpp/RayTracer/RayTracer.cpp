// RayTracer.cpp : wonderfl's Very Bad Raytracer port
// http://code.google.com/p/makc/source/browse/trunk/flash/wonderfl/RayTracer.as
#include <atlbase.h> // CComBSTR (also helps gdiplus.h to compile :)
#include <gdiplus.h> // (add gdiplus.lib)

#include <sys/stat.h>

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

#include <math.h>
#include <time.h>

#ifndef PI
#define PI 3.1415926535897932384626433832795
#endif

#define STRIDE_3ALIGN4(W) (((3*((W)+1))>>2)*4)

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
};

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

struct Pixel {
	unsigned char B;
	unsigned char G;
	unsigned char R;
	unsigned char A;
};

struct Ray {
	bool active;
	int generation, s;
	double magnitude, x, y, z, dx, dy, dz;
	Ray::Ray () {
		active = false; generation = 0; magnitude = 1; x = 0; y = 0; z = 0;
	}
};

double random () {
	return double (rand ()) / RAND_MAX;
}

bool hitTest (double x, double y, double z) {
	// Menger sponge:
	// http://www.fractalforums.com/3d-fractal-generation/revenge-of-the-half-eaten-menger-sponge/
	x += 0.5;
	y += 0.5;
	z += 0.5;
	int iterations = 7;
	if ((x<0)||(x>1)||(y<0)||(y>1)||(z<0)||(z>1)) return false;
	double p = 3;
	for (int m = 1; m < iterations; m++) {
		double xa = fmod (x*p, 3);
		double ya = fmod (y*p, 3);
		double za = fmod (z*p, 3);
		if (
			((xa > 1.0) && (xa < 2.0)   &&   (ya > 1.0) && (ya < 2.0)) ||
			((ya > 1.0) && (ya < 2.0)   &&   (za > 1.0) && (za < 2.0)) ||
			((xa > 1.0) && (xa < 2.0)   &&   (za > 1.0) && (za < 2.0))
			) return false;
		p *= 3;
	}
	return true;
}

int main(int argc, char* argv[])
{
	srand ((unsigned int) time (NULL));
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

	//saveBitmap (pLightmapBitmap, "lm.bmp");

	unsigned char *lightmap = (pLightmapBitmap + (WORD)(((PBITMAPINFOHEADER)pLightmapBitmap)->biSize));
	int lmWidth = ((PBITMAPINFOHEADER) pLightmapBitmap)->biWidth;
	int lmHeight = ((PBITMAPINFOHEADER) pLightmapBitmap)->biHeight;
	int lmStride = STRIDE_3ALIGN4 (lmWidth);

	int const S = 512; // tracing SxS bitmap
	int const N = 7; // rays per ray per generation
	int const TTL = 2; // generations: rays per pixel should be < N^TTL
/// constant step was causing crop circles :( 
///	double const STEP = 0.002; // 0.0 < step << 1.0
int const STEP_N = 12345;

	int const MAX_RAYS = 10000000;

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

	// init arrays
	double *red = new double [SS]; ZeroMemory (red, SS * sizeof (double));
	double *green = new double [SS]; ZeroMemory (green, SS * sizeof (double));
	double *blue = new double [SS]; ZeroMemory (blue, SS * sizeof (double));
	int *num = new int [SS]; ZeroMemory (num, SS * sizeof (int));
	Ray *rays = new Ray [MAX_RAYS];
	Ray *directions = new Ray [N];

	int i, j, k;

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

	// generation zero
	double fovAtan = 1.5; // 1 = 90 deg, infinity = 180 deg
	for (i = 0; i < S; i++)
	for (j = 0; j < S; j++) {
		Ray &r = rays [i + S * j]; r.active = true;
		r.s = i + S * j;
		r.x = camPosX; r.dx = camFwdX + ((i - 0.5 * S) * camUpX + (j - 0.5 * S) * camSideX) * fovAtan / S;
		r.y = camPosY; r.dy = camFwdY + ((i - 0.5 * S) * camUpY + (j - 0.5 * S) * camSideY) * fovAtan / S;
		r.z = camPosZ; r.dz = camFwdZ + ((i - 0.5 * S) * camUpZ + (j - 0.5 * S) * camSideZ) * fovAtan / S;
///		double rdL = STEP / sqrt (r.dx * r.dx + r.dy * r.dy + r.dz * r.dz);
double rdL = 1 / sqrt (r.dx * r.dx + r.dy * r.dy + r.dz * r.dz);
		r.dx *= rdL; r.dy *= rdL; r.dz *= rdL;
	}

///	// pre-multiply scaterring directions
///	for (k = 0; k < N; k++) {
///		directions [k].dx *= STEP;
///		directions [k].dy *= STEP;
///		directions [k].dz *= STEP;
///	}
double *steps = new double [STEP_N];
for (i = 0; i < STEP_N; i++) steps [i] = 0.002 * random ();
int lastStep = 0;


	// loop
	int beginAt = 0;
	int newRaysAt = SS;
	bool loop = true;

	while (loop) {
		if (rays [beginAt].active) {
			// process one ray
			Ray &r = rays [beginAt];

double step = steps [lastStep];
lastStep++; lastStep %= STEP_N;
///			r.x += r.dx; r.y += r.dy; r.z += r.dz;
r.x += r.dx * step;
r.y += r.dy * step;
r.z += r.dz * step;
			if (hitTest (r.x, r.y, r.z)) {
				// we hit something - scatter
				if (r.generation < TTL) {
					for (int n1 = 0; n1 < N; n1++) {
						Ray &r1 = rays [newRaysAt];
						if (r1.active) {
							puts ("\nRays pool exhausted :(\n");
							break;
						}
						r1.active = true;
						r1.s = r.s;
						r1.generation = r.generation + 1;
						r1.x = r.x; r1.y = r.y; r1.z = r.z;
						r1.dx = directions [n1].dx;
						r1.dy = directions [n1].dy;
						r1.dz = directions [n1].dz;
						// this basically defines "material"
						r1.magnitude = r.magnitude * 0.9;

						newRaysAt++; newRaysAt %= MAX_RAYS;
					}
				}

				r.active = false; beginAt++; beginAt %= MAX_RAYS;
				if (beginAt % 12345 == 0) printf ("\rRay %d generation %d pool at %d        ", beginAt - 1, r.generation, newRaysAt);
			} else {
				double d2 = r.x * r.x + r.y * r.y + r.z * r.z;
				if (d2 > 1.1) {
					// we hit light - get color from lightmap
					// this SHOULD be determined by the way lightmap is made ;)
					d2 = 1 / sqrt (d2); r.x *= d2; r.y *= d2; r.z *= d2;
					int lx = int (lmWidth * 0.25 * ( (r.z > 0) ? 1 + r.x : 3 - r.x ));
						if (lx > lmWidth - 1) lx = lmWidth - 1; else if (lx < 0) lx = 0;
					int ly = int (lmHeight * 0.5 * (1 + r.y));
						if (ly > lmHeight - 1) ly = lmHeight - 1; else if (ly < 0) ly = 0;
					Pixel *c = (Pixel *) &lightmap [lx * 3 + ly * lmStride];
					red [r.s] += r.magnitude * c->R;
					green [r.s] += r.magnitude * c->G;
					blue [r.s] += r.magnitude * c->B;
					num [r.s] += 1;

					r.active = false; beginAt++; beginAt %= MAX_RAYS;
					if (beginAt % 12345 == 0) printf ("\rRay %d generation %d pool at %d light  ", beginAt - 1, r.generation, newRaysAt);
				}
			}
		} else {
			// no more rays left
			loop = false;
		}
	}

	// save the image
	int s; double sum = 1;
	for (s = 0; s < SS; s++) sum += num [s]; sum /= SS;
	
	for (s = 0; s < SS; s++) {
		// ugly hack for sky :(
		double ns = (num [s] > 1) ? /* body */ sum : /* sky: */ 1;
		int ir = int (red   [s] / ns); if (ir > 255) ir = 255;
		int ig = int (green [s] / ns); if (ig > 255) ig = 255;
		int ib = int (blue  [s] / ns); if (ib > 255) ib = 255;
		Pixel *c = (Pixel *) &canvas [(s % S) * 3 + (s / S) * iStride];
		c->R = unsigned char (ir);
		c->G = unsigned char (ig);
		c->B = unsigned char (ib);
	}

	saveBitmap (pCanvasBitmap, "render.bmp");







	// release stuff
	delete [] directions;
	delete [] rays;
	delete [] num;
	delete [] blue;
	delete [] green;
	delete [] red;
	delete [] pCanvasBitmap;
	delete [] pLightmapBitmap;
	Gdiplus::GdiplusShutdown(gdiplusToken);
	return 0;
}

