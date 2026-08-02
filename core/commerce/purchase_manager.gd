extends Node

signal commerce_changed
signal purchase_finished(product_id: String, success: bool, message: String)

const SOURCE_LOCAL_MOCK := "local_mock"

var _catalog: Dictionary = {}


func _ready() -> void:
	call_deferred("_refresh_catalog_and_access")


func _refresh_catalog_and_access() -> void:
	_catalog = DataLoader.get_table("store_products")
	reconcile_access(false)


func refresh_catalog_and_access() -> void:
	_refresh_catalog_and_access()


func products() -> Array[Dictionary]:
	var output: Array[Dictionary] = []
	for product_id_var in _catalog.keys():
		var row: Dictionary = _catalog.get(product_id_var, {})
		if not bool(row.get("visible_in_mock_store", true)):
			continue
		var copy := row.duplicate(true)
		copy["id"] = str(product_id_var)
		output.append(copy)
	output.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("sort", 0)) < int(b.get("sort", 0))
	)
	return output


func product(product_id: String) -> Dictionary:
	var row: Dictionary = _catalog.get(product_id, {})
	var copy := row.duplicate(true)
	if not copy.is_empty():
		copy["id"] = product_id
	return copy


func has_entitlement(entitlement_id: String) -> bool:
	if entitlement_id == "":
		return true
	if SaveManager.has_verified_entitlement(entitlement_id):
		return true
	for product_id in mock_receipts():
		var row := product(product_id)
		for granted in row.get("grants", []):
			if str(granted) == entitlement_id:
				return true
	return false


func mock_receipts() -> Array[String]:
	var result: Array[String] = []
	var commerce: Dictionary = SaveManager.save_data.get("commerce", {})
	for product_id in commerce.get("mock_receipts", []):
		var clean := str(product_id).strip_edges()
		if clean != "" and not result.has(clean):
			result.append(clean)
	return result


func is_product_owned(product_id: String) -> bool:
	var row := product(product_id)
	if row.is_empty():
		return false
	for entitlement_id in row.get("grants", []):
		if not has_entitlement(str(entitlement_id)):
			return false
	return not row.get("grants", []).is_empty()


func store_series_ids() -> Array[String]:
	var result: Array[String] = []
	for series_id in catalog_series_ids():
		if _series_is_visible(series_id):
			result.append(series_id)
	return result


func catalog_series_ids() -> Array[String]:
	var result: Array[String] = []
	for row in products():
		var series_id := str(row.get("series_id", "")).strip_edges()
		if series_id != "" and not result.has(series_id):
			result.append(series_id)
	return result


func series_id_for_product(product_id: String) -> String:
	return str(product(product_id).get("series_id", ""))


func theme_id_for_product(product_id: String) -> String:
	return str(product(product_id).get("theme_id", ""))


func set_id_for_product(product_id: String) -> String:
	return str(product(product_id).get("arsenal_set_id", ""))


func set_id_for_series(series_id: String) -> String:
	for set_id_var in DataLoader.get_table("premium_sets").keys():
		var set_id := str(set_id_var)
		if str(DataLoader.get_row("premium_sets", set_id).get("series_id", "")) == series_id:
			return set_id
	return ""


func set_for_series(series_id: String) -> Dictionary:
	return DataLoader.get_row("premium_sets", set_id_for_series(series_id))


func theme_entitlement_for_series(series_id: String) -> String:
	return str(set_for_series(series_id).get("theme_entitlement", ""))


func arsenal_entitlement_for_series(series_id: String) -> String:
	return str(set_for_series(series_id).get("entitlement", ""))


func is_theme_owned(series_id: String) -> bool:
	return has_entitlement(theme_entitlement_for_series(series_id))


func is_arsenal_owned(series_id: String) -> bool:
	return has_entitlement(arsenal_entitlement_for_series(series_id))


func visible_offer_ids(series_id := "") -> Array[String]:
	var ids: Array[String] = []
	var requested_series: Array[String] = store_series_ids()
	if series_id != "":
		requested_series = []
		if _series_is_visible(series_id):
			requested_series.append(series_id)
	for current_series in requested_series:
		var theme_owned := is_theme_owned(current_series)
		var arsenal_owned := is_arsenal_owned(current_series)
		if not theme_owned:
			_append_offer_for_kind(ids, current_series, "theme")
		if not arsenal_owned:
			_append_offer_for_kind(
				ids,
				current_series,
				"arsenal_upgrade" if theme_owned else "arsenal_complete"
			)
	ids.sort_custom(func(a: String, b: String) -> bool:
		return int(product(a).get("sort", 0)) < int(product(b).get("sort", 0))
	)
	return ids


func mock_purchase(product_id: String, persist := true) -> bool:
	var row := product(product_id)
	if row.is_empty() or not visible_offer_ids().has(product_id):
		purchase_finished.emit(product_id, false, "商品当前不可购买")
		return false
	var receipts := mock_receipts()
	if not receipts.has(product_id):
		receipts.append(product_id)
	var commerce: Dictionary = SaveManager.save_data.get("commerce", {})
	commerce["mock_receipts"] = receipts
	commerce["mock_last_transaction_unix"] = int(Time.get_unix_time_from_system())
	SaveManager.save_data["commerce"] = commerce
	reconcile_access(persist)
	purchase_finished.emit(product_id, true, "本地演示购买成功，不会扣款")
	return true


