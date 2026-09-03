#version 330
uniform sampler2D DIFFUSE;

uniform float bgl_RenderedTextureWidth; //scene sampler width
uniform float bgl_RenderedTextureHeight; //scene sampler height
uniform float timer;
uniform float timerWrap;
uniform vec2 TextureSize;
uniform float Zoom;

uniform vec3 Light;
uniform float LightIntensity;
uniform float NightValue; //replaced timeofday.
uniform float Exterior;
uniform float NightVisionGoggles;
uniform float DesaturationVal;
uniform vec4 SearchMode;
uniform vec4 ScreenInfo;
uniform vec4 ParamInfo;
uniform vec4 VarInfo;

uniform float DrunkFactor;
uniform float BlurFactor;

in vec4 vColor;
in vec2 vUV;

float width = bgl_RenderedTextureWidth;
float height = bgl_RenderedTextureHeight;

const vec3 AvgLumin = vec3(0.4, 0.4, 0.4);
const float permTexUnit = 1.0/256.0;		// Perm texture texel-size
const float permTexUnitHalf = 0.5/256.0;	// Half perm texture texel-size

const float grainamount = 0.0003; //grain amount
bool colored = false; //colored noise?
float coloramount = 1.0;
float grainsize = 1.0; //grain particle size (1.5 - 2.5)
float lumamount = 1.0; //

//nightvision:
float contrast2 = 0.5;
const vec3 lumvec = vec3(0.30, 0.59, 0.11);
float intensityAdjust = 1.3;

//blur options:
const float blur_pi = 6.28318530718; 	// Pi times 2
const float blur_directions = 16.0; 	// def. 16.0 - higher number is more slow
const float blur_quality = 3.0; 		// def. 3.0 - higher number is more slow
const float blur_size = 12.0; 			// def. 8.0

#include "util/math"

//a random texture generator, but you can also use a pre-computed perturbation texture
vec4 rnm(in vec2 tc)
{
    float noise =  sin(dot(tc + vec2(timer,timer),vec2(12.9898,78.233))) * 43758.5453;

	float noiseR =  fract(noise)*2.0-1.0;
	float noiseG =  fract(noise*1.2154)*2.0-1.0;
	float noiseB =  fract(noise*1.3453)*2.0-1.0;
	float noiseA =  fract(noise*1.3647)*2.0-1.0;

	return vec4(noiseR,noiseG,noiseB,noiseA);
}

float fade(in float t)
 {
	return t*t*t*(t*(t*6.0-15.0)+10.0);
}

float pnoise3D(in vec3 p)
{
	vec3 pi = permTexUnit*floor(p)+permTexUnitHalf; // Integer part, scaled so +1 moves permTexUnit texel
	// and offset 1/2 texel to sample texel centers
	vec3 pf = fract(p);     // Fractional part for interpolation

	// Noise contributions from (x=0, y=0), z=0 and z=1
	float perm00 = rnm(pi.xy).a ;
	vec3  grad000 = rnm(vec2(perm00, pi.z)).rgb * 4.0 - 1.0;
	float n000 = dot(grad000, pf);
	vec3  grad001 = rnm(vec2(perm00, pi.z + permTexUnit)).rgb * 4.0 - 1.0;
	float n001 = dot(grad001, pf - vec3(0.0, 0.0, 1.0));

	// Noise contributions from (x=0, y=1), z=0 and z=1
	float perm01 = rnm(pi.xy + vec2(0.0, permTexUnit)).a ;
	vec3  grad010 = rnm(vec2(perm01, pi.z)).rgb * 4.0 - 1.0;
	float n010 = dot(grad010, pf - vec3(0.0, 1.0, 0.0));
	vec3  grad011 = rnm(vec2(perm01, pi.z + permTexUnit)).rgb * 4.0 - 1.0;
	float n011 = dot(grad011, pf - vec3(0.0, 1.0, 1.0));

	// Noise contributions from (x=1, y=0), z=0 and z=1
	float perm10 = rnm(pi.xy + vec2(permTexUnit, 0.0)).a ;
	vec3  grad100 = rnm(vec2(perm10, pi.z)).rgb * 4.0 - 1.0;
	float n100 = dot(grad100, pf - vec3(1.0, 0.0, 0.0));
	vec3  grad101 = rnm(vec2(perm10, pi.z + permTexUnit)).rgb * 4.0 - 1.0;
	float n101 = dot(grad101, pf - vec3(1.0, 0.0, 1.0));

	// Noise contributions from (x=1, y=1), z=0 and z=1
	float perm11 = rnm(pi.xy + vec2(permTexUnit, permTexUnit)).a ;
	vec3  grad110 = rnm(vec2(perm11, pi.z)).rgb * 4.0 - 1.0;
	float n110 = dot(grad110, pf - vec3(1.0, 1.0, 0.0));
	vec3  grad111 = rnm(vec2(perm11, pi.z + permTexUnit)).rgb * 4.0 - 1.0;
	float n111 = dot(grad111, pf - vec3(1.0, 1.0, 1.0));

	// Blend contributions along x
	vec4 n_x = mix(vec4(n000, n001, n010, n011), vec4(n100, n101, n110, n111), fade(pf.x));

	// Blend contributions along y
	vec2 n_xy = mix(n_x.xy, n_x.zw, fade(pf.y));

	// Blend contributions along z
	float n_xyz = mix(n_xy.x, n_xy.y, fade(pf.z));

	// We're done, return the final noise value.
	return n_xyz;
}

