shader_type canvas_item;
render_mode unshaded;

uniform vec4 accent_a : source_color = vec4(0.2, 0.82, 1.0, 1.0);
uniform vec4 accent_b : source_color = vec4(0.82, 0.44, 1.0, 1.0);
varying vec4 vertex_tint;

void vertex() {
	vertex_tint = COLOR;
}

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	vec3 accent = mix(accent_a.rgb, accent_b.rgb, smoothstep(0.1, 0.9, UV.x));
	float warmth = smoothstep(0.06, 0.24, base.r - base.b) * smoothstep(0.02, 0.14, base.r - base.g);
	float brightness = max(base.r, max(base.g, base.b));
	vec3 metal = mix(base.rgb, accent * brightness, warmth * 0.94);
	// Subtle reflected tint preserves neutral metal and existing elemental LEDs.
	float neutral = 1.0 - smoothstep(0.05, 0.20, brightness - min(base.r, min(base.g, base.b)));
	metal = mix(metal, metal * (vec3(0.88) + accent * 0.16), neutral * 0.55);
	COLOR = vertex_tint * vec4(metal, base.a);
}
