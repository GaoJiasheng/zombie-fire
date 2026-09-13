shader_type canvas_item;

// The texture-backed ArmoredFace child owns the visible nine-slice surface.
// Keep TextureButton's original resources for state/theme and input contracts,
// but do not paint a second aspect-fit raster below the child (it can protrude
// through the nine-slice's transparent corners). Children use their own material.
void fragment() {
	COLOR = vec4(0.0);
}
