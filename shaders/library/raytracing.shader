#define RAYTRACING_SHADER

#ifndef COMMON_SHADER
  #error Missing common.shader include in main shader
#endif

#line 7

void intersectTriangle(vec3 p, vec3 d, vec3 A, vec3 B, vec3 C, out vec3 r) {
    vec3 E1 = B-A;
    vec3 E2 = C-A;
    vec3 T  = p-A;
    vec3 P  = cross(d, E2);
    vec3 Q  = cross(T, E1);
    
    r  = vec3(dot(Q, E2), dot(P, T), dot(Q, d)) / dot(P, E1);
} 

bool intersectTriangle(vec3 p, vec3 d, vec3 A, vec3 B, vec3 C) {
    vec3 r;
    intersectTriangle(p, d, A, B, C, r);
    return r.x > 0.0 &&
           r.y > 0.0 && r.z > 0.0 && r.y+r.z < 1.0;
} 