//2d coordinate orientation thing
vec2 coordRot(in vec2 tc, in float angle)
{
	float aspect = width/height;
	float rotX = ((tc.x*2.0-1.0)*aspect*cos(angle)) - ((tc.y*2.0-1.0)*sin(angle));
	float rotY = ((tc.y*2.0-1.0)*cos(angle)) + ((tc.x*2.0-1.0)*aspect*sin(angle));
	rotX = ((rotX/aspect)*0.5+0.5);
	rotY = rotY*0.5+0.5;
	return vec2(rotX,rotY);
}

vec3 contrast(vec3 color, float amount)
{
    color.r = color.r - AvgLumin.r;
    color.g = color.g - AvgLumin.g;
    color.b = color.b - AvgLumin.b;
    color = color * amount;

    color.r = color.r + AvgLumin.r;
    color.g = color.g + AvgLumin.g;
    color.b = color.b + AvgLumin.b;

    return color;
}

// http://www.java-gaming.org/index.php?topic=35123.0
// GL_LINEAR filtering required

vec4 cubic(float v)
{
    vec4 n = vec4(1.0, 2.0, 3.0, 4.0) - v;
    vec4 s = n * n * n;
    float x = s.x;
    float y = s.y - 4.0 * s.x;
    float z = s.z - 4.0 * s.y + 6.0 * s.x;
    float w = 6.0 - x - y - z;
    return vec4(x, y, z, w) * (1.0/6.0);
}

vec4 textureBicubic(sampler2D sampler, vec2 texCoords)
{
//	vec2 texSize = textureSize(sampler, 0);
	vec2 texSize = TextureSize;
	vec2 invTexSize = 1.0 / texSize;

	texCoords = texCoords * texSize - 0.5;

	vec2 fxy = fract(texCoords);
	texCoords -= fxy;

	vec4 xcubic = cubic(fxy.x);
	vec4 ycubic = cubic(fxy.y);

	vec4 c = texCoords.xxyy + vec2(-0.5, +1.5).xyxy;

	vec4 s = vec4(xcubic.xz + xcubic.yw, ycubic.xz + ycubic.yw);
	vec4 offset = c + vec4(xcubic.yw, ycubic.yw) / s;

	offset *= invTexSize.xxyy;

	vec4 sample0 = texture2D(sampler, offset.xz);
	vec4 sample1 = texture2D(sampler, offset.yz);
	vec4 sample2 = texture2D(sampler, offset.xw);
	vec4 sample3 = texture2D(sampler, offset.yw);

	float sx = s.x / (s.x + s.y);
	float sy = s.z / (s.z + s.w);

	return mix(
		mix(sample3, sample2, sx),
		mix(sample1, sample0, sx),
		sy);
}

float blendOverlay(float base, float blend) {
	return base<0.5?(2.0*base*blend):(1.0-2.0*(1.0-base)*(1.0-blend));
}

vec3 blendOverlay(vec3 base, vec3 blend) {
	return vec3(blendOverlay(base.r,blend.r),blendOverlay(base.g,blend.g),blendOverlay(base.b,blend.b));
}

