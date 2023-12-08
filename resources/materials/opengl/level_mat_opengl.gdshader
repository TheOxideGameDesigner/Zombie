shader_type spatial;
render_mode specular_disabled;

float srgb2lin(float s)
{
	if (s <= 0.0404482362771082)
		return s / 12.92;
	return pow(((s + 0.055) / 1.055), 2.4);
}

void fragment() {
	float a = 0.72f;
	ALBEDO = COLOR.rgb * a;
}