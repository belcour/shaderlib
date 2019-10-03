#define LAYER_SHADER

#ifndef BRDF_SHADER
  #error Missing brdf.shader include in main shader
#endif



///////////////////////////////////////////////////////////////////////////////
//                                                                           //
//                             Layer Structure                               //
//                                                                           //
///////////////////////////////////////////////////////////////////////////////

/* A BSDF layer represent a rough interface between two medium of constant IOR.
 * It is viewed from top to bottom. As such, the upper IOR is always real. If
 * a layer has a complex bottom IOR (k2 > 0), it ends the layered structure.
 */
struct BsdfLayer {
    float n;    // Index of refraction
    vec3  k;    // Imaginary part of the second IRO
    vec2  a;    // Roughness of the layer
};

/* BSDF lobe
 */
struct BsdfLobe {
    vec3 wi;
    vec3 R;
    vec2 a;
};

/* The layer structure has to be created using 'layers' uniform variable. You
 * have to set 'layers[id].n1' in the main HTML file.
 */
#define NUM_LAYERS 2
uniform BsdfLayer u_BsdfLayers[NUM_LAYERS];



/* Helper function to select a given layer by index 'start' since it is
 * not possible to use a non constant index to layers[index].
 *
 * If the max number of layer is reached, return air's IOR and a planar
 * geometry for the microfacets.
 */
BsdfLayer GetLayer(int start) {
    for(int i=0; i<NUM_LAYERS; ++i) {
        if(start == i) {
            return u_BsdfLayers[i];
        }
    }

    BsdfLayer layer;
    layer.n = 1.0;
    layer.k = vec3(0, 0, 0);
    layer.a = vec2(0, 0);
    return layer;
}


/* Compute the BSDF lobes from a set of layers and an input
 * direction
 */
void ComputeBsdfLobes(in vec3 wi, in BsdfLayer[NUM_LAYERS] layers, out BsdfLobe[NUM_LAYERS] lobes)
{
    vec3 rij = vec3(0.0, 0.0, 0.0);
    vec3 tij = vec3(1.0, 1.0, 1.0);

    // Evaluate the reflectance and transmittance of the top layer
    vec3 r12, t12;
    if(layers[0].n > 0.0) {
        r12 = FresnelUnpolarized(wi.z, 1.0, layers[0].n)*vec3(1.0);
        t12 = vec3(1.0, 1.0, 1.0) - r12;
    } else {
        r12 = FresnelSchlick(wi.z, layers[0].k);
        t12 = vec3(0.0, 0.0, 0.0);
    }

    // Write the BSDF lobe for the first layer
    // Early exit if the layer is a conductor (no transmittance)
    lobes[0].wi = wi;
    lobes[0].R  = r12;
    lobes[0].a  = layers[0].a;
    if(layers[0].n <= 0.0) {
        lobes[1].wi = wi;
        lobes[1].R  = vec3(0);
        lobes[1].a  = layers[1].a;
        return;
    }

    // Update the global transmittance and reflectance
    tij *= t12;
    rij += r12;

    // Snell laws for the central ray
    vec3 wt;
    wt.xy = (1.0/layers[0].n)*wi.xy;
    wt.z  = sqrt(1.0 - (wi.x*wi.x + wi.y*wi.y));


    // Evaluate the reflectance and transmittance of the bottom layer
    vec3 r23, t23;
    if(layers[1].n > 0.0) {
        r23 = FresnelUnpolarized(wt.z, layers[0].n, layers[1].n)*vec3(1.0);
        t23 = vec3(1.0, 1.0, 1.0) - r23;
    } else {
        r23 = FresnelSchlick(wt.z, layers[1].k);
        t23 = vec3(0.0, 0.0, 0.0);
    }

    lobes[1].wi = wi;
    lobes[1].R  = tij * (r23 / (vec3(1.0) - r12*r23)) * tij;
    lobes[1].a  = max(layers[1].a, layers[0].a);
}