vec3 blendOverlay(vec3 base, vec3 blend, float opacity) {
	return (blendOverlay(base, blend) * opacity + base * (1.0 - opacity));
}

//blur outer regions SearchMode
vec3 blur(in vec3 col, in float alpha) {
	vec2 rad = blur_size/ScreenInfo.xy;

	vec2 uv = vUV.st;
	vec3 c = texture2D(DIFFUSE, uv).rgb;

	for( float d=0.0; d<blur_pi; d+=blur_pi/blur_directions)
	{
		for(float i=1.0/blur_quality; i<=1.01; i+=1.0/blur_quality)
		{
			c += texture2D( DIFFUSE, uv+vec2(cos(d),sin(d))*rad*i).rgb;
		}
	}

	c /= (blur_quality * (blur_directions + 1));
	c = clamp(c,0.0,1.0);
	return (col*(1.0-alpha))+(c*alpha);
}

//alpha value for SearchMode circle
float searchCircle(in float rad, in vec2 coord, in float zoom) {
	vec2 center = vec2(0.5, 0.5);
	//right click view in distance mod:
	center.x -= (ScreenInfo.z)/ScreenInfo.x;
	center.y += (ScreenInfo.w)/ScreenInfo.y;
	float dist = distance(coord.xy, center);
	dist *= ScreenInfo.x;
	//ParamInfo.y == TileWidth (64 or 32 depending on Core.TileSize), ParamInfo.z == the radius of transition gradient (already in correct pixel amount)
	//float baseAlpha = smoothstep( max(0.0,(rad*ParamInfo.y)-ParamInfo.z), (rad*ParamInfo.y)+ParamInfo.z, dist);
	return smoothstep( max(0.0,(rad*ParamInfo.y)-ParamInfo.z), (rad*ParamInfo.y)+ParamInfo.z, dist); //clamp(alpha*baseAlpha, 0.0, ParamInfo.w); //alpha + ((1.0-alpha)*baseAlpha);assd
}

//SearchMode.xy = alpha, radius, SearchMode.zw = OffscreenLeft and Top, ParamInfo.x = zoom value
//ScreenInfo.xy = screenwidth & height, ScreenInfo.zw = Rightclickoff X & Y
vec3 screenWorld(in vec3 pixel, in vec3 noise) {
	float circleAlpha = 0.0;
	vec3 Diffuse = vec3(1,1,1);
	if(VarInfo.x==0.0) {
		Diffuse = desaturate(pixel, DesaturationVal);
	} else {
		vec2 coord = (vec2(gl_FragCoord.x-SearchMode.z, gl_FragCoord.y-SearchMode.w+(56.0/ParamInfo.x)) * ParamInfo.x) / ScreenInfo.xy;
		circleAlpha = searchCircle(SearchMode.y, coord, ParamInfo.x);
		Diffuse = blur(pixel, circleAlpha*SearchMode.x);
		Diffuse = desaturate(Diffuse, max(DesaturationVal,circleAlpha*ParamInfo.w));
		Diffuse *= (1.0-(VarInfo.y*circleAlpha));
	}

	//Diffuse = blendOverlay(Diffuse,Light,LightIntensity*Exterior);
	Diffuse = clamp(Diffuse, 0.0, 1.0);
	float intensity = (0.299 * Diffuse.r) + (0.587 * Diffuse.g) + (0.114 * Diffuse.b);

	vec3 col = contrast(desaturate(Diffuse, 0.1), 1.2);
	float invintensity = 1.0 - intensity;
	invintensity = invintensity * invintensity;

	//col = col+((noise*(grainamount+((0.010-grainamount)*circleAlpha))) * (invintensity * 5.0));
	col = col+((noise*grainamount) * (invintensity * 5.0));

	return col;
}

