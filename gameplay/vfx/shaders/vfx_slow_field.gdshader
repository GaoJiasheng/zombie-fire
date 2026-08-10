shader_type canvas_item;
render_mode blend_add, unshaded;

uniform vec4 field_color : source_color = vec4(0.32, 0.82, 1.0, 0.24);
uniform float intensity : hint_range(0.0, 2.0) = 1.0;
uniform float drift_speed : hint_range(0.0, 3.0) = 0.7;
uniform float secondary_opacity : hint_range(0.0, 1.0) = 0.34;
uniform float zone_fill_opacity : hint_range(0.0, 1.0) = 0.32;

void fragment() {
	// The bitmap is authored as an organic seamless cold-energy medium. Two
	// independently drifting samples prevent obvious repetition without drawing
	// procedural scan lines, grids or geometric spell-circle placeholders.
	vec2 drift_a = vec2(TIME * 0.010, -TIME * 0.014) * drift_speed;
	vec2 drift_b = vec2(-TIME * 0.008, TIME * 0.011) * drift_speed;
	vec4 primary = texture(TEXTURE, UV + drift_a);
	vec2 secondary_uv = vec2(-UV.y * 0.83, UV.x * 0.83) + drift_b + vec2(0.37, 0.19);
	vec4 secondary = texture(TEXTURE, secondary_uv);
	float authored_alpha = clamp(primary.a + secondary.a * secondary_opacity, 0.0, 1.0);
	vec3 authored_color = max(primary.rgb, secondary.rgb * (0.72 + secondary_opacity * 0.28));
	vec3 color = mix(field_color.rgb, authored_color * 1.12, clamp(authored_alpha * 1.45, 0.0, 0.92));
	// A restrained continuous wash makes the entire gameplay region readable,
	// including the dark negative spaces of the rendered tile. It fades in at
	// the moving threshold and never creates a circle/arc silhouette.
	float threshold_fade = smoothstep(0.0, 0.045, UV.y);
	float area_alpha = field_color.a * zone_fill_opacity * threshold_fade;
	float detail_alpha = authored_alpha * field_color.a * intensity;
	COLOR = vec4(color, clamp(area_alpha + detail_alpha, 0.0, 0.72));
}
