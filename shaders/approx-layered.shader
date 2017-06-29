#line 1
precision highp float;

#include "../shaders/library/common.shader"
#include "../shaders/library/brdf.shader"
#include "../shaders/library/layer.shader"
#include "../shaders/library/pivot.shader"
//#include "shaders/library/covariance.shader"
#line 9

// Uniform variables
uniform vec3 wi;
uniform int  u_ApproxMethod;

void ComputeApproxRoughness(in vec3 wi, in vec3 wo, out vec2 a, out vec2 f) {

    // Set the initial values for the importance distribution
    a = vec2(0.0, 0.0);
    f = vec2(1.0, 1.0);

    // Temp variables
    float R23, R12i, R12o, s12, s23;
    vec3  wt,  w,    wto;

    // IOR ratio
    float ieta = layers[0].n / layers[1].n;
    float eta  = layers[1].n / layers[0].n;

    // First interface (between air [0] and first layer [1])
    s12  = sqr(layers[1].a) / 2.0 * ( 1.0 -sqr(layers[1].a));
    //a   += s12 * vec2(1.0, 1.0-ieta);
    a   += s12 * vec2(1.0, 1.0);
    if(layers[1].k > 0.0) {
        Fresnel(wo, layers[0].n, layers[1].n, layers[1].k, wto, R12i);
        f *= abs(vec2(R12i, 0.0));
        a  = sqrt(2.0 / ((1.0/a) + 2.0));
        return;
    } else {
        Fresnel(wo, layers[0].n, layers[1].n, wto, R12i);
        Fresnel(wi, layers[0].n, layers[1].n, wt,  R12o);
        f *= abs(vec2(R12i, (1.0 - R12i) * (1.0 - R12o)));

        // Scale the roughness for the transmission
        // Here I need to figure out what to do (two solutions):
        //  (1) Jacobian from half-space to transmitted
        //  (2) ad-hoc scaling
        // I think I should scale the roughness instead of the variance of outgoing lobe.
        a.y *= sqr(wi.z - eta*wt.z) / (sqr(eta) * wt.z); // (1)
      //a.y *= 1.0 - ieta;                               // (2)
    }

    // Second interface (first layer [1] and second layer [1])
    vec3 m2 = normalize(wto + wt);
    R23 = FresnelUnpolarized(wto.z, layers[1].n, layers[2].n, layers[2].k);
    s23 = sqr(layers[2].a) / 2.0 * ( 1.0 -sqr(layers[2].a));
    a.y += s23;
    f.y *= clamp(R23, 0.0, 1.0);

    // Compute the TIR portion and remove it from single scatter
    // {TODO}
    // vec3  wr  = reflect(wt, vec3(0.0, 0.0, 1.0));
    // float cap = asin(layers[0].n / layers[1].n);
    // vec3 _pw; float _pcap = 0.0;
    // PivotProjectCap(vec3(0.0, 0.0, 1.0), cap, layers[2].a*wr, _pw, _pcap);
    // f *= 2.0*PI*(1.0 - cos(_pcap));

    // Warping due to clear coat
    float jaci = (layers[0].n * wi.z) / (layers[1].n * wt.z);
    a.y /= sqr(jaci);
    //a.y += (1.0-ieta)*s12;
    
    // Convert back to roughness
    a  = sqrt(2.0 / ((1.0/a) + 2.0));

    // Update the intensity
    f.y /= sqr(ieta);// /  (wi.z / wt.z);
}

void ComputeApproxVMF(in  vec3 wi, in  vec3 wo,
                      out vec2 mu, out vec2 km) {
    vec3  wto, t1, t2, m1, m2;
    float R12i, R12o, R23;
    float km1, km2;

    mu = vec2(1.0, 1.0);    
    km = vec2(0.0, 0.0);

    // IOR ratio
    float eta  = layers[0].n / layers[1].n;
    float ieta = layers[0].n / layers[1].n;

    // Exponent of the first layer
    km1 = vMF_RoughnessToKm(layers[1].a);
    
    if(layers[1].k > 0.0) {
        km.x = km1;
        Fresnel(wo, layers[0].n, layers[1].n, layers[1].k, wto, R12i);
        mu *= abs(vec2(R12i, 0.0));
        return;
    }
    
    // Evaluate Fresnel and the transmitted rays
    Fresnel(wo, layers[0].n, layers[1].n, t1, R12i);
    Fresnel(wi, layers[0].n, layers[1].n, t2, R12o);
    mu *= abs(vec2(R12i, (1.0 - R12i) * (1.0 - R12o)));    
    km.x = km1;


    // Second interface (first layer [1] and second layer [1])
    R23 = FresnelUnpolarized(t1.z, layers[1].n, layers[2].n, layers[2].k);
    mu *= abs(vec2(1.0, R23));

    // Define the half vectors on the first and second layers
    m1 = normalize(wi + wo);
    m2 = normalize(t1 + t2);

    // Convert layer roughness to exponent
    km2 = vMF_RoughnessToKm(layers[2].a);

    // Evaluate Jacobians and new exponent.
    // Warning: those jacobians are computed w.r.t the central rays!
    // Thus it is safe to say: wm1 == wm2 = n
    // TODO compute the correct jacobians
    float J1, J2, J3;
    J1 = abs(wi.z / sqr(wi.z - eta*t1.z));          // | dwm1 / dwo |
    J2 = abs(wi.z / abs(4.0*t1.z * sqr(eta)*t1.z)); // | dwm2 / dto | | dto / dwo |
    J3 = J1;                                        // | dwm1 / dti | | dti / dto |  | dto / dwo |
    float J1km1 = vMF_A3(J1 * km1);
    float J2km2 = vMF_A3(J2 * km2);
    float J3km1 = vMF_A3(J3 * km1);
    km.y = vMF_invA3(J1km1 * J2km2 * J3km1);
}