vec3 screenNightvision(in vec3 pixel, in vec3 noise) {
	vec3 Diffuse = pixel;
	float intensity = (0.299 * Diffuse.r) + (0.587 * Diffuse.g) + (0.114 * Diffuse.b);

	Diffuse = mix(Diffuse, vec3(intensity), (NightValue*0.8) * (1.0 - intensity));
	Diffuse = ((1.0 - NightValue) * Diffuse) + (NightValue * Diffuse*Diffuse) * 1.5;

	Diffuse.rg -= NightValue * 0.25 * (1.0 - intensity);
	Diffuse.b +=  (NightValue * 0.25 * (1.0 - intensity));

	vec3 col = contrast(desaturate(Diffuse, 0.1), 1.2);
	float invintensity = 1.0 - intensity;
	invintensity = invintensity * invintensity;

	col.rg+=0.45;
	col = col*1.9+((noise*0.015) * (invintensity * 5.0));//col = col+((noise*grainamount) * (invintensity * 5.0));

	float intensity2 = dot(lumvec,col) ;

	// adjust contrast - 0...1
	intensity2 = clamp(contrast2 * (intensity2 - 0.5) + 0.5, 0.0, 1.0);

	// final green result 0...1
	float green = clamp(intensity2 / 0.59, 0.0, 1.0) * intensityAdjust;

	// vision color - getting green max
	vec3 visionColor = vec3(0.0,green,0.0); //vec3(0,green,0);//vec3(0.1, 0.95, 0.2);

	// final color
	col = col * visionColor;

	return col;
}

//alpha value for drunk effect
float drunkBoundaries(in vec2 coord) {
	vec2 center = vec2(0.5, 0.5);

	//right click view in distance mod:
	center.x -= (ScreenInfo.z)/ScreenInfo.x;
	center.y += (ScreenInfo.w)/ScreenInfo.y;

	float distX = distance(coord.x - (0.5 - center.x), center.x);
	float distY = distance(coord.y - (0.5 - center.y), center.y);

	float aXret = 1.0;
	float aYret = 1.0;

	aXret = (distX) / 0.5;
	aYret = (distY) / 0.5;

	return 1 - max(aXret, aYret);
}

float drunkCircle(in vec2 coord) {
	vec2 center = vec2(0.5, 0.5);

	//right click view in distance mod:
	center.x -= (ScreenInfo.z)/ScreenInfo.x;
	center.y += (ScreenInfo.w)/ScreenInfo.y;
	float dist = distance(coord.xy, center);
	dist *= ScreenInfo.x;

	//hardcoded values so it's not relying on searchmode
	float gradientWidth = 20;
	float gradientWidthAlpha = (gradientWidth * 64.0) / 2.0;

	return smoothstep( max(0.0,(gradientWidth)-gradientWidthAlpha), (gradientWidth)+gradientWidthAlpha, dist);
}

vec3 drunkenDeform(in vec3 pixel, in vec3 noise) {
	vec3 col = clamp(pixel, 0.0, 1.0);

	vec2 UV =  vUV.st;

//		vec2 coord = (vec2(gl_FragCoord.x, gl_FragCoord.y+(56.0/ParamInfo.x)) * ParamInfo.x) / ScreenInfo.xy;
	vec2 coord = (vec2(gl_FragCoord.x-SearchMode.z, gl_FragCoord.y-SearchMode.w) * ParamInfo.x) / ScreenInfo.xy;

	float circleAlpha = drunkCircle(coord);
	float drunkAlpha = drunkBoundaries(coord);
	float drunkAlphaB = drunkAlpha * circleAlpha;

	float jiggle1 = 7.3;
	float jiggle2 = 13.3;
	float jiggleMag = 0.005 * DrunkFactor;

	vec2 coord2 = UV + ((jiggleMag) * vec2(cos(timer/(timerWrap * jiggle1)), sin(timer/(timerWrap * jiggle2))) / ParamInfo.x);
	vec2 coord3 = UV + ((jiggleMag) * vec2(cos(timer/(timerWrap * jiggle2)), sin(timer/(timerWrap * jiggle1))) / ParamInfo.x);

	vec3 pixel2 = textureBicubic(DIFFUSE, coord2).xyz;
	vec3 pixel3 = textureBicubic(DIFFUSE, coord3).xyz;

	vec3 pixelBlur = blur(col, DrunkFactor);

	col = mix(col, pixel2, drunkAlphaB);
	col = mix(col, pixel3, drunkAlphaB);
	col = mix(col, pixelBlur, (1-drunkAlpha));

	col = clamp(col, 0, 1);

	return col;
}

