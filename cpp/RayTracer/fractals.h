bool hitTestMenger3D (double x, double y, double z);
double appDistMenger3D (double x, double y, double z);

bool hitTestMenger4D (double x, double y, double z);
double appDistMenger4D (double x, double y, double z);


// what fractal to render
#define hitTest hitTestMenger4D
#define appDist appDistMenger4D