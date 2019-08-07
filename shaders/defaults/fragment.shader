#version 300 es
#line 1
precision highp float;

// Inputs
in vec2 vPos;

// Outputs
out vec4 FragmentColor;

void main(void) {
    FragmentColor = vec4(vPos.xy, 0.0, 1.0);
}