float blurCircle(in vec2 coord, in float rad) {
	vec2 center = vec2(0.5, 0.5);

	//right click view in distance mod:
	center.x -= (ScreenInfo.z)/ScreenInfo.x;
	center.y += (ScreenInfo.w)/ScreenInfo.y;
	float dist = distance(coord.xy, center);
	dist *= ScreenInfo.x;


	//hardcoded values so it's not relying on searchmode

	float radiusPixelW = (rad * 64.0) / 2.0;
	float gradPixelW = (radiusPixelW * 3.0) * ParamInfo.x;

	float gradientWidth = gradPixelW * (rad / 32.0 / ParamInfo.x);
	float gradientWidthAlpha = (gradientWidth * 64.0) / 2.0;

	return smoothstep( max(0.0,(gradientWidth)-gradientWidthAlpha), (gradientWidth)+gradientWidthAlpha, dist);
}

// my glasses!
vec3 screenBlur(in vec3 pixel, in bool shortSight) {
	vec3 col = clamp(pixel, 0.0, 1.0);

	vec2 coord = (vec2(gl_FragCoord.x-SearchMode.z, gl_FragCoord.y-SearchMode.w) * ParamInfo.x) / ScreenInfo.xy;

	float circleAlpha = blurCircle(coord, 3);

	col = blur(col, (BlurFactor) * circleAlpha);

	return col;
}

void main()
{
	vec2 UV =  vUV.st;

	vec3 rotOffset = vec3(1.425,3.892,5.835); //rotation offset values
	vec2 rotCoordsR = coordRot(UV, timer + rotOffset.x);
	vec3 noise = vec3(pnoise3D(vec3(rotCoordsR*vec2(width/grainsize,height/grainsize),0.0)));

	//vec3 pixel = (Zoom > 0.0) ? textureBicubic(DIFFUSE, vUV.st).xyz : texture2D(DIFFUSE, UV, 0.0).xyz;
	vec3 pixel = textureBicubic(DIFFUSE, vUV.st).xyz;

	vec3 col = vec3(0,0,0);

	if (DrunkFactor > 0.0) {
		col = drunkenDeform(pixel, noise);
	} else {
		col = pixel;
	}

	if (BlurFactor > 0.0) {
		col = screenBlur(col, true);
	}

	if(NightVisionGoggles<0.5) {
		col = screenWorld(col, noise);
	} else {
		col = screenNightvision(col, noise);
	}

	gl_FragColor = vec4(col, 1.0);
}

/* LASTMAIN
void main()
{
    vec2 UV =  vUV.st;

    vec3 rotOffset = vec3(1.425,3.892,5.835); //rotation offset values
    vec2 rotCoordsR = coordRot(UV, timer + rotOffset.x);
    vec3 noise = vec3(pnoise3D(vec3(rotCoordsR*vec2(width/grainsize,height/grainsize),0.0)));

    vec3 pixel = (Zoom > 0.0) ? textureBicubic(DIFFUSE, vUV.st).xyz : texture2D(DIFFUSE, UV, 0.0).xyz;

    vec3 Diffuse = vec3(0,0,0);


    float intensity;
    float testIntens; //<-added
    if(NightVisionGoggles<0.5) {
        //base pixel light val
        testIntens = (0.299 * pixel.r) + (0.587 * pixel.g) + (0.114 * pixel.b);

        Diffuse = desaturate(pixel, DesaturationVal);
        Diffuse = blendOverlay(Diffuse,Light,LightIntensity);
        Diffuse = clamp(Diffuse, 0.0, 1.0);
        intensity = (0.299 * Diffuse.r) + (0.587 * Diffuse.g) + (0.114 * Diffuse.b);

        //boost based on darkness (= dark color with high intensity)
        float str = (((1.0-Light.r)+(1.0-Light.g)+(1.0-Light.b))*0.333)*LightIntensity;
        if(Exterior>0.5) {
            testIntens *= str * str * 0.33 * FogMod;
        } else {
            testIntens *= str * str * 0.33;
        }
        Diffuse.r += testIntens;
        Diffuse.g += testIntens;
        Diffuse.b += testIntens;
    } else {
        Diffuse = pixel;
        intensity = (0.299 * Diffuse.r) + (0.587 * Diffuse.g) + (0.114 * Diffuse.b);
    }

    if(NightVisionGoggles>0.5) {
        Diffuse = mix(Diffuse, vec3(intensity), (NightValue*0.8) * (1.0 - intensity));
        Diffuse = ((1.0 - NightValue) * Diffuse) + (NightValue * Diffuse*Diffuse) * 1.5;

        Diffuse.rg -= NightValue * 0.25 * (1.0 - intensity);
        Diffuse.b +=  (NightValue * 0.25 * (1.0 - intensity));
    }

    vec3 col = contrast(desaturate(Diffuse, 0.40), 1.3);
    float invintensity = 1.0 - intensity;
    invintensity = invintensity * invintensity;

    if(NightVisionGoggles>0.5)
    {
        col.rg+=0.45;
        col = col*1.9+((noise*0.015) * (invintensity * 5.0));//col = col+((noise*grainamount) * (invintensity * 5.0));

        float intensity2 = dot(lumvec,col) ;

        // adjust contrast - 0...1
        intensity2 = clamp(contrast2 * (intensity2 - 0.5) + 0.5, 0.0, 1.0);

        // final green result 0...1
        float green = clamp(intensity2 / 0.59, 0.0, 1.0) * intensityAdjust;

        // vision color - getting green max
        vec3 visionColor = vec3(0,green,0); //vec3(0,green,0);//vec3(0.1, 0.95, 0.2);

        // final color
        col = col * visionColor;
    }
    else
    {
        col = col+((noise*grainamount) * (invintensity * 5.0));
    }

    gl_FragColor = vec4(col, 1.0);
}*/

