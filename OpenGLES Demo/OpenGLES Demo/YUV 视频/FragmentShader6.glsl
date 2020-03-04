varying highp vec2 texCoordVarying;
precision mediump float;

uniform sampler2D SamplerY;
uniform sampler2D SamplerUV;

void main(){
    
    highp vec2 lPos;
    highp vec2 rPos;
    mediump vec3 lYUV;
    mediump vec3 rYUV;
    lowp vec3 lRGB;
    lowp vec3 rRGB;
    mediump mat3 convert = mat3(1.164,  1.164,  1.164,
                                0.0,    -0.213, 2.112,
                                1.793,  -0.533, 0.0);
    
    // - 左右位置
    lPos = vec2(texCoordVarying.x/2.0,texCoordVarying.y);
    rPos = vec2(texCoordVarying.x/2.0+0.5,texCoordVarying.y);
    
    // - 左边的的 rgb
    lYUV.x = (texture2D(SamplerY, lPos).r);// - (16.0/255.0));
    lYUV.yz = (texture2D(SamplerUV, lPos).ra - vec2(0.5, 0.5));
    lRGB = convert * lYUV;
    
    // - 右边的 rgb
    rYUV.x = (texture2D(SamplerY, rPos).r);// - (16.0/255.0));
    rYUV.yz = (texture2D(SamplerUV, rPos).ra - vec2(0.5, 0.5));
    rRGB = convert * rYUV;
    
    gl_FragColor = vec4(rRGB, lRGB.r);
}
