#define COMMON_SHADER

///////////////////////////////////////////////////////////////////////////////
//                                                                           //
//                              Common macros                                //
//                                                                           //
///////////////////////////////////////////////////////////////////////////////

// {TODO: the REQUIRE macro}


///////////////////////////////////////////////////////////////////////////////
//                                                                           //
//                              Common constants                             //
//                                                                           //
///////////////////////////////////////////////////////////////////////////////

#define PI     3.14159265358979323846
#define INV_PI 0.31830988618

///////////////////////////////////////////////////////////////////////////////
//                                                                           //
//                        Common helper functions                            //
//                                                                           //
///////////////////////////////////////////////////////////////////////////////

float sqr(float x) {
    return x*x;
}

vec2 sqr(vec2 x) {
    return x*x;
}

vec3 sqr(vec3 x) {
    return x*x;
}

/* Create a tangent frame 't', 'b', 'n' from a normal 'n' using Jeppe 
 * Frisvad's method.
 */
void FrameFrisvad(in vec3 n, out vec3 t, out vec3 b) {
    if(n.z < -0.9999999) { // Handle the singularity
        t = vec3( 0.0, -1.0, 0.0);
        b = vec3(-1.0,  0.0, 0.0);
        return;
    }
    float x = 1.0/(1.0 + n.z);
    float y = -n.x*n.y*x;
    t = vec3(1.0 - n.x*n.x*x, y, -n.x);
    b = vec3(y, 1.0 - n.y*n.y*x, -n.y);
}

/* Spherical Gaussian
 */
float SphericalGaussian(vec3 x, vec3 mu, float var) {
    float k   = 1.0 / var;
    float xmu = dot(x, mu);
    float C3k = k / (2.0*PI * (exp(k) - exp(-k)));
    return exp(k * (dot(x, mu) - 1.0));
}

int imod(int n, int N) {
    return n - N*(n / N);
}


///////////////////////////////////////////////////////////////////////////////
//                                                                           //
//                         Common math functions                             //
//                                                                           //
///////////////////////////////////////////////////////////////////////////////

// float sinh(float x) {
//     return 0.5 * (1.0 - exp(- 2.0 * x)) / exp(- x);
// }

// float cosh(float x) {
//     return 0.5 * (1.0 + exp(- 2.0 * x)) / exp(- x);
// }

// float coth(float x) {
//     return (1.0 - exp(- 2.0 * x)) / (1.0 + exp(- 2.0 * x));
// }