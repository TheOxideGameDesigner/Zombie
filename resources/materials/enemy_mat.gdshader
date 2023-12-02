shader_type spatial;
render_mode specular_disabled;

instance uniform float pain;

void vertex() {
	COLOR = vec4(mix(COLOR.rgb, vec3(1, 0, 0), pain), 0);
}

void fragment() {
	ALBEDO = COLOR.rgb;
}