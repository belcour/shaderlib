#version 300 es
#line 2
precision highp float;

// Inputs
in vec3 aVertexPosition;

// Outputs
out vec2 vPos;

void main(void) {
    vPos = aVertexPosition.xy;
    gl_Position = vec4(aVertexPosition, 1.0);
}