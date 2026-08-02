shader_type canvas_item;
render_mode unshaded;

uniform float effect_intensity : hint_range(0.0, 1.0) = 0.50;
uniform float flow_speed : hint_range(0.0, 2.0) = 0.36;
uniform float head_protection : hint_range(0.0, 0.5) = 0.27;
uniform float fire_pulse : hint_range(0.0, 1.0) = 0.0;


void fragment() {
	vec4 base = texture(TEXTURE, UV);
	float body_mask = smoothstep(head_protection, head_protection + 0.13, UV.y);
	float warm_skin = smoothstep(0.03, 0.20, base.r - base.b)
		* smoothstep(-0.03, 0.13, base.r - base.g)
		* (1.0 - smoothstep(0.76, 0.98, max(max(base.r, base.g), base.b)));
	float garment_mask = body_mask * (1.0 - warm_skin * 0.96);

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
	float crystal_edge = smoothstep(0.10, 0.46, clamp(edge, 0.0, 1.0)) * garment_mask;
	float dark_material = (1.0 - smoothstep(0.38, 0.80, luma)) * garment_mask;

	float phase = TIME * flow_speed;
	float aurora = 0.5 + 0.5 * sin((UV.y * 7.0 + UV.x * 3.2 - phase * 1.8) * 6.28318);
	float shoulder_band = smoothstep(0.18, 0.34, UV.y) * (1.0 - smoothstep(0.64, 0.82, UV.y));
	float side_plates = smoothstep(0.08, 0.38, abs(UV.x - 0.5));
	float firing_zone = clamp(shoulder_band * (0.38 + side_plates * 0.94), 0.0, 1.0);

	vec3 cyan = vec3(0.28, 0.90, 1.0);
	vec3 ice_white = vec3(0.84, 0.97, 1.0);
	vec3 violet = vec3(0.58, 0.40, 0.94);
	vec3 aurora_color = mix(cyan, violet, aurora * 0.58);
	aurora_color = mix(aurora_color, ice_white, fire_pulse * firing_zone * 0.34);
	float emission = silhouette_rim * 0.24 + crystal_edge * (0.16 + fire_pulse * firing_zone * 0.92);
	vec3 emitted = aurora_color * garment_mask * base.a * emission;
	vec3 cold_tint = cyan * dark_material * (0.014 + fire_pulse * firing_zone * 0.055);
	COLOR = vec4(min(base.rgb + (emitted + cold_tint) * effect_intensity, vec3(1.0)), base.a);
}
