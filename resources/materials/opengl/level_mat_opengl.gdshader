shader_type spatial;
render_mode specular_disabled;

void fragment() {
	ALBEDO = COLOR.rgb;
}

void light() {
	DIFFUSE_LIGHT += clamp(dot(NORMAL, LIGHT), 0.0, 1.0) * ATTENUATION * LIGHT_COLOR * 0.1f;
}