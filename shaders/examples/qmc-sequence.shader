#line 1
precision highp float;

#include "shaders/library/common.shader"
#include "shaders/library/random.shader"
#line 6

// Pass number for the progressive renderer
uniform int u_PassNumber;
uniform int u_RandomSequence;

#define NB_SAMPLES 32

vec3 TestColor(int index) {
    float x = float(index) / float(NB_SAMPLES-1);
    return vec3(x, 0.0, 1.0-x);
}

/* Test the QMC sampling distributions.
 *
 * This fragment shader draw one element of a 3D QMC sequence at a time.
 * If you use it with the progressive renderer, it will accumulate the
 * samples and display the sequence.
 */
void main(void) {
 
    // Get the next 3D point in the sequence and splat it
    float nbs = float(NB_SAMPLES);
    int   idx = mod(u_PassNumber, NB_SAMPLES);
    
    vec2 rnd;
    if(u_RandomSequence == 0) {
        rnd = QMC_Additive_3D(idx).xy;
    } else {
        rnd = QMC_Davenport(idx, NB_SAMPLES);
    }
    
    vec3  R   = TestColor(idx);

    // Splat a Gaussian kernel and adapt width to the number of samples
    R *= exp(- 0.5 * sqr(nbs * length(2.0*(rnd.xy - vec2(0.5, 0.5)) - vPos.xy)));

    // Scale the contribution to avoid black pixels
    R *= 2.0 * nbs;

    gl_FragColor = vec4(R, 1.0);
}