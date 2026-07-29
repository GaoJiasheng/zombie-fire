shader_type canvas_item;
render_mode unshaded;

uniform float effect_intensity : hint_range(0.0, 1.0) = 0.42;
uniform float flow_speed : hint_range(0.0, 2.0) = 0.72;
uniform float head_protection : hint_range(0.0, 0.5) = 0.27;
uniform float fire_pulse : hint_range(0.0, 1.0) = 0.0;


vec3 hue_to_rgb(float hue) {
	vec3 phase = abs(mod(hue * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0);
	return clamp(phase - 1.0, 0.0, 1.0);
}


void fragment() {
	vec4 base = texture(TEXTURE, UV);

	// The earlier preview drew procedural diagonal lines over the whole actor,
	// which read as a cheap net. This treatment follows authored silhouette and
	// material edges instead: restrained suit piping at idle, then a localized
	// shoulder/arm energy surge while firing.
	float body_mask = smoothstep(head_protection, head_protection + 0.13, UV.y);
	float warm_skin = smoothstep(0.03, 0.20, base.r - base.b)
		* smoothstep(-0.03, 0.13, base.r - base.g)
		* (1.0 - smoothstep(0.76, 0.98, max(max(base.r, base.g), base.b)));
	float garment_mask = body_mask * (1.0 - warm_skin * 0.92);

	vec2 pixel = TEXTURE_PIXEL_SIZE;
	vec4 right_px = texture(TEXTURE, UV + vec2(pixel.x, 0.0));
	vec4 left_px = texture(TEXTURE, UV - vec2(pixel.x, 0.0));
	vec4 down_px = texture(TEXTURE, UV + vec2(0.0, pixel.y));
	vec4 up_px = texture(TEXTURE, UV - vec2(0.0, pixel.y));
	float neighbor_alpha = min(min(right_px.a, left_px.a), min(down_px.a, up_px.a));
	float silhouette_rim = clamp(base.a - neighbor_alpha, 0.0, 1.0) * body_mask;

	float luma = dot(base.rgb, vec3(0.299, 0.587, 0.114));
	float right_luma = dot(right_px.rgb, vec3(0.299, 0.587, 0.114));
	float left_luma = dot(left_px.rgb, vec3(0.299, 0.587, 0.114));
	float down_luma = dot(down_px.rgb, vec3(0.299, 0.587, 0.114));
	float up_luma = dot(up_px.rgb, vec3(0.299, 0.587, 0.114));
	float material_edge = clamp(
		abs(luma - right_luma) + abs(luma - left_luma)
			+ abs(luma - down_luma) + abs(luma - up_luma),
		0.0,
		1.0
	);
	material_edge = smoothstep(0.10, 0.48, material_edge) * garment_mask;
	float dark_armor = (1.0 - smoothstep(0.34, 0.78, luma)) * garment_mask;

	float time_phase = TIME * flow_speed;
	float hue = fract(0.58 + UV.x * 0.18 + UV.y * 0.12 - time_phase * 0.025);
	vec3 rainbow = hue_to_rgb(hue);
	vec3 cyan = vec3(0.14, 0.94, 1.0);
	vec3 violet = vec3(0.92, 0.16, 1.0);
	vec3 neon = mix(cyan, violet, smoothstep(0.20, 0.82, UV.x));
	neon = mix(neon, rainbow, 0.14);

	float surge_y = fract(time_phase * 0.32);
	float surge_band = exp(-pow(UV.y - mix(0.30, 0.82, surge_y), 2.0) * 92.0);
	float shoulder_band = smoothstep(0.20, 0.34, UV.y) * (1.0 - smoothstep(0.62, 0.78, UV.y));
	float side_arms = smoothstep(0.12, 0.38, abs(UV.x - 0.5));
	float firing_zone = clamp(shoulder_band * (0.48 + side_arms * 0.82) + surge_band * 0.34, 0.0, 1.0);

	float idle_piping = silhouette_rim * 0.78 + material_edge * dark_armor * 0.24;
	float active_piping = material_edge * dark_armor * firing_zone;
	float emission_mask = idle_piping * 0.34 + active_piping * fire_pulse * 1.18;
	vec3 emitted = neon * garment_mask * base.a * emission_mask;
	vec3 armor_tint = mix(cyan, violet, UV.x) * dark_armor * (0.018 + fire_pulse * firing_zone * 0.07);
	vec3 result = base.rgb + (emitted + armor_tint) * effect_intensity;
	COLOR = vec4(min(result, vec3(1.0)), base.a);
}
