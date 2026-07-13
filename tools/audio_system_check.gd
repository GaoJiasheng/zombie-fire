extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var errors := PackedStringArray()
	var audio_manager := root.get_node_or_null("AudioManager")
	if audio_manager == null:
		push_error("Audio system check failed: AudioManager autoload is missing")
		quit(1)
		return
	var diagnostics: Dictionary = audio_manager.get_audio_diagnostics(true)
	for issue in diagnostics.get("issues", PackedStringArray()):
		errors.append(str(issue))
	if int(diagnostics.get("bgm_player_count", 0)) != 2:
		errors.append("crossfade requires exactly two managed BGM players")
	if int(diagnostics.get("sfx_player_count", 0)) != 24:
		errors.append("SFX pool size must remain bounded at 24 players")
	if int(diagnostics.get("idle_sfx_stream_references", -1)) != 0:
		errors.append("idle SFX players retain stream references")
	if audio_manager.get_sfx_priority("boss_intro_tank_titan") <= audio_manager.get_sfx_priority("shot_autocannon"):
		errors.append("boss cues must outrank weapon shots")
	if audio_manager.get_sfx_concurrency_limit("hit_fire") > 3:
		errors.append("element hit concurrency limit is too high")
	if audio_manager.get_sfx_concurrency_limit("victory") != 1:
		errors.append("music-like SFX must be single-instance")
	if audio_manager.get_sfx_bus("ui_click") != &"UI" or audio_manager.get_sfx_bus("hit_fire") != &"SFX":
		errors.append("UI and combat SFX bus routing is incorrect")
	for bus_name in [&"BGM", &"SFX", &"UI"]:
		if AudioServer.get_bus_index(bus_name) < 0:
			errors.append("missing audio bus: %s" % bus_name)
	var original_volumes := {}
	for bus_name in [&"BGM", &"SFX", &"UI"]:
		original_volumes[bus_name] = audio_manager.get_bus_volume(bus_name)
	audio_manager.set_bgm_volume(0.5)
	audio_manager.set_sfx_volume(0.4)
	audio_manager.set_ui_volume(0.3)
	if absf(audio_manager.get_bus_volume(&"BGM") - 0.5) > 0.001:
		errors.append("BGM volume control did not round-trip")
	if absf(audio_manager.get_bus_volume(&"SFX") - 0.4) > 0.001:
		errors.append("SFX volume control did not round-trip")
	if absf(audio_manager.get_bus_volume(&"UI") - 0.3) > 0.001:
		errors.append("UI volume control did not round-trip")
	for bus_name in original_volumes:
		audio_manager.set_bus_volume(bus_name, float(original_volumes[bus_name]))
	audio_manager.set_enabled(false)
	for bus_name in [&"BGM", &"SFX", &"UI"]:
		if not AudioServer.is_bus_mute(AudioServer.get_bus_index(bus_name)):
			errors.append("global audio disable did not mute bus: %s" % bus_name)
	audio_manager.set_enabled(true)
	audio_manager.set("_headless_audio", false)
	audio_manager.play_bgm("menu", 0.0)
	await process_frame
	var playback: Dictionary = audio_manager.get_audio_diagnostics(false)
	if playback.get("current_bgm", "") != "menu" or int(playback.get("active_bgm_players", 0)) != 1:
		errors.append("BGM did not start as one active player")
	audio_manager.play_bgm("boss", 0.08)
	playback = audio_manager.get_audio_diagnostics(false)
	if playback.get("current_bgm", "") != "boss" or int(playback.get("active_bgm_players", 0)) != 2:
		errors.append("BGM crossfade did not use exactly two active players")
	await create_timer(0.12).timeout
	playback = audio_manager.get_audio_diagnostics(false)
	if int(playback.get("active_bgm_players", 0)) != 1:
		errors.append("BGM crossfade did not release its outgoing player")
	audio_manager.stop_bgm(0.05)
	await create_timer(0.08).timeout
	playback = audio_manager.get_audio_diagnostics(false)
	if int(playback.get("active_bgm_players", -1)) != 0:
		errors.append("BGM fade-out did not stop and release its player")
	audio_manager.set("_headless_audio", true)
	audio_manager.release_for_tests()
	await create_timer(0.12).timeout
	var released: Dictionary = audio_manager.get_audio_diagnostics(false)
	if int(released.get("active_bgm_players", -1)) != 0 or int(released.get("active_sfx_players", -1)) != 0:
		errors.append("release_for_tests left an active audio player")
	if int(released.get("idle_sfx_stream_references", -1)) != 0:
		errors.append("release_for_tests left an idle stream reference")
	if not errors.is_empty():
		for error in errors:
			push_error("Audio system check failed: %s" % error)
		quit(1)
		return
	print("Audio system check passed: buses, loops, priorities, concurrency, and player cleanup")
	quit(0)
