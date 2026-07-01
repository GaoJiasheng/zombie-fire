shader_type canvas_item;
render_mode blend_add, unshaded;

uniform vec4 tint : source_color = vec4(1.0, 0.95, 0.72, 1.0);
uniform float intensity : hint_range(0.0, 6.0) = 2.4;
uniform float core_power : hint_range(0.25, 4.0) = 1.35;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float alpha = pow(tex.a, core_power) * tint.a;
	float hot_core = smoothstep(0.42, 1.0, tex.a);
	float pulse = 1.0 + sin(TIME * 52.0 + tex.a * 6.28318) * 0.055;
	vec3 glow = tint.rgb * (intensity + hot_core * intensity * 0.85) * pulse;
	COLOR = vec4(glow, alpha);
}
