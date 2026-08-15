shader_type canvas_item;
render_mode unshaded, blend_add;

// The accepted V3 frost crest is authored slightly lower on its right edge.
// Counter-warp only that global slope while retaining all local ice/snow shape.
uniform float slope_compensation_px : hint_range(-48.0, 48.0, 0.5) = 18.0;
uniform float gameplay_seam_y_px : hint_range(0.0, 240.0, 0.5) = 96.0;
uniform float gameplay_seam_opacity : hint_range(0.0, 1.0, 0.01) = 0.34;

void fragment() {
	vec2 source_uv = UV;
	source_uv.y += (UV.x - 0.5) * slope_compensation_px * TEXTURE_PIXEL_SIZE.y;
	if (source_uv.y < 0.0 || source_uv.y > 1.0) {
		COLOR = vec4(0.0);
	} else {
		vec4 tint = COLOR;
		vec4 frost = texture(TEXTURE, source_uv);
		float output_y_px = UV.y / TEXTURE_PIXEL_SIZE.y;
		float seam = 1.0 - smoothstep(1.25, 4.5, abs(output_y_px - gameplay_seam_y_px));
		float edge_fade = smoothstep(0.0, 0.035, UV.x) * smoothstep(0.0, 0.035, 1.0 - UV.x);
		vec4 level_seam = vec4(0.48, 0.88, 1.0, 1.0) * seam * edge_fade * gameplay_seam_opacity;
		COLOR = (frost + level_seam) * tint;
	}
}
