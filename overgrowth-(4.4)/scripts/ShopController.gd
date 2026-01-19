extends Control
## Glue between the Shop scene, the ShopSystem autoload, and the ShopUI node.
## It asks ShopSystem to prepare an inventory and pushes it into ShopUI.
## Optional signal hookup: if ShopUI emits `buy_requested(index: int)`, we listen.

func _ready() -> void:
	# Open/refresh the shop model.
	if Engine.has_singleton("ShopSystem"):
		var ss: Object = ShopSystem
		if ss.has_method("open_shop"):
			ss.call("open_shop")
	_refresh_ui()

func _refresh_ui() -> void:
	var items: Array[Dictionary] = []
	if Engine.has_singleton("ShopSystem"):
		var ss: Object = ShopSystem
		if ss.has_method("get_inventory"):
			var inv: Variant = ss.call("get_inventory")
			if inv is Array:
				for v in inv:
					if v is Dictionary:
						items.append(v)
	# Push to UI if present
	if has_node("ShopUI"):
		var ui := get_node("ShopUI")
		if ui and ui.has_method("set_inventory"):
			ui.call("set_inventory", items)
		# Lazily connect optional signal once
		if ui and ui.has_signal("buy_requested") and not ui.is_connected("buy_requested", Callable(self, "_on_buy_requested")):
			ui.connect("buy_requested", Callable(self, "_on_buy_requested"))

func _on_buy_requested(index: int) -> void:
	if Engine.has_singleton("ShopSystem"):
		var ss: Object = ShopSystem
		if ss.has_method("buy"):
			ss.call("buy", index)
	_refresh_ui()
