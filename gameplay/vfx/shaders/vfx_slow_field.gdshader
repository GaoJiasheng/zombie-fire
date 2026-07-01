shader_type canvas_item;
render_mode blend_add, unshaded;

uniform vec4 field_color : source_color = vec4(0.32, 0.82, 1.0, 0.24);
uniform vec4 edge_color : source_color = vec4(0.74, 0.96, 1.0, 0.42);
uniform float intensity : hint_range(0.0, 2.0) = 1.0;
uniform float drift_speed : hint_range(0.0, 3.0) = 0.7;
uniform float scan_strength : hint_range(0.0, 1.0) = 0.34;

void fragment() {
	vec2 uv = UV;
	float field_mask = smoothstep(0.0, 0.12, uv.y) * (1.0 - smoothstep(0.88, 1.0, uv.y));
	float edge = smoothstep(0.18, 0.0, uv.y) + smoothstep(0.18, 0.0, 1.0 - uv.y);
	float ripple_a = sin((uv.x * 18.0 + uv.y * 6.0 - TIME * drift_speed) * 6.28318) * 0.5 + 0.5;
	float ripple_b = sin((uv.x * -10.0 + uv.y * 14.0 + TIME * drift_speed * 0.7) * 6.28318) * 0.5 + 0.5;
	float scan = smoothstep(0.78, 1.0, max(ripple_a, ripple_b));
	float alpha = (0.055 + scan * scan_strength + edge * 0.3) * field_mask * field_color.a * intensity;
	vec3 color = field_color.rgb * (0.9 + scan * 1.45) + edge_color.rgb * edge * 0.7;
	COLOR = vec4(color, alpha);
}
