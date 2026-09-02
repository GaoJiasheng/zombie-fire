extends Node

const SFX := {
	"ui_click": "res://assets/production/audio/sfx/sfx_ui_click.wav",
	"ui_confirm": "res://assets/production/audio/sfx/sfx_ui_confirm.wav",
	"shot_autocannon": "res://assets/production/audio/sfx/sfx_shot_autocannon.wav",
	"shot_flamethrower": "res://assets/production/audio/sfx/sfx_shot_flamethrower.wav",
	"shot_cryocannon": "res://assets/production/audio/sfx/sfx_shot_cryocannon.wav",
	"shot_teslacoil": "res://assets/production/audio/sfx/sfx_shot_teslacoil.wav",
	"shot_venomlauncher": "res://assets/production/audio/sfx/sfx_shot_venomlauncher.wav",
	"shot_railgun": "res://assets/production/audio/sfx/sfx_shot_railgun.wav",
	"shot_scattergun": "res://assets/production/audio/sfx/sfx_shot_scattergun.wav",
	"shot_plasmacannon": "res://assets/production/audio/sfx/sfx_shot_plasmacannon.wav",
	"muzzle_fire": "res://assets/production/audio/sfx/sfx_muzzle_fire.wav",
	"muzzle_ice": "res://assets/production/audio/sfx/sfx_muzzle_ice.wav",
	"muzzle_lightning": "res://assets/production/audio/sfx/sfx_muzzle_lightning.wav",
	"muzzle_poison": "res://assets/production/audio/sfx/sfx_muzzle_poison.wav",
	"hit_physical": "res://assets/production/audio/sfx/sfx_hit_physical.wav",
	"hit_fire": "res://assets/production/audio/sfx/sfx_hit_fire.wav",
	"hit_ice": "res://assets/production/audio/sfx/sfx_hit_ice.wav",
	"hit_lightning": "res://assets/production/audio/sfx/sfx_hit_lightning.wav",
	"hit_poison": "res://assets/production/audio/sfx/sfx_hit_poison.wav",
	"hit_immune": "res://assets/production/audio/sfx/sfx_hit_immune.wav",
	"skill_split_shot": "res://assets/production/audio/sfx/sfx_skill_split_shot.wav",
	"skill_pierce": "res://assets/production/audio/sfx/sfx_skill_pierce.wav",
	"skill_multishot": "res://assets/production/audio/sfx/sfx_skill_multishot.wav",
	"skill_slow_field": "res://assets/production/audio/sfx/sfx_skill_slow_field.wav",
	"skill_homing": "res://assets/production/audio/sfx/sfx_skill_homing.wav",
	"skill_critical": "res://assets/production/audio/sfx/sfx_skill_critical.wav",
	"skill_barrier": "res://assets/production/audio/sfx/sfx_skill_barrier.wav",
	"skill_gold_rush": "res://assets/production/audio/sfx/sfx_skill_gold_rush.wav",
	"skill_ricochet": "res://assets/production/audio/sfx/sfx_skill_ricochet.wav",
	"skill_salvo": "res://assets/production/audio/sfx/sfx_skill_salvo.wav",
	"skill_incendiary": "res://assets/production/audio/sfx/sfx_skill_incendiary.wav",
	"skill_cryo": "res://assets/production/audio/sfx/sfx_skill_cryo.wav",
	"skill_tesla": "res://assets/production/audio/sfx/sfx_skill_tesla.wav",
	"skill_venom": "res://assets/production/audio/sfx/sfx_skill_venom.wav",
	"skill_charge_shot_charge": "res://assets/production/audio/sfx/sfx_skill_charge_shot_charge.wav",
	"skill_charge_shot_release": "res://assets/production/audio/sfx/sfx_skill_charge_shot_release.wav",
	"skill_recycle": "res://assets/production/audio/sfx/sfx_skill_recycle.wav",
	"apocalypse_inferno_ignition": "res://assets/production/audio/sfx/sfx_apocalypse_inferno_ignition.wav",
	"apocalypse_inferno_combustion": "res://assets/production/audio/sfx/sfx_apocalypse_inferno_combustion.wav",
	"apocalypse_inferno_phoenix": "res://assets/production/audio/sfx/sfx_apocalypse_inferno_phoenix.wav",
	"apocalypse_inferno_counter": "res://assets/production/audio/sfx/sfx_apocalypse_inferno_counter.wav",
	"apocalypse_inferno_awakening": "res://assets/production/audio/sfx/sfx_apocalypse_inferno_awakening.wav",
	"apocalypse_absolute_zero_fire": "res://assets/production/audio/sfx/sfx_apocalypse_absolute_zero_fire.wav",
	"apocalypse_absolute_zero_shatter": "res://assets/production/audio/sfx/sfx_apocalypse_absolute_zero_shatter.wav",
	"apocalypse_absolute_zero_field": "res://assets/production/audio/sfx/sfx_apocalypse_absolute_zero_field.wav",
	"apocalypse_absolute_zero_counter": "res://assets/production/audio/sfx/sfx_apocalypse_absolute_zero_counter.wav",
	"apocalypse_absolute_zero_awakening": "res://assets/production/audio/sfx/sfx_apocalypse_absolute_zero_awakening.wav",
	"apocalypse_golden_law_fire": "res://assets/production/audio/sfx/sfx_apocalypse_golden_law_fire.wav",
	"apocalypse_golden_law_impact": "res://assets/production/audio/sfx/sfx_apocalypse_golden_law_impact.wav",
	"apocalypse_golden_law_decree": "res://assets/production/audio/sfx/sfx_apocalypse_golden_law_decree.wav",
	"apocalypse_golden_law_falcon": "res://assets/production/audio/sfx/sfx_apocalypse_golden_law_falcon.wav",
	"apocalypse_golden_law_counter": "res://assets/production/audio/sfx/sfx_apocalypse_golden_law_counter.wav",
	"apocalypse_golden_law_awakening": "res://assets/production/audio/sfx/sfx_apocalypse_golden_law_awakening.wav",
	"char_vanguard_intro": "res://assets/production/audio/sfx/sfx_char_vanguard_intro.wav",
	"sig_vanguard_railvolley": "res://assets/production/audio/sfx/sfx_sig_vanguard_railvolley.wav",
	"char_blaze_intro": "res://assets/production/audio/sfx/sfx_char_blaze_intro.wav",
	"sig_blaze_meltdown": "res://assets/production/audio/sfx/sfx_sig_blaze_meltdown.wav",
	"char_frost_intro": "res://assets/production/audio/sfx/sfx_char_frost_intro.wav",
	"sig_frost_glacier": "res://assets/production/audio/sfx/sfx_sig_frost_glacier.wav",
	"char_volt_intro": "res://assets/production/audio/sfx/sfx_char_volt_intro.wav",
	"sig_volt_storm": "res://assets/production/audio/sfx/sfx_sig_volt_storm.wav",
	"zombie_screamer": "res://assets/production/audio/sfx/sfx_zombie_screamer.wav",
	"zombie_spitter": "res://assets/production/audio/sfx/sfx_zombie_spitter.wav",
	"zombie_shielder": "res://assets/production/audio/sfx/sfx_zombie_shielder.wav",
	"zombie_hopper": "res://assets/production/audio/sfx/sfx_zombie_hopper.wav",
	"zombie_juggernaut": "res://assets/production/audio/sfx/sfx_zombie_juggernaut.wav",
	"zombie_phantom": "res://assets/production/audio/sfx/sfx_zombie_phantom.wav",
	"zombie_necromancer": "res://assets/production/audio/sfx/sfx_zombie_necromancer.wav",
	"zombie_toxic": "res://assets/production/audio/sfx/sfx_zombie_toxic.wav",
	"zombie_charger": "res://assets/production/audio/sfx/sfx_zombie_charger.wav",
	"zombie_regenerator": "res://assets/production/audio/sfx/sfx_zombie_regenerator.wav",
	"zombie_splitter": "res://assets/production/audio/sfx/sfx_zombie_splitter.wav",
	"zombie_warden": "res://assets/production/audio/sfx/sfx_zombie_warden.wav",
	"zombie_mutant": "res://assets/production/audio/sfx/sfx_zombie_mutant.wav",
	"zombie_berserker": "res://assets/production/audio/sfx/sfx_zombie_berserker.wav",
	"zombie_runner": "res://assets/production/audio/sfx/sfx_zombie_runner.wav",
	"zombie_bomber": "res://assets/production/audio/sfx/sfx_zombie_bomber.wav",
	"zombie_shambler": "res://assets/production/audio/sfx/sfx_zombie_shambler.wav",
	"zombie_brute": "res://assets/production/audio/sfx/sfx_zombie_brute.wav",
	"zombie_armored": "res://assets/production/audio/sfx/sfx_zombie_armored.wav",
	"zombie_crawler": "res://assets/production/audio/sfx/sfx_zombie_crawler.wav",
	"enemy_death": "res://assets/production/audio/sfx/sfx_enemy_death_small.wav",
	"enemy_attack_claw": "res://assets/production/audio/sfx/sfx_enemy_attack_claw.wav",
	"enemy_attack_fast_claw": "res://assets/production/audio/sfx/sfx_enemy_attack_fast_claw.wav",
	"enemy_attack_bite": "res://assets/production/audio/sfx/sfx_enemy_attack_bite.wav",
	"enemy_attack_heavy_slam": "res://assets/production/audio/sfx/sfx_enemy_attack_heavy_slam.wav",
	"enemy_attack_blast": "res://assets/production/audio/sfx/sfx_enemy_attack_blast.wav",
	"enemy_attack_corrosion": "res://assets/production/audio/sfx/sfx_enemy_attack_corrosion.wav",
	"enemy_attack_support": "res://assets/production/audio/sfx/sfx_enemy_attack_support.wav",
	"enemy_breach": "res://assets/production/audio/sfx/sfx_enemy_breach.wav",
	"threat_warning": "res://assets/production/audio/sfx/sfx_threat_warning.wav",
	"level_up": "res://assets/production/audio/sfx/sfx_level_up.wav",
	"card_offer": "res://assets/production/audio/sfx/sfx_ui_card_offer.wav",
	"card_pick": "res://assets/production/audio/sfx/sfx_ui_card_pick.wav",
	"reroll": "res://assets/production/audio/sfx/sfx_reroll.wav",
	"pause": "res://assets/production/audio/sfx/sfx_pause.wav",
	"resume": "res://assets/production/audio/sfx/sfx_resume.wav",
	"lock": "res://assets/production/audio/sfx/sfx_lock_target.wav",
	"upgrade": "res://assets/production/audio/sfx/sfx_upgrade_weapon.wav",
	"gold_pickup": "res://assets/production/audio/sfx/sfx_gold_pickup.wav",
	"star_gain": "res://assets/production/audio/sfx/sfx_star_gain.wav",
	"boss_intro_tank_titan": "res://assets/production/audio/sfx/sfx_boss_intro_tank_titan.wav",
	"boss_intro_inferno_maw": "res://assets/production/audio/sfx/sfx_boss_intro_inferno_maw.wav",
	"boss_intro_frost_warden": "res://assets/production/audio/sfx/sfx_boss_intro_frost_warden.wav",
	"boss_intro_storm_caller": "res://assets/production/audio/sfx/sfx_boss_intro_storm_caller.wav",
	"boss_intro_plague_mother": "res://assets/production/audio/sfx/sfx_boss_intro_plague_mother.wav",
	"boss_intro_void_phantom": "res://assets/production/audio/sfx/sfx_boss_intro_void_phantom.wav",
	"boss_intro_necrotitan": "res://assets/production/audio/sfx/sfx_boss_intro_necrotitan.wav",
	"boss_intro_apex_overlord": "res://assets/production/audio/sfx/sfx_boss_intro_apex_overlord.wav",
	"victory": "res://assets/production/audio/sfx/sfx_victory.wav",
	"defeat": "res://assets/production/audio/sfx/sfx_defeat.wav",
}

