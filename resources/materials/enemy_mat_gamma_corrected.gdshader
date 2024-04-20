shader_type spatial;
render_mode specular_disabled;

instance uniform float pain;
instance uniform float hypno = 0.0;

void vertex() {
	COLOR = vec4(mix(mix(pow(COLOR.rgb, vec3(2.2, 2.2, 2.2)), vec3(1, 0, 0), pain), vec3(0.5, 0, 1), max(0, hypno - pain)), 0);
}

void fragment() {
	ALBEDO = COLOR.rgb;
}