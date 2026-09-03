#version 330

in vec3 vNormal;
in vec4 vColor;

uniform vec3 Light0Direction = vec3(0.5, -1, 0.0);
uniform vec3 Light0Color = vec3(0.33, 0.33, 0.33);
uniform vec3 AmbientColor = vec3(0.4, 0.4, 0.4);

void main()
{
	vec3 normal = normalize(vNormal);
	vec3 lighting = vec3(0.0);
	float dotprod = max(dot(normal, normalize(Light0Direction)), 0.0);
	lighting += Light0Color * dotprod;

	dotprod = max(dot(-normal, normalize(Light0Direction)), 0.0);
	lighting += Light0Color * dotprod * 0.5;

	lighting += AmbientColor;
	lighting = min(lighting, vec3(1.0));
	gl_FragColor = vColor * vec4(lighting, 1.0);
}
