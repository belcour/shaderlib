#line 1
precision highp float;

#include "shaders/library/common.shader"
#line 5

// Uniform variables
uniform sampler2D u_FramebufferSampler;
uniform int       u_PassNumber; // Pass number for the progressive renderer

void main(void) {
    vec4 color = texture2D(u_FramebufferSampler, 0.5*(vPos+1.0));
    gl_FragColor = color / float(u_PassNumber);
}