func restore_mock_purchases() -> int:
	# Mock receipts already live in the save file. Reconciliation intentionally
	# exercises the same restore path that StoreKit will later feed.
	reconcile_access(true)
	var count := mock_receipts().size()
	purchase_finished.emit("", true, "已恢复 %d 笔本地演示购买" % count)
	return count


func reset_mock_purchases(persist := true) -> void:
	var commerce: Dictionary = SaveManager.save_data.get("commerce", {})
	commerce["mock_receipts"] = []
	commerce["mock_last_transaction_unix"] = 0
	SaveManager.save_data["commerce"] = commerce
	reconcile_access(persist)
	purchase_finished.emit("", true, "本地演示购买已清空")


func reset_mock_purchases_for_series(series_id: String, persist := true) -> int:
	if not catalog_series_ids().has(series_id):
		purchase_finished.emit("", false, "商品系列不存在")
		return 0
	var receipts := mock_receipts()
	var kept: Array[String] = []
	var removed := 0
	for product_id in receipts:
		if str(product(str(product_id)).get("series_id", "")) == series_id:
			removed += 1
		else:
			kept.append(str(product_id))
	var commerce: Dictionary = SaveManager.save_data.get("commerce", {})
	commerce["mock_receipts"] = kept
	commerce["mock_last_transaction_unix"] = int(Time.get_unix_time_from_system()) if not kept.is_empty() else 0
	SaveManager.save_data["commerce"] = commerce
	reconcile_access(persist)
	purchase_finished.emit("", true, "已清空本系列 %d 笔本地演示购买" % removed)
	return removed


func equip_complete_set(set_id := "") -> bool:
	var resolved_set_id := set_id
	if resolved_set_id == "":
		for series_id in store_series_ids():
			if is_arsenal_owned(series_id):
				resolved_set_id = set_id_for_series(series_id)
				break
	if resolved_set_id == "":
		return false
	var set_row := DataLoader.get_row("premium_sets", resolved_set_id)
	if set_row.is_empty() or not has_entitlement(str(set_row.get("entitlement", ""))):
		return false
	for slot in ["weapon", "armor", "chip", "pet"]:
		var item_id := str(set_row.get(slot, ""))
		if item_id == "" or not SaveManager.select_item(slot, item_id):
			return false
	ThemeManager.select_theme(str(set_row.get("theme", ThemeManager.DEFAULT_THEME_ID)))
	commerce_changed.emit()
	return true


func reconcile_access(persist := true) -> void:
	var unlocks: Dictionary = SaveManager.save_data.get("unlocks", {})
	var premium_sets: Dictionary = DataLoader.get_table("premium_sets")
	for set_id_var in premium_sets.keys():
		var set_row := DataLoader.get_row("premium_sets", str(set_id_var))
		var owned_arsenal := has_entitlement(str(set_row.get("entitlement", "")))
		for slot in ["weapon", "armor", "chip", "pet"]:
			var item_id := str(set_row.get(slot, ""))
			if item_id == "":
				continue
			var key := "armors" if slot == "armor" else "%ss" % slot
			var items: Array = unlocks.get(key, [])
			if owned_arsenal and not items.has(item_id):
				items.append(item_id)
			elif not owned_arsenal and items.has(item_id):
				items.erase(item_id)
				if SaveManager.get_selected(slot) == item_id:
					SaveManager.save_data["equipment"]["selected_%s" % slot] = (
						"weapon_autocannon" if slot == "weapon" else ""
					)
			unlocks[key] = items
	SaveManager.save_data["unlocks"] = unlocks
	ThemeManager.refresh_from_save()
	if persist:
		SaveManager.save_game()
	commerce_changed.emit()


func _append_offer_for_kind(ids: Array[String], series_id: String, kind: String) -> void:
	for row in products():
		if str(row.get("series_id", "")) != series_id or str(row.get("offer_role", row.get("kind", ""))) != kind:
			continue
		ids.append(str(row.get("id", "")))
		return


func _series_is_visible(series_id: String) -> bool:
	if series_id == "" or not catalog_series_ids().has(series_id):
		return false
	# An owned non-consumable must remain restorable/selectable even if a test
	# fixture later rolls campaign progress backward.
	if is_theme_owned(series_id) or is_arsenal_owned(series_id):
		return true
	if OS.is_debug_build() and OS.get_environment("ZOMBIE_FIRE_STORE_GATE_BYPASS") == "1":
		return true
	var unlock: Dictionary = set_for_series(series_id).get("store_unlock", {})
	var clear_level := int(unlock.get("clear_level", 0))
	if clear_level > 0:
		var level_id := "level_%03d" % clear_level
		if SaveManager.get_level_stars(level_id) <= 0:
			return false
	var required_character_level := int(unlock.get("any_character_level", 0))
	if required_character_level > 0:
		var level_met := false
		for character_id in ["vanguard", "blaze", "frost", "volt"]:
			if SaveManager.get_item_level(character_id) >= required_character_level:
				level_met = true
				break
		if not level_met:
			return false
	return true
