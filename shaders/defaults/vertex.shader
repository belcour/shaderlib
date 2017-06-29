#line 1
precision highp float;

#include "shaders/library/common.shader"
#line 5

attribute vec3 aVertexPosition;

void main(void) {
    vPos = aVertexPosition.xy;
    gl_Position = vec4(aVertexPosition, 1.0);
}