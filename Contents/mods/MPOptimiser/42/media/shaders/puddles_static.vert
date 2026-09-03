#version 110

uniform mat4 ModelViewProjection;

varying float puddlesDirNE;
varying float puddlesDirNW;
varying float puddlesDirAll;
varying float puddlesDirNone;

void main (void)
{
	gl_Position = ModelViewProjection * gl_Vertex;
	gl_TexCoord[0] = gl_MultiTexCoord0;
	gl_FrontColor = gl_Color;
    
    puddlesDirNE = gl_MultiTexCoord0.st.x;
    puddlesDirNW = gl_MultiTexCoord0.st.y;
    puddlesDirAll = gl_MultiTexCoord1.st.x;
    puddlesDirNone = gl_MultiTexCoord1.st.y;
}
