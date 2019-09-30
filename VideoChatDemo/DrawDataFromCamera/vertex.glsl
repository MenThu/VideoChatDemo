precision mediump float;

attribute vec4 position;
attribute mediump vec2 textureCoordinate;
uniform mat4 modelTransform;

varying vec2 coordinate;
//varying vec3 fragColor;

void main()
{
    gl_Position = modelTransform * position;
//    gl_Position = position;
    coordinate = textureCoordinate;
}
