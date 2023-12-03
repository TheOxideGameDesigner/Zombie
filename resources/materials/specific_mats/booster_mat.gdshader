shader_type spatial;
render_mode unshaded;

uniform sampler2D albedo_texture;
instance uniform vec2 texture_scale;

void fragment() {
	ALBEDO = textureLod(albedo_texture, vec2(UV.x * texture_scale.x, UV.y * texture_scale.y + TIME * 2.0), 0).rgb;
}
