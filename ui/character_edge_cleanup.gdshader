shader_type canvas_item;
render_mode unshaded;
varying vec4 vertex_tint;

void vertex() {
	vertex_tint = COLOR;
}

// Display-only despill for the original neutral/ice hero cutouts. Alpha,
// geometry, body pixels and weapon anchors are deliberately unchanged.
void fragment() {
	vec4 base = texture(TEXTURE, UV);
	vec2 step_uv = TEXTURE_PIXEL_SIZE * 12.0;
	float nearby_alpha = min(
		min(texture(TEXTURE, UV + vec2(step_uv.x, 0.0)).a, texture(TEXTURE, UV - vec2(step_uv.x, 0.0)).a),
		min(texture(TEXTURE, UV + vec2(0.0, step_uv.y)).a, texture(TEXTURE, UV - vec2(0.0, step_uv.y)).a)
	);
	float green_excess = max(0.0, base.g - max(base.r, base.b));
	float fringe = 1.0 - smoothstep(0.75, 0.99, nearby_alpha);
	base.g -= green_excess * smoothstep(0.06, 0.20, green_excess) * fringe;
	COLOR = vertex_tint * base;
}
