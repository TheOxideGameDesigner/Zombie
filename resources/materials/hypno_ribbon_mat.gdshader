shader_type spatial;
render_mode unshaded;
uniform float opac = 1.0f;
uniform float offset = 1.0f;

const float RADIUS = 0.2f;
const float SQUIGGINESS = 2.0f;

void vertex() {
	VERTEX.y += offset;
	if (VERTEX.y < -0.001)
	{
		VERTEX.z += sin(VERTEX.y * SQUIGGINESS) * RADIUS;
		VERTEX.x += cos(VERTEX.y * SQUIGGINESS) * RADIUS;
	}
}

void fragment() {
	ALBEDO = vec3(1, 0, 1);
	ALPHA = opac;
}
