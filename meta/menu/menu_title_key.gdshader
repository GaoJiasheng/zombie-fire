shader_type canvas_item;

uniform float dark_key_threshold : hint_range(0.0, 0.4) = 0.09;
uniform float dark_key_softness : hint_range(0.01, 0.25) = 0.06;

void fragment() {
	vec4 sampled = texture(TEXTURE, UV);
	float luminance = max(sampled.r, max(sampled.g, sampled.b));
	float keyed_alpha = smoothstep(
		dark_key_threshold,
		dark_key_threshold + dark_key_softness,
		luminance
	);
	sampled.a *= keyed_alpha;
	COLOR = sampled;
}
