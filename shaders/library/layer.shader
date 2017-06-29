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
  float k;    // Imaginary part of the second IRO
  float a;    // Roughness of the layer
};


/* The layer structure has to be created using 'layers' uniform variable. You
 * have to set 'layers[id].n1' in the main HTML file.
 */
#define NUM_LAYERS 3
uniform BsdfLayer layers[NUM_LAYERS];


/* Helper function to select a given layer by index 'start' since it is
 * not possible to use a non constant index to layers[index].
 *
 * If the max number of layer is reached, return air's IOR and a planar
 * geometry for the microfacets.
 */
BsdfLayer GetLayer(int start) {
    for(int i=0; i<NUM_LAYERS; ++i) {
        if(start == i) {
            return layers[i];
        }
    }

    BsdfLayer layer;
    layer.n = 1.0;
    layer.k = 0.0;
    layer.a = 0.0;
    return layer;
}



#ifdef RANDOM_SHADER
///////////////////////////////////////////////////////////////////////////////
//                                                                           //
//                          Random Walk in the Layers                        //
//                                                                           //
///////////////////////////////////////////////////////////////////////////////


/* Sampling routines when interacting with the layer from the top or from the
 * bottom (incoming direction of light).
 *
 *    1/ Sample a microfacet using the GGX distribution.
 *    2/ Use the Fresnel to test for transmission or reflexion.
 *    3/ Update sampling weight.
 */
void InteractWithLayer(in BsdfLayer layer1, in BsdfLayer layer2,
                       in  vec3 wi, in  vec3 random,
                       out vec3 wo, out vec3 weight) {

  // Sample a microfacet
  vec3 h; float pdf;
  SamplingUniformHemisphere(random.xy, h, pdf);
  if(dot(wo, h) < 0.0) { return; }

  // Generate the reflected direction
  wo = reflect(wi, h);

  // Sample Fresnel
  float f = FresnelUnpolarized(dot(wi, h), layer1.n, layer2.n, layer2.k);

  // Update the weight
  weight = vec3(1.0, 1.0, 1.0) * f * GGX(wi, wo, vec3(0.0,0.0,1.0), layer2.a) / pdf;
}
#endif