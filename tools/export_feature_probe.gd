extends SceneTree


func _initialize() -> void:
	var expected := OS.get_environment("ZOMBIE_FIRE_EXPECT_EXPORT_FEATURE").strip_edges()
	if expected == "":
		push_error("Export feature probe requires ZOMBIE_FIRE_EXPECT_EXPORT_FEATURE")
		quit(1)
		return
	if not OS.has_feature(expected):
		push_error("Exported PCK is missing required feature: %s" % expected)
		quit(1)
		return
	print("Export feature probe passed: %s=true" % expected)
	quit()
