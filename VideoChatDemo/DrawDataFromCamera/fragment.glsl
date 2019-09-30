precision mediump float;

uniform sampler2D SamplerY;
uniform sampler2D SamplerU;
uniform sampler2D SamplerV;
varying highp vec2 coordinate;

//varying highp vec2 fragColor;

const vec3 delyuv = vec3(-0.0/255.0,    -128.0/255.0,   -128.0/255.0);

//yuv to rgb
const vec3 matYUVRGB1 = vec3(1.0,   0.0,      1.402);
const vec3 matYUVRGB2 = vec3(1.0,   -0.344,   -0.714);
const vec3 matYUVRGB3 = vec3(1.0,   1.772,    0.0);

void main()
{
//    vec3 CurResult;
    highp vec3 yuv;
//
    yuv.x = texture2D(SamplerY, coordinate).r;
//    yuv.x = texture2D(SamplerU, coordinate).r;
//    yuv.z = texture2D(SamplerV, coordinate).r;

//    yuv += delyuv;

//    CurResult.x = dot(yuv,matYUVRGB1);
//    CurResult.y = dot(yuv,matYUVRGB2);
//    CurResult.z = dot(yuv,matYUVRGB3);

//    gl_FragColor = vec4(CurResult.rgb, 1);
    gl_FragColor = texture2D(SamplerY, coordinate);
}
