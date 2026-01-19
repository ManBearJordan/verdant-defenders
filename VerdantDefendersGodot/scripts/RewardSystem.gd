extends Node

# RewardSystem offers card rewards after combat and handles the player
# choosing one of them.  It uses DataLayer and GameController for pools
# and randomness.

# The current set of offered cards.  This is populated when offer_cards()
# is called and consumed by claim_card().
var _offers: Array[Dictionary] = []

func offer_cards(n: int, class_id: String) -> Array[Dictionary]:
	# Clear any previous offers
	_offers.clear()
	var dl: Node = get_node_or_null("/root/DataLayer")
	if dl == null:
		return []
	# Assemble a pool of cards.  Prefer class‑specific cards if available.
	var pool: Array[Dictionary] = []
	if dl.has("cards_by_class"):
		var by_class_v: Variant = dl.get("cards_by_class")
		if by_class_v is Dictionary and (by_class_v as Dictionary).has(class_id):
			var class_pool_v: Variant = (by_class_v as Dictionary).get(class_id)
			if class_pool_v is Array:
				pool = class_pool_v as Array
	# Fallback to all cards
	if pool.is_empty() and dl.has_method("get_cards_all"):
		var all_v: Variant = dl.call("get_cards_all")
		if all_v is Array:
			pool = all_v as Array
	if pool.is_empty():
		return []
	# Use the run RNG if available for deterministic rewards
	var rng: RandomNumberGenerator = null
	var gc: Node = get_node_or_null("/root/GameController")
	if gc != null and gc.has_method("get_rng"):
		rng = gc.call("get_rng") as RandomNumberGenerator
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	# Draw without replacement
	var used: Dictionary = {}
	while _offers.size() < n and pool.size() > 0:
		var idx: int = rng.randi_range(0, pool.size() - 1)
		var card: Variant = pool[idx]
		if card is Dictionary:
			var c: Dictionary = card as Dictionary
			var cid: String = String(c.get("id", c.get("name", "")))
			if used.has(cid):
				continue
			used[cid] = true
			_offers.append(c.duplicate(true))
	return _offers.duplicate()

func claim_card(index: int) -> void:
	# Add the selected card to the discard pile.  Consumes the current
	# offers; subsequent calls will need a new offer_cards() call.
	if index < 0 or index >= _offers.size():
		return
	var card: Dictionary = _offers[index]
	var dm: Node = get_node_or_null("/root/DeckManager")
	if dm != null and dm.has_method("discard_card"):
		dm.call("discard_card", card)
	# Clear offers after claiming
	_offers.clear()
