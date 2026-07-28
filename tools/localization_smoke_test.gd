extends SceneTree

var _failures: Array[String] = []

func _initialize() -> void:
	await process_frame
	var manager := root.get_node("/root/LocalizationManager")
	var data_loader := root.get_node("/root/DataLoader")
	data_loader.load_all()

	manager.apply_language("en", false)
	_expect(manager.is_english(), "manager must enter English without persisting test state")
	_expect(manager.text("设置") == "Settings", "exact UI message must translate")
	_expect(manager.text("弱点") == "Weakness", "exact term must beat the short 弱%s template")
	_expect(
		manager.text("画质：标准 60帧") == "Graphics: Standard · 60 FPS",
		"formatted UI text must translate after runtime formatting"
	)
	_expect(
		manager.text("推荐 · 角色适配") == "Hero Synergy",
		"authored printf template must beat partial term replacement"
	)
	_expect(data_loader.tr_key("char_vanguard") == "Steel Vanguard", "content id must use English catalog")
	_expect(not _contains_cjk(manager.text("第03战区 · 废弃工厂")), "composed English text must not retain CJK")

	manager.apply_language("zh", false)
	_expect(manager.text("设置") == "设置", "Chinese locale must preserve source copy")
	_expect(str(TranslationServer.translate("设置")) == "设置", "Godot fallback must not retranslate Chinese source through English")
	_expect(data_loader.tr_key("char_vanguard") == "钢铁先锋", "content id must switch back to Chinese")

	if _failures.is_empty():
		print("LOCALIZATION SMOKE TEST PASSED")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _contains_cjk(value: String) -> bool:
	for character in value:
		var code := character.unicode_at(0)
		if (code >= 0x3400 and code <= 0x9FFF) or (code >= 0xF900 and code <= 0xFAFF):
			return true
	return false
