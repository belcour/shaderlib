#version 300 es
#line 2
precision highp float;

#include "shaders/library/common.shader"
#line 5

// Uniform variables
uniform sampler2D u_FramebufferSampler;
uniform int       u_PassNumber; // Pass number for the progressive renderer

// Inputs
in vec2 vPos;

// Ouputs
out vec4 out_FragColor;

void main(void) {
    vec4 color = texture(u_FramebufferSampler, 0.5*(vPos+1.0));
    out_FragColor = color / float(u_PassNumber);
}