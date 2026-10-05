#version 120

attribute vec2 vertex;
attribute vec4 color;
attribute float aDirNE;
attribute float aDirNW;
attribute float aDirAll;
attribute float aDirNone;
attribute float aFragDepth;

uniform mat4 ModelViewProjection;

varying float puddlesDirNE;
varying float puddlesDirNW;
varying float puddlesDirAll;
varying float puddlesDirNone;
varying vec4 vertColour;
varying float vDepth;

void puddlesMain(void)
{
	gl_Position = ModelViewProjection * vec4(vertex.xy, 0.0, 1.0);
	vertColour = color;

	puddlesDirNE = aDirNE;
	puddlesDirNW = aDirNW;
	puddlesDirAll = aDirAll;
	puddlesDirNone = 1.0 - aDirNone;
	vDepth = aFragDepth;
}
