attribute vec4 Position;
attribute vec2 TextureCoords;
varying vec2 TextureCoordsVarying;
uniform mat4 modelTransform;

void main (void){
    gl_Position = modelTransform * Position;
    TextureCoordsVarying = TextureCoords;
}
