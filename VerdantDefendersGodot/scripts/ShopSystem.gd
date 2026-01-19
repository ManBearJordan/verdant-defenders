extends Node

const SHOP_CFG_PATH: String = "res://Data/shop_config.json"

var _cfg: Dictionary = {}
var current_inventory: Array = []

var game_controller: Node
var deck_manager: Node
var data_layer: Node

func _ready() -> void:
	game_controller = get_node_or_null("/root/RunController") # Was GameController
	deck_manager = get_node_or_null("/root/DeckManager")
	data_layer = get_node_or_null("/root/DataLayer")
	_cfg = _read_json(SHOP_CFG_PATH)

# Compute the price for a card.  Uses the shop configuration to look up
# rarity‐specific prices; defaults to 35 if unspecified.

func remove_price() -> int:
	var cfg: Dictionary = _shop_cfg()
	return int(cfg.get("remove_price", 50))

func heal_cost_for(amount_hp: int) -> int:
	var cfg: Dictionary = _shop_cfg()
	var per: int = int(cfg.get("healing_price_per_hp", 1))
	return per * amount_hp

# Strict Shop Inventory Rule: 70% Archetype, 20% Filler, 10% Other
func generate_inventory(n: int, class_id: String) -> Array:
	current_inventory.clear()
	var dl: Node = data_layer
	if dl == null: return []
	
	# Determine Distribution
	var count_arch = int(round(n * 0.7))
	var count_neutral = int(round(n * 0.2))
	var count_other = n - count_arch - count_neutral # Remainder (approx 10%)
	
	if count_other < 0: count_other = 0 # Safety
	
	# Setup RNG
	var rng: RandomNumberGenerator = null
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
		
	# Fetch Pools (Resources)
	var pool_arch = dl.get_cards_by_criteria(class_id, "", false)
	var pool_neutral = dl.get_cards_by_criteria("neutral", "", false)
	# For "other", use neutral for now until Colorless/Tech exists
	var pool_other = dl.get_cards_by_criteria("neutral", "", false) 
	
	_fill_inventory_from_pool(pool_arch, count_arch, rng)
	_fill_inventory_from_pool(pool_neutral, count_neutral, rng)
	_fill_inventory_from_pool(pool_other, count_other, rng)
	
	return current_inventory.duplicate()

func _fill_inventory_from_pool(pool: Array[CardResource], count: int, rng: RandomNumberGenerator) -> void:
	if pool.is_empty(): return
	
	var used_local = {} 
	# Note: current_inventory contains Dictionaries (converted from Resources for shop compat?)
	# ShopSystem seems to expect Dictionaries based on previous code: `current_inventory: Array[Dictionary]`
	# We need to convert Resource -> Dict to maintain Shop compatibility unless we refactor Shop to use Resources.
	# The previous `data_layer` loaded Dictionaries? 
	# Wait, `DataLayer` refactor changed `get_cards_all` to return `Array[CardResource]`.
	# BUT `ShopSystem` was interacting with `Dictionary`.
	# We need to serialize the Resource to a Dictionary for the Shop UI if it expects Dicts.
	# Or better, update Shop UI to handle Resources.
	# Checking usage: `price_for_card(card)`, `purchase(index)`.
	# `DeckManager.discard_card` accepts `CardResource` now?
	# `DeckManager` refactor was Phase 9. It uses Resources now.
	# So ShopSystem MUST be updated to use Resources!
	
	var candidates = pool.duplicate()
	candidates.shuffle()
	
	for i in range(count):
		if candidates.is_empty(): break
		var card_res = candidates.pop_back()
		
		# Convert to Dictionary-like wrapper OR just store Resource
		# Refactor Shop to store Resources.
		current_inventory.append(card_res) 

# Purchase the card at the specified index from the current inventory.  The
# card is added to the player's discard pile and removed from the shop
# inventory.  Returns true on success.
# Purchase the card at the specified index from the current inventory.
func purchase(index: int) -> bool:
	if index < 0 or index >= current_inventory.size():
		return false
	
	# Current inventory holds RESOURCES now
	var card_res = current_inventory[index]
	if not (card_res is CardResource):
		print("ShopSystem: Error, inventory item is not a CardResource")
		return false
		
	var gc: Node = game_controller
	var cost: int = price_for_card(card_res)
	
	if gc != null:
		# RunController uses 'shards'
		var shards: int = int(gc.get("shards"))
		if shards < cost:
			return false
		gc.modify_shards(-cost)
	
	# Add card to discard pile via DeckManager
	var dm: Node = deck_manager
	if dm != null and dm.has_method("discard_card"):
		# DeckManager.discard_card expects CardResource
		dm.discard_card(card_res)
		
	# Remove from shop
	current_inventory.remove_at(index)
	return true

func price_for_card(card: Variant) -> int:
	var rarity = "common"
	if card is CardResource:
		rarity = card.rarity.to_lower()
	elif card is Dictionary:
		rarity = String(card.get("rarity", "common")).to_lower()
		
	var cfg: Dictionary = _shop_cfg()
	var prices: Dictionary = cfg.get("card_prices", {})
	return int(prices.get(rarity, 35))

func heal_player(amount: int) -> bool:
	var gc: Node = game_controller
	if gc == null: return false
	
	var cost = heal_cost_for(amount)
	var shards = int(gc.get("shards"))
	if shards < cost: return false
	
	var hp = int(gc.get("player_hp"))
	var max_h = int(gc.get("max_hp"))
	if hp >= max_h: return false
	
	gc.modify_shards(-cost)
	gc.modify_hp(amount)
	return true

func remove_card_from_deck(card: Variant) -> bool:
	# Card should be Resource
	var gc: Node = game_controller
	if gc == null: return false
	
	var cost = remove_price()
	var shards = int(gc.get("shards"))
	if shards < cost: return false
	
	var dm: Node = deck_manager
	if dm and dm.has_method("remove_card"):
		# DeckManager.remove_card expects CardResource
		if dm.remove_card(card):
			gc.modify_shards(-cost)
			return true
	return false

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
