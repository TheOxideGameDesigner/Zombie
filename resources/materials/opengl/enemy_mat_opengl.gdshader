shader_type spatial;
render_mode specular_disabled;

void fragment() {
	ALBEDO = vec3(pow(COLOR.r, 1.0 / 2.2), pow(COLOR.g, 1.0 / 2.2), pow(COLOR.b, 1.0 / 2.2));
}