/*void main() LAST MAIN I
{
    vec2 UV =  vUV.st;

    vec3 rotOffset = vec3(1.425,3.892,5.835); //rotation offset values
    vec2 rotCoordsR = coordRot(UV, timer + rotOffset.x);
    vec3 noise = vec3(pnoise3D(vec3(rotCoordsR*vec2(width/grainsize,height/grainsize),0.0)));

    //float night = clamp(abs(TimeOfDay), 0.5, 1.0) * 2.0 - 1.0;
    //night = night * 0.4;

    vec3 pixel = (Zoom > 0.0) ? textureBicubic(DIFFUSE, vUV.st).xyz : texture2D(DIFFUSE, UV, 0.0).xyz;
    //float intensity = (0.299 * pixel.r) + (0.587 * pixel.g) + (0.114 * pixel.b);

    vec3 Diffuse = vec3(0,0,0);

    //Diffuse += pixel;

        //Diffuse += Diffuse * Light * LightIntensity * clamp(pixel.b,0.25,1.0); //LightIntensity;
    //Diffuse += Light * LightIntensity * Diffuse * clamp(pixel.b,0.25,1.0);
    //previous screenshot
        //Diffuse = desaturate(pixel, DesaturationVal);
        //Diffuse += Light * LightIntensity * clamp((pixel.r+pixel.g+pixel.b)*0.34,0.0,1.0);
    float intensity;
    if(NightVisionGoggles<0.5) {
        Diffuse = desaturate(pixel, DesaturationVal);
        Diffuse = blendOverlay(Diffuse,Light,LightIntensity);
        //Diffuse = blendOverlay(pixel,Light,LightIntensity);
        //Diffuse = desaturate(Diffuse, DesaturationVal);
        Diffuse = clamp(Diffuse, 0.0, 1.0);
        intensity = (0.299 * Diffuse.r) + (0.587 * Diffuse.g) + (0.114 * Diffuse.b);
        //Diffuse.rg += NightValue*0.35*intensity;
            //Diffuse.b -= NightValue*0.25*intensity;
        //Diffuse = clamp(Diffuse, 0.0, 1.0);
    } else {
        Diffuse = pixel;
        intensity = (0.299 * Diffuse.r) + (0.587 * Diffuse.g) + (0.114 * Diffuse.b);
    }

    //intensity = (0.299 * Diffuse.r) + (0.587 * Diffuse.g) + (0.114 * Diffuse.b);

    if(NightVisionGoggles>0.5) {
        Diffuse = mix(Diffuse, vec3(intensity), (NightValue*0.8) * (1.0 - intensity));
        Diffuse = ((1.0 - NightValue) * Diffuse) + (NightValue * Diffuse*Diffuse) * 1.5;

        Diffuse.rg -= NightValue * 0.25 * (1.0 - intensity);
        Diffuse.b +=  (NightValue * 0.25 * (1.0 - intensity));
    }

    vec3 col = contrast(desaturate(Diffuse, 0.40), 1.3);
    float invintensity = 1.0 - intensity;
    invintensity = invintensity * invintensity;

    if(NightVisionGoggles>0.5)
    {
        col.rg+=0.45;
        col = col*1.9+((noise*0.015) * (invintensity * 5.0));//col = col+((noise*grainamount) * (invintensity * 5.0));

        float intensity2 = dot(lumvec,col) ;

        // adjust contrast - 0...1
        intensity2 = clamp(contrast2 * (intensity2 - 0.5) + 0.5, 0.0, 1.0);

        // final green result 0...1
        float green = clamp(intensity2 / 0.59, 0.0, 1.0) * intensityAdjust;

        // vision color - getting green max
        vec3 visionColor = vec3(0,green,0); //vec3(0,green,0);//vec3(0.1, 0.95, 0.2);

        // final color
        col = col * visionColor;
    }
    else
    {
        col = col+((noise*grainamount) * (invintensity * 5.0));
    }

    gl_FragColor = vec4(col, 1.0);
}*/