/* Compute the approximate GGX lobe using the method of Elek [2010].
 * TODO: I do not account for the G term modulation in the base layer.
 */
void ComputeApproxElek(in vec3 wi, in vec3 wo, out vec2 a, out vec2 f) {

    // Set the initial values for the importance distribution
    a = vec2(0.0, 0.0);
    f = vec2(1.0, 1.0);

    // Temp variables
    float R23, R12i, R12o, s12, s23;
    vec3  wt, w, wto;

    // IOR ratio
    float eta  = layers[1].n / layers[0].n;
    float ieta = layers[0].n / layers[1].n;

    // First interface (between air [0] and first layer [1])
    if(layers[1].k > 0.0) {
        Fresnel(wo, layers[0].n, layers[1].n, layers[1].k, wto, R12i);
        f *= abs(vec2(R12i, 0.0));
        a.x = layers[1].a;
        return;
    } else {
        Fresnel(wo, layers[0].n, layers[1].n, wto, R12i);
        Fresnel(wi, layers[0].n, layers[1].n, wt,  R12o);
        f *= abs(vec2(R12i, (1.0 - R12i) * (1.0 - R12o)));
        a.x = layers[1].a;
    }

    // Second interface (first layer [1] and second layer [1])
    vec3 m2 = normalize(wto + wt);
    R23 = FresnelUnpolarized(wto.z, layers[1].n, layers[2].n, layers[2].k);
    f.y *= clamp(R23, 0.0, 1.0);
    a.y = max(layers[1].a, layers[2].a);
}


void main(void) {

    // Get the omega_o direction from the vPos variable
    vec3 wo;
    wo.xy = vPos.xy;
    float sinTo = length(wo.xy);
    if(sinTo <= 1.0) {
        wo.z = sqrt(1.0 - sinTo*sinTo);
        vec3 wr = -reflect(wo, vec3(0.0, 0.0, 1.0));

        vec3 R = vec3(0.0, 0.0, 0.0);
        // Using covariance approximation for the resulting BRDF function.
        if(u_ApproxMethod == 0) {

            // Return the BRDF values for the provided wi, wo configuration assuming
            // that n=[0,0,1] and the microfact model is GGX
            vec2 a, f;
            ComputeApproxRoughness(wi, wo, a, f);

            float GGX_r;
            GGX_r  = GGX(wi, wo, vec3(0.0, 0.0, 1.0), max(a.x, 1.0E-5));
            R     += f.x * GGX_r * vec3(1.0, 1.0, 1.0);
            
            GGX_r  = GGX(wi, wo, vec3(0.0, 0.0, 1.0), max(a.y, 1.0E-5));
            R     += f.y * GGX_r * vec3(1.0, 1.0, 1.0);

        // Using vMF microfacet model approximation [Guo et al. 2016]
        } else if(u_ApproxMethod == 1) {
            vec2 mu, km;
            ComputeApproxVMF(wi, wo, mu, km);

            float vMF_r;
            vMF_r  = vMF_BRDF(wi, wo, km.x);
            R     += mu.x * vMF_r * vec3(1.0, 1.0, 1.0);

            if(mu.y > 0.0) {
                vMF_r  = vMF_BRDF(wi, wo, km.y);
                R     += mu.y * vMF_r * vec3(1.0, 1.0, 1.0);
            }

        // Oskar Elek method using the min of the roughness
        } else {
            vec2 a, f;
            ComputeApproxElek(wi, wo, a, f);

            float GGX_r;
            GGX_r  = GGX(wi, wo, vec3(0.0, 0.0, 1.0), max(a.x, 1.0E-5));
            R     += f.x * GGX_r * vec3(1.0, 1.0, 1.0);
            
            GGX_r  = GGX(wi, wo, vec3(0.0, 0.0, 1.0), max(a.y, 1.0E-5));
            R     += f.y * GGX_r * vec3(1.0, 1.0, 1.0);
        }

        gl_FragColor.xyz = R * wo.z * vec3(1.0, 1.0, 1.0);
        gl_FragColor.w   = 1.0;

        if(dot(wo, wi) > 0.99995) {
            gl_FragColor.xyz = vec3(1.0, 0.0, 0.0);
        }
    } else {
        gl_FragColor = vec4(0.0, 0.0, 0.0, 0.0);
    }
}
