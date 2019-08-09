#define RANDOM_SHADER

#ifndef COMMON_SHADER
    #error Missing common.shader include in main shader
#endif

///////////////////////////////////////////////////////////////////////////////
//                                                                           //
//                          2D pseudorandom noise                            //
//                                                                           //
///////////////////////////////////////////////////////////////////////////////

/* 2D -> 1D Pseudo-random noise from [-1, 1]^2 to [-1, 1]
 */
float Noise_2D_to_1D(in vec2 coordinate, in float seed) {
    return fract(sin(dot(coordinate*seed, vec2(12.9898, 78.233)))*43758.5453);
}

/* 2D -> 2D noise
 */
vec2 Noise_2D_to_2D(in vec2 p) {
	return fract(sin(vec2(dot(p, vec2(127.1,311.7)), dot(p,vec2(269.5,183.3))))*43758.5453);
}

///////////////////////////////////////////////////////////////////////////////
//                                                                           //
//                                QMC Sequences                              //
//                                                                           //
///////////////////////////////////////////////////////////////////////////////

/* 2D Lattice grid for 1024 points
 */
vec2 Lattice2D(int i) {
    vec2 a = vec2(1.0, 275.0);
    return mod((float(i) - 1.0) * a, 1024.0) / 1024.0;
}

/* Additive sub-random sequences: we use multiple of irrational numbers
 * to fill out the unit domain. Those distribution are not good to populated
 * high dimensional domains (D > 2).
 *
 * See: https://en.wikipedia.org/wiki/Low-discrepancy_sequence#Additive_recurrence
 */
float QMC_Additive_1D(float alpha, int n) {
    return mod(alpha * float(n), 1.0);
}

float QMC_Additive_1D(int n) {
    return mod(0.618034 * float(n), 1.0);
}

vec2 QMC_Additive_2D(vec2 alpha, int n) {
    return mod(alpha * float(n), vec2(1.0, 1.0));
}

vec2 QMC_Additive_2D(int n) {
    return mod(vec2(0.5545497, 0.308517) * float(n), vec2(1.0, 1.0));
}

vec3 QMC_Additive_3D(vec3 alpha, int n) {
    return mod(alpha * float(n), vec3(1.0, 1.0, 1.0));
}

vec3 QMC_Additive_3D(int n) {
    return mod(vec3(0.645751311, 0.732050808, 0.31662479) * float(n), vec3(1.0, 1.0, 1.0));
}

/* Davenport sequence
 */
vec2 QMC_Davenport(int n, int N) {
    float alpha = 0.618034;
    return vec2(float(n)/float(N), mod(alpha*float(n), 1.0));
}