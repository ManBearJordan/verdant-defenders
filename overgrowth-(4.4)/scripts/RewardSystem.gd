extends Node

# RewardSystem offers card rewards after combat and handles the player
# choosing one of them.  It uses DataLayer and GameController for pools
# and randomness.

# The current set of offered cards.  This is populated when offer_cards()
# is called and consumed by claim_card().
var _offers: Array = []

# --- REWARD POOLS (STRICT) ---
# n_arch: Number of Archetype cards
# n_neutral: Number of Neutral/Filler cards
# class_id: The run's locked archetype ("growth", "decay", "elemental")
func offer_mixed_rewards(n_arch: int, n_neutral: int, class_id: String) -> Array[CardResource]:
	_offers.clear()
	var dl: Node = get_node_or_null("/root/DataLayer")
	if not dl: return []
	
	# Fetch Pools (excluding Locked content)
	var arch_pool = dl.get_cards_by_criteria(class_id, "", false)
	var neutral_pool = dl.get_cards_by_criteria("neutral", "", false) # Or "filler"? Using "neutral" for now.
	
	# Safety checks
	if arch_pool.is_empty() and n_arch > 0:
		print("RewardSystem: No cards found for archetype '%s'!" % class_id)
		# Fallback to anything? No, strict lock says "Run Invalid".
		# But to keep game playable, maybe fallback to neutral?
		arch_pool = neutral_pool
		
	# Setup RNG
	var rng: RandomNumberGenerator = null
	var gc: Node = get_node_or_null("/root/GameController")
	if gc and gc.has_method("get_rng"):
		rng = gc.call("get_rng")
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
		
	# 1. Roll Archetype Cards
	for i in range(n_arch):
		if arch_pool.is_empty(): break
		
		# Rarity Weighting (60/30/10)
		var rarity = _roll_rarity(rng)
		var candidates = _filter_by_rarity(arch_pool, rarity)
		
		# Fallback if no cards of specific rarity
		if candidates.is_empty(): candidates = arch_pool
		
		_pick_unique(candidates, rng)
		
	# 2. Roll Neutral Cards
	for i in range(n_neutral):
		if neutral_pool.is_empty(): break
		
		var rarity = _roll_rarity(rng)
		var candidates = _filter_by_rarity(neutral_pool, rarity)
		if candidates.is_empty(): candidates = neutral_pool
		
		_pick_unique(candidates, rng)
		
	return _offers.duplicate()

# Wrapper for legacy calls or simple cases (defaulting to 2 Arch + 1 Neutral)
func offer_cards(n: int, class_id: String) -> Array[CardResource]:
	# Default Distribution rule: 2 Arch + 1 Filler (if n=3)
	if n == 3:
		return offer_mixed_rewards(2, 1, class_id)
	else:
		# Fallback: All Archetype? Or split?
		# For Elites (n=3 but strictly archetype), caller should use offer_mixed_rewards(3, 0)
		# Just default to all Archetype for safety if unknown n
		return offer_mixed_rewards(n, 0, class_id)

func _roll_rarity(rng: RandomNumberGenerator) -> String:
	var r = rng.randf()
	if r < 0.10: return "rare"
	if r < 0.40: return "uncommon"
	return "common"

func _filter_by_rarity(pool: Array[CardResource], rarity: String) -> Array[CardResource]:
	var out: Array[CardResource] = []
	for c in pool:
		if c.rarity.to_lower() == rarity:
			out.append(c)
	return out

func _pick_unique(pool: Array[CardResource], rng: RandomNumberGenerator) -> void:
	if pool.is_empty(): return
	
	# Simple retry for uniqueness
	for k in range(10):
		var pick = pool.pick_random() # Note: Pool is array of Resources
		# Check if already offered
		var already_has = false
		for o in _offers:
			if o.id == pick.id:
				already_has = true
				break
		
		if not already_has:
			_offers.append(pick)
			return

func get_random_relic(rarity: String = "") -> Dictionary:
	var dl: Node = get_node_or_null("/root/DataLayer")
	var rs: Node = get_node_or_null("/root/RelicSystem")
	if not dl or not rs: return {}
	
	if not dl.has_method("get_all_relics"): return {}
	var all_relics = dl.call("get_all_relics")
	var valid: Array = []
	
	for r in all_relics:
		var has = false
		if rs.has_method("has_relic"):
			has = rs.call("has_relic", r.get("id"))
		if not has:
			if rarity == "" or r.get("rarity", "common") == rarity:
				valid.append(r)
	
	if valid.is_empty(): return {}
	
	var gc: Node = get_node_or_null("/root/GameController")
	var rng = gc.call("get_rng") if (gc and gc.has_method("get_rng")) else RandomNumberGenerator.new()
	
	return valid[rng.randi() % valid.size()]

