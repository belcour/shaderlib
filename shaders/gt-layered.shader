#line 1
precision highp float;

#include "shaders/library/common.shader"
#include "shaders/library/random.shader"
#include "shaders/library/brdf.shader"
#include "shaders/library/layer.shader"
#line 7

// Uniform variables
uniform vec3  wi;
uniform float roughness;
uniform float eta1;

// Pass number for the progressive renderer
uniform int u_PassNumber;

#define MAX_BOUNCE 8
#define NB_SAMPLES 1024


/* {TODO: Move this function in Layer.shader}
 */
vec3 RaytraceLayers(in vec3 wC, in vec3 wL) {
    // Resulting color & accumulated weight
    vec3 W = vec3(1.0, 1.0, 1.0);
    vec3 R = vec3(0.0, 0.0, 0.0);
    int dz = +1;

    // Index for the paths' end
    int  wCi = 0, wLi = 0;
    vec3 wCw = wC, wLw = wL;
    vec3 m, mL; float pdf;

    /* Test if the first layer is purely specular. If so, change the incoming
     * and outgoing direction to be the transmitted ones. Apply the Fresnel
     * coefficients to the resulting color.

     * {Note: Check if there is a needed scaling factor}
     */
    BsdfLayer layer1 = GetLayer(wCi);
    BsdfLayer layer2 = GetLayer(wCi+1);
    
    // Accumulate the direct reflection
    float Fd = FresnelUnpolarized(wCw.z, layer1.n, layer2.n, layer2.k);
    R += Fd * GGX(wCw, wLw, vec3(0.0, 0.0, 1.0), max(layer2.a, 1.0E-5)) * W;
    if(layer2.k > 0.0) {
        return R;
    }

    // Random number
    //int  idx = mod(u_PassNumber, NB_SAMPLES);
    int  idx = u_PassNumber;
    vec3 rnd = clamp(QMC_Additive_3D(idx), vec3(1.0E-6,1.0E-6,1.0E-6), vec3(0.99999,0.99999,0.99999));
    vec2 rnd2 = clamp(QMC_Additive_2D(idx), vec2(1.0E-6,1.0E-6), vec2(0.99999,0.99999));
    //rnd.xy = QMC_Davenport(idx, NB_SAMPLES);
    
    // Compute the transmitted rays and the transmittance
    float R12, R12p;
    GGX_Sample_VNDF(wC, layer2.a, rnd.xy, m, pdf);
    GGX_Sample_VNDF(wL, layer2.a, rnd2, mL, pdf);
    // SamplingUniformHemisphere(rnd.xy, m, pdf);
    // W *= GGX_D(m.z, layer2.a) / pdf;
    if(dot(wC, m) < 0.0 || dot(wL, m) < 0.0) {
        return R;
    }

    Fresnel(wC, m, layer1.n, layer2.n, wCw, R12);
    Fresnel(wL, mL, layer1.n, layer2.n, wLw, R12p);
    wCi += 1;
    wLi += 1;

    // Update the weight
    W *= clamp((1.0-R12)*(1.0-R12p), 0.0, 1.0);
    if(length(W) <= 0.0) { return R; }

    // Select the layer
    layer1 = GetLayer(wCi);
    layer2 = GetLayer(wCi+1);

    /* Direct connection if possible */

    // Only accumulate if the layers index match
    if(wCw.z < 0.0 || wLw.z < 0.0) { return R; }
    
    vec3 h = normalize(wCw + wLw);
    Fd = FresnelUnpolarized(dot(wCw, h), layer1.n, layer2.n, layer2.k);
    R += W * Fd * GGX(wCw, wLw, vec3(0.0, 0.0, 1.0), layer2.a);
    return R;

    /* Randomly walk into the layer structure starting from interface wCi
     * and wLi.
     */
    for(int bounce=1; bounce<MAX_BOUNCE; ++bounce) {

        if(wCw.z < 0.0 || wCi+dz < 0) { return R; }

        // Select the layer
        layer1 = GetLayer(wCi);
        layer2 = GetLayer(wCi+dz);

        /* Direct connection if possible */

        // Only accumulate if the layers index match
        if(wCi == wLi && dz > 0) {
            float Fd = FresnelUnpolarized(wCw.z, layer1.n, layer2.n, layer2.k);
            R += W * Fd * GGX(wCw, wLw, vec3(0.0, 0.0, 1.0), layer2.a);

        } /* else if(wCi == wLi && dz < 0) {
            float Fd = FresnelUnpolarized(wCw.z, layer1.n, layer2.n, layer2.k);
            R += W * GGX_T(wCw, wLw, vec3(0.0, 0.0, 1.0), layer1.n/layer2.n, Fd, layer2.a);
        }*/

        return R;

        /* Continue Random Walk */

        // Random number
        int  idx = bounce*NB_SAMPLES + mod(u_PassNumber, NB_SAMPLES);
        vec3 rnd = QMC_Additive_3D(idx);
        
        // Randomly select a microfacet
        SamplingUniformHemisphere(rnd.xy, m, pdf);
        // Backfacing microfacet: this is an invalid configuration!
        if(dot(wCw, m) <= 0.0) {
            return R;
        }

        // Evaluate the Fresnel term
        vec3 w; float R12;
        //Fresnel(wCw, layer1.n, layer2.n, layer2.k);
        Fresnel(wCw, layer1.n, layer2.n, layer2.k, w, R12);


        /* Select if we transmit or reflect and update the corresponding
         * weight. Update the layer number for the camera path.
         */
        if(rnd.z < R12) {
            // Reflect
            //W   *= F;
            wCw  = reflect(wCw, m);
            dz   = -1;
        } else {
            // Transmit
            //W   *= (1.0 - F);
            wCw  = w; //Fresnel(wCw, m, layer1.n/layer2.n);
            dz   = +1;
        }

        // Update layer index
        wCi += dz;
    }

    return R;
}

void main(void) {

    // Get the omega_o direction from the vPos variable
    vec3 wo;
    wo.xy = vPos.xy;
    float sinTo = length(wo.xy);
    if(sinTo <= 1.0) {
        wo.z = sqrt(1.0 - sinTo*sinTo);

         /* Perform random evaluation of the layered structure using 'wiT' and 'woT'
          * as the incoming and outgoing directions.
          */
        gl_FragColor.xyz = wo.z * RaytraceLayers(wo, wi) * vec3(1.0, 1.0, 1.0);
        gl_FragColor.w   = 1.0;

        if(dot(wo, wi) > 0.99995) {
            gl_FragColor.xyz = vec3(1.0, 0.0, 0.0);
        }
        
    } else {
        gl_FragColor = vec4(0.0, 0.0, 0.0, 0.0);
    }
}