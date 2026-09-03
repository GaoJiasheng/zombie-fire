extends "res://tools/m1_smoke_test.gd"

# Fast iteration entry point; the same assertions also run in the full M1 gate.
func _initialize() -> void:
	await process_frame
	root.size = Vector2i(1080, 1920)
	root.get_node("/root/DataLoader").load_all()
	await _verify_settings_info_content_layout()
	await _verify_character_detail_first_page_layout()
	await _verify_loadout_stage_summary_layout()
	root.get_node("/root/AudioManager").release_for_tests()
	print("ROUND3_SMOKE_OK")
	quit(0)