/*
void mainOriginal()
{
    vec2 UV = vUV.st;

    vec3 rotOffset = vec3(1.425,3.892,5.835); //rotation offset values
	vec2 rotCoordsR = coordRot(UV, timer + rotOffset.x);
	vec3 noise = vec3(pnoise3D(vec3(rotCoordsR*vec2(width/grainsize,height/grainsize),0.0)));

    float bloom = 1.0 - abs(0.0 - TimeOfDay);
    bloom = bloom * 0.0;
	 float dawn = 1.0 - (abs(clamp(TimeOfDay, -1.0, 0.0) + 0.5) * 2.0);
	 dawn *= dawn;
	 dawn *= 1.3;
    float dusk = 1.0 - (abs(clamp(TimeOfDay, 0.0, 1.0) - 0.5) * 2.0);
    dusk *= dusk;
    dusk *= 1.3;
    float night = clamp(abs(TimeOfDay), 0.5, 1.0) * 2.0 - 1.0;
    night = night * 0.4;

    vec3 pixel = (Zoom > 0.0) ? textureBicubic(DIFFUSE, vUV.st).xyz : texture2D(DIFFUSE, UV, 0.0).xyz;
    float intensity = (0.299 * pixel.r) + (0.587 * pixel.g) + (0.114 * pixel.b);

    vec3 Diffuse = texture2D(DIFFUSE, UV, 4.0).xyz * 5.0;
    Diffuse += texture2D(DIFFUSE, UV, 3.0).xyz * 2.5;
    Diffuse += texture2D(DIFFUSE, UV, 2.0).xyz;
    Diffuse += texture2D(DIFFUSE, UV, 1.0).xyz;
    Diffuse /= 6.0;
    Diffuse *= Diffuse*Diffuse;
    Diffuse *= 0.75 * bloom * 0.15 * BloomVal;
    Diffuse *= bloom * 0.75 * pow(intensity, 5.0) + 0.003 * BloomVal;

    Diffuse.yz += colHaze.yz * dawn * 0.125;

    Diffuse += pixel;

    //Diffuse += pow(intensity * bloom, 3);
    Diffuse = clamp(Diffuse, 0.0, 1.0);

    Diffuse += colDawn * Diffuse * dawn * clamp(pixel.b, 0.25, 1.0);
    Diffuse += colDusk * Diffuse * dusk * clamp(pixel.b, 0.25, 1.0);
    Diffuse = clamp(Diffuse, 0.0, 1.0);

    Diffuse = mix(Diffuse, vec3(intensity), (night*0.8) * (1.0 - intensity));
    Diffuse = ((1.0 - night) * Diffuse) + (night * Diffuse*Diffuse) * 1.5;

    Diffuse.rg -= night * 0.25 * (1.0 - intensity);
    Diffuse.b +=  (night * 0.25 * (1.0 - intensity));
    vec3 col = contrast(desaturate(Diffuse, 0.40), 1.3);
    float invintensity = 1.0 - intensity;
    invintensity = invintensity * invintensity;

    col = col+((noise*grainamount) * (invintensity * 5.0));
    gl_FragColor = vec4(col, 1.0);
 }*/