func grant_random_relic(rarity: String = "") -> void:
	var r = get_random_relic(rarity)
	if not r.is_empty():
		var rs = get_node_or_null("/root/RelicSystem")
		if rs and rs.has_method("add_relic"):
			rs.call("add_relic", r.get("id"))
			print("RewardSystem: Granted relic %s" % r.get("name"))

func generate_elite_rewards(act: int) -> Dictionary:
	# TASK 7: Elite Reward Tuning (Final Spec)
	# A) Guaranteed Shards
	# B) 3-Card Offer (elite rarity weights)
	# C) Bonus Roll (chance-based)
	
	var rewards = {
		"shards": 0,
		"cards": [],
		"bonus": null,
		"sigil_fragment": false
	}
	
	# A) VERDANT SHARDS (Guaranteed)
	var shard_table = {1: 90, 2: 125, 3: 170}
	rewards.shards = shard_table.get(act, 170)
	
	# B) CARD REWARD (Guaranteed, 3 cards, elite rarity weights)
	var dc = get_node_or_null("/root/DungeonController")
	var class_id = "growth"
	if dc and dc.has_method("get_current_pool"):
		class_id = dc.get_current_pool()
	
	rewards.cards = offer_elite_cards(3, class_id)
	
	# C) BONUS ROLL (Chance-based)
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	var bonus_chance_table = {1: 0.30, 2: 0.40, 3: 0.50}
	var bonus_chance = bonus_chance_table.get(act, 0.50)
	
	if rng.randf() < bonus_chance:
		# Roll for bonus type
		var roll = rng.randf()
		if roll < 0.60:
			# +50 shards
			rewards.bonus = {"type": "shards", "amount": 50, "label": "+50 Shards"}
		elif roll < 0.90:
			# +1 consumable/rune charge
			rewards.bonus = {"type": "consumable", "amount": 1, "label": "+1 Rune Charge"}
		else:
			# +1 sigil fragment
			rewards.bonus = {"type": "sigil_fragment", "amount": 1, "label": "+1 Sigil Fragment"}
			rewards.sigil_fragment = true
	
	return rewards

func offer_elite_cards(count: int, class_id: String) -> Array[CardResource]:
	# Elite card offering: 3 cards, at least 1 from pool, elite rarity weights
	# Rarity weights: Common 55%, Uncommon 40%, Rare 5%
	_offers.clear()
	
	var dl: Node = get_node_or_null("/root/DataLayer")
	if not dl: return []
	
	var arch_pool = dl.get_cards_by_criteria(class_id, "", false)
	var neutral_pool = dl.get_cards_by_criteria("neutral", "", false)
	
	var rng: RandomNumberGenerator = null
	var gc: Node = get_node_or_null("/root/GameController")
	if gc and gc.has_method("get_rng"):
		rng = gc.call("get_rng")
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	
	# At least 1 from player's pool (guaranteed first pick)
	if not arch_pool.is_empty():
		var rarity = _roll_elite_rarity(rng)
		var candidates = _filter_by_rarity(arch_pool, rarity)
		if candidates.is_empty(): candidates = arch_pool
		_pick_unique(candidates, rng)
	
	# Remaining cards from pool OR neutral
	var combined_pool: Array[CardResource] = []
	combined_pool.append_array(arch_pool)
	combined_pool.append_array(neutral_pool)
	
	while _offers.size() < count and not combined_pool.is_empty():
		var rarity = _roll_elite_rarity(rng)
		var candidates = _filter_by_rarity(combined_pool, rarity)
		if candidates.is_empty(): candidates = combined_pool
		_pick_unique(candidates, rng)
	
	return _offers.duplicate()

func _roll_elite_rarity(rng: RandomNumberGenerator) -> String:
	# Elite Rarity Weights: Common 55%, Uncommon 40%, Rare 5%
	var r = rng.randf()
	if r < 0.05: return "rare"
	if r < 0.45: return "uncommon"
	return "common"

# Sigil Fragment Tracking
var sigil_fragments: int = 0

func add_sigil_fragment(count: int = 1) -> void:
	sigil_fragments += count
	print("RewardSystem: +%d Sigil Fragment (Total: %d)" % [count, sigil_fragments])
	
	# Auto-convert 3 fragments to Sigil reward screen
	if sigil_fragments >= 3:
		sigil_fragments -= 3
		print("RewardSystem: 3 Fragments -> Sigil Reward Screen!")
		# Trigger Sigil selection (handled by UI or GameController)
		var gc = get_node_or_null("/root/GameController")
		if gc and gc.has_method("trigger_sigil_reward"):
			gc.trigger_sigil_reward()

func reset_sigil_fragments() -> void:
	sigil_fragments = 0

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
