#ifndef MAPPING_SHADER
#define MAPPING_SHADER
#line 2

///////////////////////////////////////////////////////////////////////////////
//                                                                           //
//                             LatLong Mapping                               //
//                                                                           //
///////////////////////////////////////////////////////////////////////////////

/* Convert a direction on the unit sphere to its 2D position in the
 * LatLong parametrization.
 */
vec2 Sphere_to_LatLong(vec3 w) {
    vec2 uv;
    uv.y = 0.5*w.y + 0.5;
    uv.x = degrees(atan(w.z, w.x))/360.0 + 0.5;
    return clamp(uv, vec2(0.0, 0.0), vec2(1.0, 1.0));
}


/* Blend a dual Paraboloid map where to textures are defined usign
 * the forward and backward mapping respectively. The lookup of
 * both textures are scaled with respect to the dot product with
 * the direction of least distortion.
 */
vec3 Fetch_LatLong(in vec3 direction, in sampler2D latlong) {
    vec2 uv = Sphere_to_LatLong(direction);
    return texture(latlong, uv).xyz;
}


///////////////////////////////////////////////////////////////////////////////
//                                                                           //
//                           Paraboloid Mapping                              //
//                                                                           //
///////////////////////////////////////////////////////////////////////////////

/* Convert a direction on the unit sphere to its 2D position in the
 * paraboloid map [0,1]^2 that is looking the unit sphere forward.
 * 
 * Each point of the paraboloid map defines a normal on the unit
 * sphere that is used to reflect an input vector (here [0,0,1]) to
 * obtain the outgoing direction 'w'.
 */
vec2 Sphere_to_Paraboloid_ForwardZ(in vec3 w) {
    vec3 m = vec3(0,0,1);
    vec3 n = normalize((w + m));
    return 0.5*vec2(n.x+1.0, n.y+1.0);
}

/* Convert a direction on the unit sphere to its 2D position in the
 * paraboloid map [0,1]^2 that is looking the unit sphere forward.
 * 
 * Each point of the paraboloid map defines a normal on the unit
 * sphere that is used to reflect an input vector (here [0,0,-1]) to
 * obtain the outgoing direction 'w'.
 *
 * If the uv is outside of the unit disc, we return the [0,0,0]
 * position.
 */
vec3 Paraboloid_ForwardZ_to_Sphere(in vec2 uv) {
    float l = length(uv);
    if(l > 1.0) {
        return vec3(0,0,0);
    }
    
    vec3 m = vec3(0,0,1);
    vec3 n = vec3(uv.x, uv.y, -sqrt(1.0 - l*l));
    return reflect(m, n);
}


/* Convert a direction on the unit sphere to its 2D position in the
 * paraboloid map [0,1]^2 that is looking the unit sphere forward.
 * 
 * Each point of the paraboloid map defines a normal on the unit
 * sphere that is used to reflect an input vector (here [0,0,-1]) to
 * obtain the outgoing direction 'w'.
 */
vec2 Sphere_to_Paraboloid_BackwardZ(in vec3 w) {
    vec3 m = vec3(0,0,-1);
    vec3 n = normalize(w + m);
    return 0.5*vec2(n.x+1.0, n.y+1.0);
}

/* Convert a direction on the unit sphere to its 2D position in the
 * paraboloid map [0,1]^2 that is looking the unit sphere forward.
 * 
 * Each point of the paraboloid map defines a normal on the unit
 * sphere that is used to reflect an input vector (here [0,0,-1]) to
 * obtain the outgoing direction 'w'.
 *
 * If the uv is outside of the unit disc, we return the [0,0,0]
 * position.
 */
vec3 Paraboloid_BackwardZ_to_Sphere(in vec2 uv) {
    float l = length(uv);
    if(l > 1.0) {
        return vec3(0,0,0);
    }

    vec3 m = vec3(0,0,-1);
    vec3 n = vec3(uv.x, uv.y, sqrt(1.0 - l*l));
    return reflect(m, n);
}

/* Blend a dual Paraboloid map where to textures are defined usign
 * the forward and backward mapping respectively. The lookup of
 * both textures are scaled with respect to the dot product with
 * the direction of least distortion.
 */
vec3 Fetch_Dual_ParaboloidMap(in vec3 direction, in sampler2D paraboloidForward, in sampler2D paraboloidBackward) {

    vec3 vIBL = vec3(0);
    vec2 uv;

    // Accumulate the forward direction
    uv = Sphere_to_Paraboloid_ForwardZ(direction);
    vIBL += (0.5*direction.z + 0.5)*texture(paraboloidForward, uv).rgb;

    // Accumulate the backward direction
    uv = Sphere_to_Paraboloid_BackwardZ(direction);
    vIBL += (0.5 - 0.5*direction.z)*texture(paraboloidBackward, uv).rgb;
    
    return vIBL;
}
vec3 Fetch_Dual_ParaboloidMapLod(in vec3 direction,
                                 in sampler2D paraboloidForward,
                                 in sampler2D paraboloidBackward,
                                 in float lod = 0.0f) {

    vec3 vIBL = vec3(0);
    vec2 uv;

    // Accumulate the forward direction
    uv = Sphere_to_Paraboloid_ForwardZ(direction);
    vIBL += (0.5*direction.z + 0.5)*texture(paraboloidForward, uv, lod).rgb;

    // Accumulate the backward direction
    uv = Sphere_to_Paraboloid_BackwardZ(direction);
    vIBL += (0.5 - 0.5*direction.z)*texture(paraboloidBackward, uv, lod).rgb;
    
    return vIBL;
}


#endif // MAPPING_SHADER