const BGM := {
	"menu": "res://assets/production/audio/bgm/bgm_menu.wav",
	"map": "res://assets/production/audio/bgm/bgm_map.wav",
	"battle": "res://assets/production/audio/bgm/bgm_battle_city.wav",
	"battle_city": "res://assets/production/audio/bgm/bgm_battle_city.wav",
	"battle_subway": "res://assets/production/audio/bgm/bgm_battle_subway.wav",
	"battle_biolab": "res://assets/production/audio/bgm/bgm_battle_biolab.wav",
	"battle_military": "res://assets/production/audio/bgm/bgm_battle_military.wav",
	"boss": "res://assets/production/audio/bgm/bgm_boss.wav",
	"victory": "res://assets/production/audio/bgm/bgm_result_victory.wav",
	"defeat": "res://assets/production/audio/bgm/bgm_result_defeat.wav",
}

const MUSIC_LIKE_SFX := {
	"sig_vanguard_railvolley": true,
	"sig_blaze_meltdown": true,
	"sig_frost_glacier": true,
	"sig_volt_storm": true,
	"victory": true,
	"defeat": true,
}

const UI_SFX := {
	"ui_click": true,
	"ui_confirm": true,
	"level_up": true,
	"card_offer": true,
	"card_pick": true,
	"reroll": true,
	"pause": true,
	"resume": true,
	"lock": true,
	"upgrade": true,
	"gold_pickup": true,
	"star_gain": true,
}

