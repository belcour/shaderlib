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
  float a;    // Roughness of the layer
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
    layer.k = vec3(0.0, 0.0, 0.0);
    layer.a = 0.0;
    return layer;
}