extends Node

const SHOP_CFG_PATH: String = "res://Data/shop_config.json"

var _cfg: Dictionary = {}
var _inventory: Array[Dictionary] = []

func _ready() -> void:
	_cfg = _read_json(SHOP_CFG_PATH)

# Compute the price for a card.  Uses the shop configuration to look up
# rarity‐specific prices; defaults to 35 if unspecified.
func price_for_card(card: Dictionary) -> int:
	var cfg: Dictionary = _shop_cfg()
	var prices: Dictionary = cfg.get("card_prices", {})
	var rarity: String = String(card.get("rarity", "common"))
	return int(prices.get(rarity, 35))

func remove_price() -> int:
	var cfg: Dictionary = _shop_cfg()
	return int(cfg.get("remove_price", 50))

func heal_cost_for(amount_hp: int) -> int:
	var cfg: Dictionary = _shop_cfg()
	var per: int = int(cfg.get("healing_price_per_hp", 1))
	return per * amount_hp

func generate_inventory(n: int, class_id: String) -> Array:
	# Generate a new inventory of n cards biased towards the given class id.
	_inventory.clear()
	var dl: Node = get_node_or_null("/root/DataLayer")
	var pool: Array[Dictionary] = []
	if dl != null:
		# Prefer class‑specific cards if available
		if dl.has("cards_by_class"):
			var cc: Variant = dl.get("cards_by_class")
			if cc is Dictionary and (cc as Dictionary).has(class_id):
				var arr_v: Variant = (cc as Dictionary)[class_id]
				if arr_v is Array:
					pool = arr_v as Array
		# Fallback to all cards
		if pool.is_empty() and dl.has_method("get_cards_all"):
			var all_v: Variant = dl.call("get_cards_all")
			if all_v is Array:
				pool = all_v as Array
	if pool.is_empty():
		return []
	# Use run RNG for deterministic shop
	var rng: RandomNumberGenerator = null
	var gc: Node = get_node_or_null("/root/GameController")
	if gc != null and gc.has_method("get_rng"):
		rng = gc.call("get_rng") as RandomNumberGenerator
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var used: Dictionary = {}
	while _inventory.size() < n and pool.size() > 0:
		var idx: int = rng.randi_range(0, pool.size() - 1)
		var item: Variant = pool[idx]
		if item is Dictionary:
			var c: Dictionary = item as Dictionary
			var cid: String = String(c.get("id", c.get("name", "")))
			if used.has(cid):
				continue
			used[cid] = true
			_inventory.append(c.duplicate(true))
	return _inventory.duplicate()

# Purchase the card at the specified index from the current inventory.  The
# card is added to the player's discard pile and removed from the shop
# inventory.  Returns true on success.
func purchase(index: int) -> bool:
	if index < 0 or index >= _inventory.size():
		return false
	var card: Dictionary = _inventory[index]
	# Spend shards via GameController
	var gc: Node = get_node_or_null("/root/GameController")
	var cost: int = price_for_card(card)
	if gc != null and gc.has("verdant_shards"):
		var shards: int = int(gc.get("verdant_shards"))
		if shards < cost:
			return false
		gc.set("verdant_shards", shards - cost)
	# Add card to discard pile via DeckManager
	var dm: Node = get_node_or_null("/root/DeckManager")
	if dm != null and dm.has_method("discard_card"):
		dm.call("discard_card", card)
	# Remove from shop
	_inventory.remove_at(index)
	return true

func _shop_cfg() -> Dictionary:
	return _cfg

func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var txt: String = f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(txt)
	return (parsed as Dictionary) if (parsed is Dictionary) else {}