const AUDIO_BUSES := [&"BGM", &"SFX", &"UI"]
const BGM_PLAYER_COUNT := 2
const SFX_POOL_SIZE := 24
const DEFAULT_BGM_FADE_SECONDS := 0.45
const DEFAULT_BGM_STOP_FADE_SECONDS := 0.25
const SILENT_DB := -80.0
const BGM_DUCK_ATTACK_DB_PER_SECOND := 46.0
const BGM_DUCK_RELEASE_DB_PER_SECOND := 14.0
const ENEMY_FOLEY_GROUP := "enemy_foley"

var enabled := true
var _sfx_cache := {}
var _bgm_cache := {}
var _bgm_players: Array[AudioStreamPlayer] = []
var _sfx_pool: Array[AudioStreamPlayer] = []
var _current_bgm := ""
var _last_sfx_time := {}
var _headless_audio := false
var _active_bgm_index := -1
var _bgm_transition := {}
var _manual_paused := false
var _application_paused := false
var _tree_paused := false
var _pause_ui_too := false
var _missing_audio_reported := {}
var _bgm_duck_db := 0.0
var _bgm_duck_target_db := 0.0
var _bgm_duck_hold_until_msec := 0
## 阶段 67：按环境的空间声学做混音。数值来自 data/environments.json.audio_mix，
## 代码里不写死任何一条曲线。
var _env_sfx_db := 0.0
var _env_bgm_db := 0.0
var _env_mix_id := ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_headless_audio = DisplayServer.get_name() == "headless"
	for i in range(BGM_PLAYER_COUNT):
		var bgm_player := AudioStreamPlayer.new()
		bgm_player.name = "BGMPlayer%d" % i
		bgm_player.bus = &"BGM"
		bgm_player.volume_db = SILENT_DB
		bgm_player.set_meta("base_gain", 0.0)
		add_child(bgm_player)
		_bgm_players.append(bgm_player)
	for i in range(SFX_POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.name = "SFXPlayer%02d" % i
		player.bus = &"SFX"
		player.volume_db = 0.0
		player.finished.connect(_on_sfx_finished.bind(player))
		add_child(player)
		_sfx_pool.append(player)
	_set_managed_buses_muted(not enabled)
	var startup_issues := validate_audio_configuration(false)
	for issue in startup_issues:
		push_warning("AudioManager: %s" % issue)

func _process(delta: float) -> void:
	_update_bgm_transition(delta)
	_update_bgm_duck(delta)
	var tree_paused_now := get_tree() != null and get_tree().paused
	if tree_paused_now != _tree_paused:
		_tree_paused = tree_paused_now
		_sync_pause_state()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		_application_paused = true
		_sync_pause_state()
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		_application_paused = false
		_sync_pause_state()

func _exit_tree() -> void:
	release_for_tests()

func play_bgm(id: String, fade_duration := DEFAULT_BGM_FADE_SECONDS) -> void:
	if _headless_audio:
		return
	if not BGM.has(id):
		_report_missing_audio("BGM id '%s' is not registered" % id)
		return
	if _current_bgm == id and _active_bgm_index >= 0 and _bgm_players[_active_bgm_index].playing:
		return
	_clear_bgm_duck()
	_stop_music_like_sfx()
	var stream := _load_bgm(id)
	if stream == null:
		return
	_complete_bgm_transition()
	var previous_index := _active_bgm_index
	var next_index := 0 if previous_index != 0 else 1
	var next_player := _bgm_players[next_index]
	_clear_bgm_player(next_player)
	next_player.stream = stream
	next_player.volume_db = SILENT_DB
	next_player.play()
	_current_bgm = id
	_active_bgm_index = next_index
	_begin_bgm_transition(previous_index, next_index, maxf(0.0, float(fade_duration)))
	_sync_pause_state()

func stop_bgm(fade_duration := DEFAULT_BGM_STOP_FADE_SECONDS) -> void:
	_current_bgm = ""
	_complete_bgm_transition()
	if _active_bgm_index < 0:
		return
	var previous_index := _active_bgm_index
	_active_bgm_index = -1
	_begin_bgm_transition(previous_index, -1, maxf(0.0, float(fade_duration)))

func release_for_tests() -> void:
	_current_bgm = ""
	_bgm_transition.clear()
	_active_bgm_index = -1
	_bgm_duck_db = 0.0
	_bgm_duck_target_db = 0.0
	_bgm_duck_hold_until_msec = 0
	for player in _bgm_players:
		_clear_bgm_player(player)
		player.free()
	for player in _sfx_pool:
		_clear_sfx_player(player)
		player.free()
	_bgm_players.clear()
	_sfx_pool.clear()
	_sfx_cache.clear()
	_bgm_cache.clear()
	_last_sfx_time.clear()
	_missing_audio_reported.clear()

func play_sfx(id: String, volume_db := 0.0, pitch_variation := 0.04) -> void:
	_play_sfx_internal(id, volume_db, pitch_variation, "", false)

func play_enemy_sfx(id: String, volume_db := 0.0, pitch_variation := 0.04, force_interrupt := false) -> void:
	# All zombie motion, casts, attacks, deaths, defense warnings and real base
	# contacts share one authored lane. Crowd density may choose which action is
	# audible, but it must never turn one event into several simultaneous clips.
	# A real contact/warning replaces the current action instead of layering over it.
	_play_sfx_internal(id, volume_db, pitch_variation, ENEMY_FOLEY_GROUP, force_interrupt or enemy_sfx_interrupts_current(id))

func enemy_sfx_interrupts_current(id: String) -> bool:
	return id in ["enemy_breach", "threat_warning", "hit_immune"]

func _play_sfx_internal(id: String, volume_db: float, pitch_variation: float, exclusive_group: String, interrupt_group: bool) -> void:
	if _headless_audio or not enabled:
		return
	if not SFX.has(id):
		_report_missing_audio("SFX id '%s' is not registered" % id)
		return
	if not exclusive_group.is_empty() and _has_playing_sfx_group(exclusive_group):
		if not interrupt_group:
			return
		# Contact/defense priority must silence the previous zombie tail even when
		# the incoming high-priority cue is itself rate-limited by a recent hit.
		_stop_sfx_group(exclusive_group)
	if _is_rate_limited(id):
		return
	var stream := _load_sfx(id)
	if stream == null:
		return
	if MUSIC_LIKE_SFX.has(id):
		_stop_music_like_sfx()
	var priority := get_sfx_priority(id)
	var player := _select_sfx_player(id, priority)
	if player == null:
		return
	_clear_sfx_player(player)
	player.stream = stream
	player.bus = get_sfx_bus(id)
	player.volume_db = float(volume_db) + (_env_sfx_db if player.bus == &"SFX" else 0.0)
	var variation := absf(float(pitch_variation))
	player.pitch_scale = randf_range(maxf(0.01, 1.0 - variation), 1.0 + variation)
	player.set_meta("audio_id", id)
	player.set_meta("exclusive_group", exclusive_group)
	player.set_meta("music_like", MUSIC_LIKE_SFX.has(id))
	player.set_meta("priority", priority)
	player.set_meta("started_msec", Time.get_ticks_msec())
	player.play()
	player.stream_paused = _should_pause_player(player)
	_request_bgm_duck_for_sfx(id)

func _request_bgm_duck_for_sfx(id: String) -> void:
	if id.begins_with("boss_intro_"):
		request_bgm_duck(-8.0, 1.45)
	elif id.begins_with("sig_") or id.begins_with("char_"):
		request_bgm_duck(-6.0, 1.05)
	elif id in ["enemy_breach", "threat_warning"]:
		request_bgm_duck(-4.5, 0.62)
	elif id in ["victory", "defeat"]:
		request_bgm_duck(-5.5, 0.90)

func request_bgm_duck(target_db: float, hold_seconds: float) -> void:
	var bounded_target := clampf(target_db, -12.0, 0.0)
	_bgm_duck_target_db = minf(_bgm_duck_target_db, bounded_target)
	_bgm_duck_hold_until_msec = maxi(
		_bgm_duck_hold_until_msec,
		Time.get_ticks_msec() + int(round(maxf(hold_seconds, 0.0) * 1000.0))
	)

func _clear_bgm_duck() -> void:
	_bgm_duck_db = 0.0
	_bgm_duck_target_db = 0.0
	_bgm_duck_hold_until_msec = 0
	_apply_bgm_player_volumes()

func _update_bgm_duck(delta: float) -> void:
	if Time.get_ticks_msec() > _bgm_duck_hold_until_msec:
		_bgm_duck_target_db = 0.0
	var rate := BGM_DUCK_ATTACK_DB_PER_SECOND if _bgm_duck_target_db < _bgm_duck_db else BGM_DUCK_RELEASE_DB_PER_SECOND
	var next_db := move_toward(_bgm_duck_db, _bgm_duck_target_db, maxf(delta, 0.0) * rate)
	if not is_equal_approx(next_db, _bgm_duck_db):
		_bgm_duck_db = next_db
		_apply_bgm_player_volumes()

func _apply_bgm_player_volumes() -> void:
	for player in _bgm_players:
		var base_gain := float(player.get_meta("base_gain", 0.0))
		player.volume_db = SILENT_DB if base_gain <= 0.0001 else _gain_to_db(base_gain) + _bgm_duck_db + _env_bgm_db

func _set_bgm_player_gain(player: AudioStreamPlayer, gain: float) -> void:
	if player == null:
		return
	var bounded_gain := clampf(gain, 0.0, 1.0)
	player.set_meta("base_gain", bounded_gain)
	player.volume_db = SILENT_DB if bounded_gain <= 0.0001 else _gain_to_db(bounded_gain) + _bgm_duck_db + _env_bgm_db

func _is_rate_limited(id: String) -> bool:
	var min_gap := 0.0
	match id:
		"hit_physical", "hit_fire", "hit_ice", "hit_lightning", "hit_poison", "hit_immune":
			min_gap = 0.045
		"shot_autocannon", "shot_flamethrower", "shot_cryocannon", "shot_teslacoil", "shot_venomlauncher", "shot_railgun", "shot_scattergun", "shot_plasmacannon":
			min_gap = 0.035
		"muzzle_fire", "muzzle_ice", "muzzle_lightning", "muzzle_poison":
			min_gap = 0.06
		"skill_split_shot", "skill_pierce", "skill_multishot", "skill_ricochet", "skill_incendiary", "skill_cryo", "skill_tesla", "skill_venom", "skill_critical", "skill_homing":
			min_gap = 0.09
		"skill_salvo", "skill_charge_shot_release":
			min_gap = 0.16
		"apocalypse_inferno_ignition":
			min_gap = 0.065
		"apocalypse_inferno_combustion":
			min_gap = 0.34
		"apocalypse_inferno_phoenix", "apocalypse_inferno_counter", "apocalypse_inferno_awakening":
			min_gap = 0.8
		"apocalypse_absolute_zero_fire":
			min_gap = 0.065
		"apocalypse_absolute_zero_shatter":
			min_gap = 0.34
		"apocalypse_absolute_zero_field", "apocalypse_absolute_zero_counter", "apocalypse_absolute_zero_awakening":
			min_gap = 0.8
		"apocalypse_golden_law_fire":
			min_gap = 0.065
		"apocalypse_golden_law_impact":
			min_gap = 0.34
		"apocalypse_golden_law_decree", "apocalypse_golden_law_falcon", "apocalypse_golden_law_counter", "apocalypse_golden_law_awakening":
			min_gap = 0.8
		"sig_vanguard_railvolley", "sig_blaze_meltdown", "sig_frost_glacier", "sig_volt_storm":
			min_gap = 1.2
		"skill_gold_rush", "skill_slow_field", "skill_barrier", "skill_charge_shot_charge", "skill_recycle":
			min_gap = 0.28
		"zombie_runner":
			min_gap = 0.38
		"zombie_spitter", "zombie_hopper", "zombie_charger", "zombie_phantom", "zombie_mutant", "zombie_berserker", "zombie_bomber", "zombie_splitter":
			min_gap = 0.55
		"zombie_screamer", "zombie_shielder", "zombie_warden", "zombie_juggernaut", "zombie_necromancer", "zombie_toxic", "zombie_regenerator", "zombie_shambler", "zombie_brute", "zombie_armored", "zombie_crawler":
			min_gap = 0.9
		"enemy_death":
			min_gap = 0.04
		"enemy_attack_claw", "enemy_attack_fast_claw", "enemy_attack_bite", "enemy_attack_heavy_slam", "enemy_attack_blast", "enemy_attack_corrosion", "enemy_attack_support":
			min_gap = 0.14
		"enemy_breach", "threat_warning":
			min_gap = 0.75
		"victory", "defeat":
			min_gap = 0.8
		"gold_pickup":
			min_gap = 0.12
		_:
			min_gap = 0.0
	if min_gap <= 0.0:
		return false
	var now := Time.get_ticks_msec() / 1000.0
	var last := float(_last_sfx_time.get(id, -999.0))
	if now - last < min_gap:
		return true
	_last_sfx_time[id] = now
	return false

func toggle_enabled() -> bool:
	set_enabled(not enabled)
	return enabled

func set_enabled(value: bool) -> void:
	enabled = value
	_set_managed_buses_muted(not enabled)

func set_bgm_volume(value: float) -> void:
	set_bus_volume(&"BGM", value)

func set_sfx_volume(value: float) -> void:
	set_bus_volume(&"SFX", value)

## 阶段 67 · 按环境的动态混音。熔岩铸厂、冰川断桥、沉没地铁、虚空圣堂……
## 各自的空间不同，同一把枪在里面不该是同一个声音。三条参数全部来自
## data/environments.json 的 `audio_mix`，这里只负责把它们套到总线上：
##   sfx_db / bgm_db  ——  以**播放器音量偏移**的形式施加，绝不写总线音量，
##                        否则会和设置页的音量滑杆互相覆盖。
##   reverb_*         ——  施加在 SFX 总线的混响上；UI 音效走 UI 总线，永远保持干声。
## 战斗进入时调用，离开战斗时用 clear_environment_mix() 归零。
func apply_environment_mix(environment_id: String) -> void:
	# Resolve the autoload at runtime instead of introducing a compile-time dependency.
	# This keeps standalone audio/smoke checks valid while preserving the normal runtime path.
	var data_loader := get_node_or_null("/root/DataLoader")
	if data_loader == null or not data_loader.has_method("get_row"):
		clear_environment_mix()
		return
	var row_var: Variant = data_loader.call("get_row", "environments", environment_id)
	var row: Dictionary = row_var if row_var is Dictionary else {}
	var mix_var: Variant = row.get("audio_mix", {})
	if not (mix_var is Dictionary) or (mix_var as Dictionary).is_empty():
		clear_environment_mix()
		return
	var mix: Dictionary = mix_var
	_env_mix_id = environment_id
	_env_sfx_db = clampf(float(mix.get("sfx_db", 0.0)), -6.0, 6.0)
	_env_bgm_db = clampf(float(mix.get("bgm_db", 0.0)), -6.0, 6.0)
	_apply_sfx_reverb(
		clampf(float(mix.get("reverb_wet", 0.0)), 0.0, 0.35),
		clampf(float(mix.get("reverb_room", 0.5)), 0.0, 1.0),
		clampf(float(mix.get("reverb_damping", 0.5)), 0.0, 1.0)
	)
	_apply_bgm_player_volumes()

func clear_environment_mix() -> void:
	_env_mix_id = ""
	_env_sfx_db = 0.0
	_env_bgm_db = 0.0
	_apply_sfx_reverb(0.0, 0.5, 0.5)
	_apply_bgm_player_volumes()

func current_environment_mix_id() -> String:
	return _env_mix_id

func environment_sfx_trim_db() -> float:
	return _env_sfx_db

func environment_bgm_trim_db() -> float:
	return _env_bgm_db

func sfx_reverb_wet() -> float:
	var reverb := _sfx_reverb_effect()
	return 0.0 if reverb == null else reverb.wet

func _sfx_reverb_effect() -> AudioEffectReverb:
	var bus_index := AudioServer.get_bus_index(&"SFX")
	if bus_index < 0 or AudioServer.get_bus_effect_count(bus_index) <= 0:
		return null
	return AudioServer.get_bus_effect(bus_index, 0) as AudioEffectReverb

func _apply_sfx_reverb(wet: float, room_size: float, damping: float) -> void:
	var reverb := _sfx_reverb_effect()
	if reverb == null:
		return
	reverb.wet = wet
	reverb.dry = 1.0
	reverb.room_size = room_size
	reverb.damping = damping

func set_ui_volume(value: float) -> void:
	set_bus_volume(&"UI", value)

func set_bus_volume(bus_name: StringName, value: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		_report_missing_audio("audio bus '%s' is missing" % bus_name)
		return
	var linear_value := clampf(value, 0.0, 1.0)
	AudioServer.set_bus_volume_db(bus_index, SILENT_DB if linear_value <= 0.0001 else linear_to_db(linear_value))

func get_bus_volume(bus_name: StringName) -> float:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return 0.0
	var volume_db := AudioServer.get_bus_volume_db(bus_index)
	return 0.0 if volume_db <= SILENT_DB else db_to_linear(volume_db)

func pause_audio(include_ui := false) -> void:
	_manual_paused = true
	_pause_ui_too = bool(include_ui)
	_sync_pause_state()

func resume_audio() -> void:
	_manual_paused = false
	_pause_ui_too = false
	_sync_pause_state()

func _load_sfx(id: String) -> AudioStream:
	if not _sfx_cache.has(id):
		var path := str(SFX[id])
		if not ResourceLoader.exists(path):
			_report_missing_audio("missing SFX asset for '%s': %s" % [id, path])
			return null
		_sfx_cache[id] = load(path)
	return _sfx_cache[id]

func _load_bgm(id: String) -> AudioStream:
	if not _bgm_cache.has(id):
		var path := str(BGM[id])
		if not ResourceLoader.exists(path):
			_report_missing_audio("missing BGM asset for '%s': %s" % [id, path])
			return null
		var stream: AudioStream = load(path)
		if stream is AudioStreamWAV:
			(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
		_bgm_cache[id] = stream
	return _bgm_cache[id]

func _stop_music_like_sfx() -> void:
	for player in _sfx_pool:
		if player == null:
			continue
		if player.playing and bool(player.get_meta("music_like", false)):
			_clear_sfx_player(player)
		elif not player.playing and bool(player.get_meta("music_like", false)):
			_clear_sfx_player(player)

func get_sfx_priority(id: String) -> int:
	if id.begins_with("boss_intro_") or id in ["enemy_breach", "threat_warning", "victory", "defeat"]:
		return 100
	if id in ["hit_immune", "level_up", "card_offer", "card_pick", "pause", "resume", "lock"]:
		return 85
	if id.begins_with("sig_") or id.begins_with("char_") or id.begins_with("skill_"):
		return 70
	if UI_SFX.has(id):
		return 65
	if id.begins_with("zombie_"):
		return 50
	if id.begins_with("enemy_attack_"):
		return 48
	if id.begins_with("hit_"):
		return 40
	if id.begins_with("shot_") or id.begins_with("muzzle_"):
		return 30
	if id == "enemy_death":
		return 20
	return 45

func get_sfx_concurrency_limit(id: String) -> int:
	if MUSIC_LIKE_SFX.has(id) or id.begins_with("boss_intro_") or id in ["enemy_breach", "threat_warning", "hit_immune"]:
		return 1
	if id.begins_with("shot_") or id.begins_with("muzzle_") or id.begins_with("hit_"):
		return 3
	if id == "enemy_death" or id.begins_with("zombie_") or id.begins_with("enemy_attack_"):
		return 2
	if UI_SFX.has(id):
		return 2
	return 2

func get_sfx_bus(id: String) -> StringName:
	return &"UI" if UI_SFX.has(id) else &"SFX"

func validate_audio_configuration(load_streams := false) -> PackedStringArray:
	var issues := PackedStringArray()
	for bus_name in AUDIO_BUSES:
		if AudioServer.get_bus_index(bus_name) < 0:
			issues.append("missing audio bus: %s" % bus_name)
	for id in BGM:
		var path := str(BGM[id])
		if not ResourceLoader.exists(path):
			issues.append("missing BGM asset for '%s': %s" % [id, path])
		elif load_streams:
			var stream: AudioStream = load(path)
			if stream == null:
				issues.append("BGM asset failed to load for '%s': %s" % [id, path])
			elif stream is AudioStreamWAV and (stream as AudioStreamWAV).loop_mode == AudioStreamWAV.LOOP_DISABLED:
				issues.append("BGM loop is disabled for '%s': %s" % [id, path])
	for id in SFX:
		var path := str(SFX[id])
		if not ResourceLoader.exists(path):
			issues.append("missing SFX asset for '%s': %s" % [id, path])
	if _bgm_players.size() != BGM_PLAYER_COUNT:
		issues.append("BGM player leak/config mismatch: expected %d, found %d" % [BGM_PLAYER_COUNT, _bgm_players.size()])
	if _sfx_pool.size() != SFX_POOL_SIZE:
		issues.append("SFX player leak/config mismatch: expected %d, found %d" % [SFX_POOL_SIZE, _sfx_pool.size()])
	var player_instance_ids := {}
	for player in _bgm_players + _sfx_pool:
		if player == null or player.get_parent() != self:
			issues.append("audio player is null or detached from AudioManager")
			continue
		var instance_id := player.get_instance_id()
		if player_instance_ids.has(instance_id):
			issues.append("audio player is registered more than once: %s" % instance_id)
		player_instance_ids[instance_id] = true
	var element_paths := {}
	for element_id in ["hit_physical", "hit_fire", "hit_ice", "hit_lightning", "hit_poison"]:
		if not SFX.has(element_id):
			issues.append("element hit entry is missing: %s" % element_id)
			continue
		var element_path := str(SFX[element_id])
		if element_paths.has(element_path):
			issues.append("element hit entries share an asset: %s and %s" % [element_paths[element_path], element_id])
		element_paths[element_path] = element_id
	return issues

func get_audio_diagnostics(load_streams := false) -> Dictionary:
	var active_sfx := 0
	var idle_stream_references := 0
	for player in _sfx_pool:
		if player.playing:
			active_sfx += 1
		elif player.stream != null:
			idle_stream_references += 1
	return {
		"issues": validate_audio_configuration(load_streams),
		"current_bgm": _current_bgm,
		"active_bgm_players": _count_active_bgm_players(),
		"active_sfx_players": active_sfx,
		"idle_sfx_stream_references": idle_stream_references,
		"bgm_player_count": _bgm_players.size(),
		"sfx_player_count": _sfx_pool.size(),
		"headless": _headless_audio,
		"enabled": enabled,
		"bgm_duck_db": _bgm_duck_db,
		"bgm_duck_target_db": _bgm_duck_target_db,
	}

func _select_sfx_player(id: String, priority: int) -> AudioStreamPlayer:
	if _count_playing_sfx(id) >= get_sfx_concurrency_limit(id):
		return null
	for player in _sfx_pool:
		if not player.playing:
			return player
	var candidate: AudioStreamPlayer = null
	var candidate_priority := 1000000
	var candidate_started := 0
	for player in _sfx_pool:
		var active_priority := int(player.get_meta("priority", 0))
		var active_started := int(player.get_meta("started_msec", 0))
		if candidate == null or active_priority < candidate_priority or (active_priority == candidate_priority and active_started < candidate_started):
			candidate = player
			candidate_priority = active_priority
			candidate_started = active_started
	if candidate == null or priority <= candidate_priority:
		return null
	return candidate

func _count_playing_sfx(id: String) -> int:
	var count := 0
	for player in _sfx_pool:
		if player.playing and str(player.get_meta("audio_id", "")) == id:
			count += 1
	return count

func _has_playing_sfx_group(group_id: String) -> bool:
	for player in _sfx_pool:
		if player.playing and str(player.get_meta("exclusive_group", "")) == group_id:
			return true
	return false

func _stop_sfx_group(group_id: String) -> void:
	for player in _sfx_pool:
		if player.playing and str(player.get_meta("exclusive_group", "")) == group_id:
			_clear_sfx_player(player)

func _on_sfx_finished(player: AudioStreamPlayer) -> void:
	_clear_sfx_player(player)

func _clear_sfx_player(player: AudioStreamPlayer) -> void:
	if player == null:
		return
	player.stop()
	player.stream_paused = false
	player.stream = null
	player.bus = &"SFX"
	player.volume_db = 0.0
	player.pitch_scale = 1.0
	player.set_meta("audio_id", "")
	player.set_meta("exclusive_group", "")
	player.set_meta("music_like", false)
	player.set_meta("priority", 0)
	player.set_meta("started_msec", 0)

func _begin_bgm_transition(from_index: int, to_index: int, duration: float) -> void:
	if duration <= 0.0:
		if from_index >= 0 and from_index != to_index:
			_clear_bgm_player(_bgm_players[from_index])
		if to_index >= 0:
			_set_bgm_player_gain(_bgm_players[to_index], 1.0)
		_bgm_transition.clear()
		return
	_bgm_transition = {
		"from": from_index,
		"to": to_index,
		"elapsed": 0.0,
		"duration": duration,
	}
	_update_bgm_transition(0.0)

func _update_bgm_transition(delta: float) -> void:
	if _bgm_transition.is_empty():
		return
	var duration := maxf(0.001, float(_bgm_transition["duration"]))
	var elapsed := minf(duration, float(_bgm_transition["elapsed"]) + delta)
	_bgm_transition["elapsed"] = elapsed
	var weight := elapsed / duration
	var from_index := int(_bgm_transition["from"])
	var to_index := int(_bgm_transition["to"])
	if from_index >= 0:
		_set_bgm_player_gain(_bgm_players[from_index], 1.0 - weight)
	if to_index >= 0:
		_set_bgm_player_gain(_bgm_players[to_index], weight)
	if elapsed >= duration:
		_complete_bgm_transition()

func _complete_bgm_transition() -> void:
	if _bgm_transition.is_empty():
		return
	var from_index := int(_bgm_transition["from"])
	var to_index := int(_bgm_transition["to"])
	if from_index >= 0 and from_index != to_index:
		_clear_bgm_player(_bgm_players[from_index])
	if to_index >= 0:
		_set_bgm_player_gain(_bgm_players[to_index], 1.0)
	_bgm_transition.clear()

func _gain_to_db(gain: float) -> float:
	return SILENT_DB if gain <= 0.0001 else linear_to_db(gain)

func _clear_bgm_player(player: AudioStreamPlayer) -> void:
	if player == null:
		return
	player.stop()
	player.stream_paused = false
	player.stream = null
	player.volume_db = SILENT_DB
	player.set_meta("base_gain", 0.0)

func _count_active_bgm_players() -> int:
	var count := 0
	for player in _bgm_players:
		if player.playing:
			count += 1
	return count

func _set_managed_buses_muted(muted: bool) -> void:
	for bus_name in AUDIO_BUSES:
		var bus_index := AudioServer.get_bus_index(bus_name)
		if bus_index >= 0:
			AudioServer.set_bus_mute(bus_index, muted)

func _sync_pause_state() -> void:
	var pause_bgm_and_sfx := _manual_paused or _application_paused or _tree_paused
	for player in _bgm_players:
		player.stream_paused = pause_bgm_and_sfx
	for player in _sfx_pool:
		player.stream_paused = _should_pause_player(player)

func _should_pause_player(player: AudioStreamPlayer) -> bool:
	if _application_paused:
		return true
	if not (_manual_paused or _tree_paused):
		return false
	return _pause_ui_too or player.bus != &"UI"

func _report_missing_audio(message: String) -> void:
	if _missing_audio_reported.has(message):
		return
	_missing_audio_reported[message] = true
	push_warning("AudioManager: %s" % message)
