shader_type spatial;
render_mode unshaded;

uniform float opac = 1.0f;
uniform float size = 20.0f;

void fragment() {
	ALBEDO = vec3(1.0f, 0, 0);
	ALPHA = opac;
}


void vertex() {
	VERTEX.y += 0.5f;
	VERTEX.y *= size;
	float ang = (size - VERTEX.y) * 3.0f + 3.0f * TIME;
	VERTEX.x += cos(ang) * 0.1f;
	VERTEX.z += sin(ang) * 0.1f;
}