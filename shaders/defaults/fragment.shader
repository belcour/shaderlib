#line 1
precision highp float;

#include "../shaders/library/common.shader"
#line 5

// Pass number for the progressive renderer
uniform int u_PassNumber;

void main(void) {
    gl_FragColor = vec4(vPos.xy, 0.0, 1.0);
}
