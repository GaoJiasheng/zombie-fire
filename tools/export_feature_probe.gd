extends SceneTree


func _initialize() -> void:
	var expected := OS.get_environment("ZOMBIE_FIRE_EXPECT_EXPORT_FEATURE").strip_edges()
	var forbidden := OS.get_environment("ZOMBIE_FIRE_FORBID_EXPORT_FEATURES").strip_edges()
	if expected == "" and forbidden == "":
		push_error("Export feature probe requires ZOMBIE_FIRE_EXPECT_EXPORT_FEATURE or ZOMBIE_FIRE_FORBID_EXPORT_FEATURES")
		quit(1)
		return
	# App Review builds: every TestFlight-only convenience must be absent.
	for forbidden_feature in forbidden.split(",", false):
		if OS.has_feature(forbidden_feature.strip_edges()):
			push_error("Exported PCK carries a TestFlight-only feature that must not ship to App Review: %s" % forbidden_feature)
			quit(1)
			return
	if expected == "":
		print("Export feature probe passed: none of [%s] present" % forbidden)
		quit()
		return
	if not OS.has_feature(expected):
		push_error("Exported PCK is missing required feature: %s" % expected)
		quit(1)
		return
	print("Export feature probe passed: %s=true" % expected)
	quit()
