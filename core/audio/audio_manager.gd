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
	"enemy_death": "res://assets/production/audio/sfx/sfx_enemy_death_small.wav",
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

var enabled := true
var _sfx_cache := {}
var _bgm_cache := {}
var _bgm_player: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _current_bgm := ""
var _last_sfx_time := {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = "Master"
	_bgm_player.volume_db = -13.0
	add_child(_bgm_player)
	for i in range(12):
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		player.volume_db = -6.0
		add_child(player)
		_sfx_pool.append(player)

func play_bgm(id: String) -> void:
	if not enabled or not BGM.has(id) or _current_bgm == id:
		return
	_current_bgm = id
	var stream := _load_bgm(id)
	if stream == null:
		return
	_bgm_player.stop()
	_bgm_player.stream = stream
	_bgm_player.play()

func stop_bgm() -> void:
	_current_bgm = ""
	_bgm_player.stop()

func release_for_tests() -> void:
	stop_bgm()
	_bgm_player.stream = null
	for player in _sfx_pool:
		player.stop()
		player.stream = null
	_sfx_cache.clear()
	_bgm_cache.clear()
	_last_sfx_time.clear()

func play_sfx(id: String, volume_db := 0.0, pitch_variation := 0.04) -> void:
	if not enabled or not SFX.has(id):
		return
	if _is_rate_limited(id):
		return
	var stream := _load_sfx(id)
	if stream == null:
		return
	var player := _next_sfx_player()
	player.stop()
	player.stream = stream
	player.volume_db = -6.0 + volume_db
	player.pitch_scale = randf_range(1.0 - pitch_variation, 1.0 + pitch_variation)
	player.play()

func _is_rate_limited(id: String) -> bool:
	var min_gap := 0.0
	match id:
		"hit_physical", "hit_fire", "hit_ice", "hit_lightning", "hit_poison", "hit_immune":
			min_gap = 0.045
		"shot_autocannon", "shot_flamethrower", "shot_cryocannon", "shot_teslacoil", "shot_venomlauncher", "shot_railgun", "shot_scattergun", "shot_plasmacannon":
			min_gap = 0.035
		"muzzle_fire", "muzzle_ice", "muzzle_lightning", "muzzle_poison":
			min_gap = 0.06
		"enemy_death":
			min_gap = 0.04
		"enemy_breach", "threat_warning":
			min_gap = 0.75
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
	enabled = not enabled
	if enabled:
		if _current_bgm != "":
			_bgm_player.play()
	else:
		_bgm_player.stop()
		for player in _sfx_pool:
			player.stop()
	return enabled

func _load_sfx(id: String) -> AudioStream:
	if not _sfx_cache.has(id):
		_sfx_cache[id] = load(SFX[id])
	return _sfx_cache[id]

func _load_bgm(id: String) -> AudioStream:
	if not _bgm_cache.has(id):
		_bgm_cache[id] = load(BGM[id])
	return _bgm_cache[id]

func _next_sfx_player() -> AudioStreamPlayer:
	for player in _sfx_pool:
		if not player.playing:
			return player
	return _sfx_pool[0]
