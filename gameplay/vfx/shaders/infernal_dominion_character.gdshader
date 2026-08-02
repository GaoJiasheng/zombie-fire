shader_type canvas_item;
render_mode unshaded;

uniform float effect_intensity : hint_range(0.0, 1.0) = 0.48;
uniform float flow_speed : hint_range(0.0, 2.0) = 0.42;
uniform float head_protection : hint_range(0.0, 0.5) = 0.27;
uniform float fire_pulse : hint_range(0.0, 1.0) = 0.0;


void fragment() {
	vec4 base = texture(TEXTURE, UV);
	float body_mask = smoothstep(head_protection, head_protection + 0.13, UV.y);
	float warm_skin = smoothstep(0.03, 0.20, base.r - base.b)
		* smoothstep(-0.03, 0.13, base.r - base.g)
		* (1.0 - smoothstep(0.76, 0.98, max(max(base.r, base.g), base.b)));
	float garment_mask = body_mask * (1.0 - warm_skin * 0.94);

	vec2 pixel = TEXTURE_PIXEL_SIZE;
	vec4 right_px = texture(TEXTURE, UV + vec2(pixel.x, 0.0));
	vec4 left_px = texture(TEXTURE, UV - vec2(pixel.x, 0.0));
	vec4 down_px = texture(TEXTURE, UV + vec2(0.0, pixel.y));
	vec4 up_px = texture(TEXTURE, UV - vec2(0.0, pixel.y));
	float neighbor_alpha = min(min(right_px.a, left_px.a), min(down_px.a, up_px.a));
	float silhouette_rim = clamp(base.a - neighbor_alpha, 0.0, 1.0) * body_mask;

	float luma = dot(base.rgb, vec3(0.299, 0.587, 0.114));
	float edge = abs(luma - dot(right_px.rgb, vec3(0.299, 0.587, 0.114)))
		+ abs(luma - dot(left_px.rgb, vec3(0.299, 0.587, 0.114)))
		+ abs(luma - dot(down_px.rgb, vec3(0.299, 0.587, 0.114)))
		+ abs(luma - dot(up_px.rgb, vec3(0.299, 0.587, 0.114)));
	float material_edge = smoothstep(0.10, 0.48, clamp(edge, 0.0, 1.0)) * garment_mask;
	float dark_armor = (1.0 - smoothstep(0.34, 0.78, luma)) * garment_mask;

	float time_phase = TIME * flow_speed;
	float furnace_band = exp(-pow(UV.y - mix(0.34, 0.83, fract(time_phase * 0.27)), 2.0) * 84.0);
	float shoulder_band = smoothstep(0.20, 0.34, UV.y) * (1.0 - smoothstep(0.64, 0.80, UV.y));
	float side_arms = smoothstep(0.10, 0.38, abs(UV.x - 0.5));
	float firing_zone = clamp(shoulder_band * (0.42 + side_arms * 0.92) + furnace_band * 0.36, 0.0, 1.0);

	vec3 copper = vec3(0.92, 0.27, 0.055);
	vec3 ember = vec3(1.0, 0.58, 0.12);
	vec3 white_hot = vec3(1.0, 0.91, 0.66);
	vec3 heat = mix(copper, ember, smoothstep(0.24, 0.84, UV.y));
	heat = mix(heat, white_hot, fire_pulse * firing_zone * 0.42);
	float emission_mask = silhouette_rim * 0.25 + material_edge * dark_armor * (0.16 + fire_pulse * firing_zone * 1.12);
	vec3 emitted = heat * garment_mask * base.a * emission_mask;
	vec3 armor_tint = copper * dark_armor * (0.016 + fire_pulse * firing_zone * 0.075);
	COLOR = vec4(min(base.rgb + (emitted + armor_tint) * effect_intensity, vec3(1.0)), base.a);
}
