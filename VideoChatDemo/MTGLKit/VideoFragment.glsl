precision mediump float;

uniform sampler2D SamplerY;
uniform sampler2D SamplerU;
uniform sampler2D SamplerV;
varying vec2 TextureCoordsVarying;

const vec3 delyuv = vec3(-0.0/255.0,-128.0/255.0,-128.0/255.0);

//yuv to rgb
const vec3 matYUVRGB1 = vec3(1.0,0.0,1.402);
const vec3 matYUVRGB2 = vec3(1.0,-0.344,-0.714);
const vec3 matYUVRGB3 = vec3(1.0,1.772,0.0);

void main () {
    float x1 = TextureCoordsVarying.x;
    float y1 = TextureCoordsVarying.y;
    vec2 distortCoord = vec2(x1,y1);
    
    highp vec3 yuv;
    yuv.x = texture2D(SamplerY, distortCoord).r;
    yuv.y = texture2D(SamplerU, distortCoord).r;
    yuv.z = texture2D(SamplerV, distortCoord).r;
    
    vec3 CurResult;
    yuv += delyuv;
    CurResult.x = dot(yuv,matYUVRGB1);
    CurResult.y = dot(yuv,matYUVRGB2);
    CurResult.z = dot(yuv,matYUVRGB3);
    
    gl_FragColor = vec4(CurResult.rgb, 1);
}
