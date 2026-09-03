extends RefCounted

# Apple StoreKit 2 bridge.
#
# The iOS plugin singleton only exists inside an iOS export that ships the
# plugin. In the editor, in headless probes and on desktop runs the singleton is
# absent, is_live() stays false, and PurchaseManager keeps using the local demo
# path unchanged. This class never touches save data: it only translates between
# the native plugin and PurchaseManager, which owns every entitlement write.
#
# Native contract (implemented by ios/plugins/zombiefire_storekit):
#   methods
#     initialize(product_ids: PackedStringArray) -> void
#     purchase(product_id: String) -> void
#     restore() -> void
#     refresh_entitlements() -> void
#   signals
#     products_loaded(products: Array)        # [{product_id, price_text, title, description}]
#     transaction_updated(transaction: Dictionary)
#         # {product_id, state, message}
#         # state in purchased|restored|pending|cancelled|failed|revoked
#     entitlements_synced(product_ids: Array)  # authoritative owned set
#     store_error(message: String)

const PLUGIN_SINGLETON := "ZombieFireStoreKit"

const STATE_PURCHASED := "purchased"
const STATE_RESTORED := "restored"
const STATE_PENDING := "pending"
const STATE_CANCELLED := "cancelled"
const STATE_FAILED := "failed"
const STATE_REVOKED := "revoked"

signal products_loaded(products: Array)
signal transaction_updated(product_id: String, state: String, message: String)
signal entitlements_synced(product_ids: Array)
signal store_error(message: String)

var _plugin: Object = null
var _price_text: Dictionary = {}

func _init() -> void:
	if not Engine.has_singleton(PLUGIN_SINGLETON):
		return
	var candidate: Object = Engine.get_singleton(PLUGIN_SINGLETON)
	if candidate == null:
		return
	# Refuse a partially implemented singleton rather than half-wiring commerce.
	for required in ["initialize", "purchase", "restore", "refresh_entitlements"]:
		if not candidate.has_method(required):
			push_warning("StoreKit plugin is missing %s(); falling back to the local demo store" % required)
			return
	_plugin = candidate
	_plugin.connect("products_loaded", _on_products_loaded)
	_plugin.connect("transaction_updated", _on_transaction_updated)
	_plugin.connect("entitlements_synced", _on_entitlements_synced)
	_plugin.connect("store_error", _on_store_error)

func is_live() -> bool:
	return _plugin != null

func initialize(product_ids: PackedStringArray) -> void:
	if _plugin == null:
		return
	_plugin.call("initialize", product_ids)

func purchase(product_id: String) -> void:
	if _plugin == null:
		return
	_plugin.call("purchase", product_id)

func restore() -> void:
	if _plugin == null:
		return
	_plugin.call("restore")

func refresh_entitlements() -> void:
	if _plugin == null:
		return
	_plugin.call("refresh_entitlements")

# Localized App Store price for a product, or "" until StoreKit has answered.
# The store falls back to the authored demo price string when this is empty, so
# a slow or failed product query never leaves a blank price on screen.
func price_text(product_id: String) -> String:
	return str(_price_text.get(product_id, ""))

func _on_products_loaded(products: Array) -> void:
	for entry in products:
		if not (entry is Dictionary):
			continue
		var product_id := str((entry as Dictionary).get("product_id", ""))
		var text := str((entry as Dictionary).get("price_text", ""))
		if product_id != "" and text != "":
			_price_text[product_id] = text
	products_loaded.emit(products)

func _on_transaction_updated(transaction: Dictionary) -> void:
	transaction_updated.emit(
		str(transaction.get("product_id", "")),
		str(transaction.get("state", STATE_FAILED)),
		str(transaction.get("message", "")),
	)

func _on_entitlements_synced(product_ids: Array) -> void:
	var clean: Array[String] = []
	for product_id in product_ids:
		var text := str(product_id).strip_edges()
		if text != "" and not clean.has(text):
			clean.append(text)
	entitlements_synced.emit(clean)

func _on_store_error(message: String) -> void:
	store_error.emit(message)
