#version 140

uniform sampler2D NoiseTexture;
uniform vec4 screenInfo;
uniform vec4 textureInfo;
uniform vec4 rectangleInfo;
uniform vec4 scalingInfo;
uniform vec4 colorInfo;
uniform vec4 worldOffset;
uniform vec4 paramInfo;
uniform vec4 cameraInfo;

in vec4 vColor;
in vec2 vUV1;
in float vDepth;

#include "util/math"

//fog noise
float fogNoise( in vec2 fcoord )
{
    // 'scaling' scales the fog texture(s)
    float scaling = 0.0008;
    vec2 uv = vec2(fcoord.x*screenInfo.x*scaling, fcoord.y*screenInfo.y*scaling) + worldOffset.xy*scaling;
    uv *=0.25;

    // 'scalingMod' affects movement speed of fog
    float scalingMod = 0.00035;

    vec2 uv2 = vec2(uv.x+(scalingInfo.x * scalingMod), uv.y+(scalingInfo.y * scalingMod));

    float value = 0.0;
    float amplitude = 0.5;
    float ampTot = amplitude;

    vec4 tex1 = texture2D(NoiseTexture, uv2);
    value += amplitude * tex1.r;
    amplitude *= 0.5;
    ampTot += amplitude;

    scalingMod = 0.00070;
    uv2 = vec2(uv.x+(scalingInfo.x * scalingMod), uv.y+(scalingInfo.y * scalingMod));
    tex1 = texture2D(NoiseTexture, uv2);
    value += amplitude * tex1.g;
    amplitude *= 0.5;
    ampTot += amplitude;

    scalingMod = 0.00040; //0.00140;
    uv2 = vec2(uv.x+(scalingInfo.x * scalingMod), uv.y+(scalingInfo.y * scalingMod));
    //tex1 = texture2D(NoiseTexture, uv2);
    //value += amplitude * tex1.b;
    //amplitude *= 0.5;
    //ampTot += amplitude;

    uv2 *= 3.0;
    tex1 = texture2D(NoiseTexture, uv2);
    value += amplitude * tex1.b;

    value = 0.5 + (0.50*(value/ampTot));//0.3 + (0.70*(value/ampTot));fddlggglffffffs
    return clamp(value,0.0,1.0);
}
//----------------------------------------------------------------------------------------

// screenInfo, textureInfo, rectangleInfo, paramInfo
float alphaBorders(in vec2 coord, in vec2 fcoord) {
    float borderAlpha = 1.0;

    //------------
    float scaling = 0.00035;
    vec2 uv = vec2(fcoord.x*screenInfo.x*scaling, fcoord.y*screenInfo.y*scaling) + worldOffset.xy*scaling;

    //apply row based offsets
    uv.x += cameraInfo.w;
    uv.y += cameraInfo.w;

    vec4 tex1 = texture2D(NoiseTexture, uv);
    float n = tex1.a;

    tex1 = texture2D(NoiseTexture, uv+0.5);
    float n2 = tex1.a;
    //------------
    //Applying irregular alpha fading borders at top-bottom and linear fading at left-right of the rectangle.
    vec2 recCoord = rectangleInfo.xy / screenInfo.xy;
    vec2 recDim = vec2(rectangleInfo.z,rectangleInfo.w) / screenInfo.xy;
    recCoord.y = 1.0 - recCoord.y;

    vec2 p = vec2(coord);
    p.y = (recCoord.y-coord.y)/recDim.y;
    p.x = (coord.x-recCoord.x)/recDim.x;

    //top
    float height = paramInfo.x-((paramInfo.x*0.5)*n);
    borderAlpha = min(p.y/height, 1.0);
    //bottom
    height = paramInfo.y-((paramInfo.y*0.5)*n2);
    borderAlpha = min( max((1.0-p.y)/height, 0) , borderAlpha);

    float sidesWidth = (32.0*textureInfo.w)/screenInfo.x;
    sidesWidth /= recDim.x;
    //right
    borderAlpha = min(max((1.0-p.x)/sidesWidth, 0), borderAlpha);
    //left
    borderAlpha = min(p.x/sidesWidth, borderAlpha);

    //------------
    //A final noise texture applied to the areas that have less than 1.0 alpha resulting from above calcs.
    scaling = 0.00085;
    uv = vec2(fcoord.x*screenInfo.x*scaling, fcoord.y*screenInfo.y*scaling) + worldOffset.xy*scaling;

    uv.x += cameraInfo.w;
    uv.y += cameraInfo.w;

    tex1 = texture2D(NoiseTexture, uv);
    n = tex1.a;
    //------------
    borderAlpha += (1.0-borderAlpha) * (n*borderAlpha);
    borderAlpha *= borderAlpha;


    borderAlpha = clamp(borderAlpha,0.0,1.0);

    return borderAlpha;
}

// screenInfo, worldOffset
float alphaCircle(in float alpha, in float rad, in vec2 coord, in float zoom) {
    vec2 center = vec2(0.5, 0.5);
    //right click view in distance mod:
    center.x -= (worldOffset.z)/screenInfo.x;
    center.y += (worldOffset.w)/screenInfo.y;
    float dist = distance(coord.xy, center);
    float baseAlpha = smoothstep(0.01,0.99,dist*rad*zoom);
    return alpha + ((1.0-alpha)*baseAlpha);
}

// screenInfo, textureInfo, scalingInfo, colorInfo, paramInfo
void main() {
    float zoom = screenInfo.z;
    vec2 coord = (vec2(gl_FragCoord.x-cameraInfo.x, gl_FragCoord.y-cameraInfo.y) * zoom) / screenInfo.xy;
    float alpha = alphaCircle(paramInfo.z, paramInfo.w, coord, zoom); //orig for not in car was: 0.30, 2.25, coord, zoom

    vec2 fcoord = vec2(gl_FragCoord.x/(screenInfo.x/zoom), 1.0 - gl_FragCoord.y/(screenInfo.y/zoom));
    float layerAlpha = screenInfo.w; //adjusted alpha for layer>0;

    float borderAlpha = alphaBorders(coord, fcoord);

    if(textureInfo.x>=1.0) { //NOTE: DEBUG0f
        float alp = textureInfo.z * alpha * borderAlpha * layerAlpha;
        alp = clamp(alp, 0.0, 1.0);
        gl_FragDepth = vDepth;
        gl_FragColor = vec4( 1.0, 1.0, 0.0, alp );
        return;
    }

    float n = fogNoise(fcoord);

    float alp = max(0.0,(n-0.50)/0.50); //max(0.0,(n-0.40)/0.60);fl;f

    alp *= textureInfo.z * alpha * borderAlpha * layerAlpha;
    alp = clamp(alp, 0.0, 1.0);

    gl_FragDepth = vDepth;

    gl_FragColor = vec4(n*colorInfo.r, n*colorInfo.g, n*colorInfo.b, alp);
}
