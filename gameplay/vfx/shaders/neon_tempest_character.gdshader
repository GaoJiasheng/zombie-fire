shader_type canvas_item;
render_mode unshaded;

uniform float effect_intensity : hint_range(0.0, 1.0) = 0.42;
uniform float flow_speed : hint_range(0.0, 2.0) = 0.72;
uniform float head_protection : hint_range(0.0, 0.5) = 0.27;


vec3 hue_to_rgb(float hue) {
	vec3 phase = abs(mod(hue * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0);
	return clamp(phase - 1.0, 0.0, 1.0);
}


void fragment() {
	vec4 base = texture(TEXTURE, UV);
	// The top of every authored character frame contains the head and hair.
	// A soft protected band keeps identity/skin tones untouched even while firing.
	float body_mask = smoothstep(head_protection, head_protection + 0.13, UV.y);
	float warm_skin = smoothstep(0.03, 0.20, base.r - base.b)
		* smoothstep(-0.03, 0.13, base.r - base.g)
		* (1.0 - smoothstep(0.76, 0.98, max(max(base.r, base.g), base.b)));
	float garment_mask = body_mask * (1.0 - warm_skin * 0.92);

	float time_phase = TIME * flow_speed;
	float diagonal = UV.x * 7.2 + UV.y * 4.8 - time_phase;
	float narrow_band = pow(0.5 + 0.5 * sin(diagonal * 6.2831853), 9.0);
	float counter_band = pow(
		0.5 + 0.5 * sin((UV.x * -4.3 + UV.y * 8.1 + time_phase * 0.72) * 6.2831853),
		13.0
	);
	float circuit_mask = clamp(narrow_band * 0.76 + counter_band * 0.46, 0.0, 1.0);

	vec2 pixel = TEXTURE_PIXEL_SIZE;
	float neighbor_alpha = min(
		min(texture(TEXTURE, UV + vec2(pixel.x, 0.0)).a, texture(TEXTURE, UV - vec2(pixel.x, 0.0)).a),
		min(texture(TEXTURE, UV + vec2(0.0, pixel.y)).a, texture(TEXTURE, UV - vec2(0.0, pixel.y)).a)
	);
	float lower_rim = clamp(base.a - neighbor_alpha, 0.0, 1.0) * body_mask;
	float hue = fract(UV.x * 0.34 + UV.y * 0.62 - time_phase * 0.18);
	vec3 neon = mix(hue_to_rgb(hue), vec3(0.25, 0.92, 1.0), 0.28);

	vec3 emitted = neon * garment_mask * base.a * (circuit_mask * 0.62 + lower_rim * 0.78);
	vec3 result = base.rgb + emitted * effect_intensity;
	COLOR = vec4(min(result, vec3(1.0)), base.a);
}
