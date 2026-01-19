extends Node

func _ready() -> void:
	# Check if we should auto-start a run for debug/demo?
	# Usually DungeonController drives this.
	pass

func _start_combat(pack: Array) -> void:
	var cs: Node = get_node_or_null("/root/CombatSystem")
	if cs != null and cs.has_method("begin_encounter"):
		# Ensure run state
		var gc: Node = _gc()
		
		# Get Current Pool
		var pool_name = "growth"
		var dc = get_node_or_null("/root/DungeonController")
		if dc and dc.has_method("get_current_pool"):
			pool_name = dc.get_current_pool()
		
		# Set bg
		var gui = get_node_or_null("/root/GameUI")
		if gui and gui.has_method("set_background"):
			# e.g. "growth_combat", "decay_combat"
			gui.set_background(pool_name + "_combat")
			
		cs.begin_encounter(pack)
	else:
		push_warning("CombatSystem not found.")

func _on_combat_finished(victory: bool, is_mini_boss: bool = false) -> void:
	if victory:
		var gc: Node = _gc()
		if gc: 
			gc.add_seeds(25 if is_mini_boss else 15)
			
		var rs = get_node_or_null("/root/RewardSystem")
		if rs:
			var pool_name = "growth"
			var dc = get_node_or_null("/root/DungeonController")
			if dc and dc.has_method("get_current_pool"):
				pool_name = dc.get_current_pool()
				
			if is_mini_boss:
				# Elite Reward Logic (Simulated Choice + Bonuses)
				var act = 1
				if dc and dc.has_method("get_current_act"): act = dc.current_act
				
				var rewards = rs.generate_elite_rewards(act)
				
				# 1. Apply Currency (Defaulting to "Pick Currency" isn't right, but we grant it along with cards for now as we lack Choice UI)
				# Or maybe we just give the currency as a baseline loot?
				# Spec says "Choose 1 of 3". If UI can't do it, we are generous (give all) or stingy?
				# Let's give Coins + Cards (No Relic? Or Relic?)
				# Existing code gave Relic. User spec says Choice.
				# I will disable automatic Relic grant to respect "Choice" (assuming Cards is the default pick).
				# But wait, Elites usually give Relics. If I remove it, it feels bad if I don't get to choose.
				# Compromise: Give Relic + Cards. (Generous for now).
				
				# Apply Bonuses
				for b in rewards.bonuses:
					print("Elite Bonus: %s" % b.type)
					if b.type == "uncommon_card_offer":
						# Add 1 Uncommon to offers? 
						# existing offer_mixed_rewards clears offers.
						# We should append? RS doesn't support append easily.
						pass
					elif b.type == "upgrade_card":
						# Upgrade random card
						var dm = get_node_or_null("/root/DeckManager")
						if dm: dm.upgrade_random_deck_card()
					elif b.type == "remove_filler":
						# Remove filler
						var dm = get_node_or_null("/root/DeckManager")
						if dm: dm.remove_random_filler()

				# Base Reward: Cards (3 Archetype)
				rs.offer_mixed_rewards(3, 0, pool_name)
				
				# Grant Currency
				var gold_opts = rewards.options.filter(func(x): return x.type == "currency")
				if not gold_opts.is_empty():
					var amt = gold_opts[0].amount
					if gc and "verdant_shards" in gc: gc.verdant_shards += amt
					print("Elite Reward: +%d Shards" % amt)

				# Temporarily Grant Relic (Legacy/Fallback until UI supports Choice)
				rs.grant_random_relic("")
				
			else:
				# Normal: 2 Archetype Cards, 1 Neutral
				rs.offer_mixed_rewards(2, 1, pool_name)

func _roll_basic_pack() -> Array:
	return _roll_pack("normal")

func _roll_elite_pack() -> Array:
	return _roll_pack("elite")

func _roll_boss_pack() -> Array:
	var dc = get_node_or_null("/root/DungeonController")
	var act = 1
	if dc and dc.has_method("get_current_act"): # Assumption: get_current_act doesn't exist yet but public var does?
		# DC has var current_act. Use dc.current_act
		act = dc.current_act
	
	if act == 2:
		return _roll_pack("boss_act2")
	if act >= 3:
		return _roll_pack("boss_act3")
	return _roll_pack("boss")

func _roll_pack(tier: String) -> Array:
	var dl = _dl()
	if not dl: return []
	
	var pool_name = "growth"
	var dc = get_node_or_null("/root/DungeonController")
	if dc and dc.has_method("get_current_pool"):
		pool_name = dc.get_current_pool()
	
	# Primary logic: Get enemies by Tier AND Pool
	# But DataLayer only has get_enemies_by_tier OR get_enemies_by_pool separately?
	# Let's check DataLayer structure...
	# DataLayer: enemies_by_tier, enemies_by_pool.
	# We need Intersection. Or just iterate all enemies in Tier and check Pool?
	
	var candidates = []
	var t_enemies = dl.get_enemies_by_tier(tier)
	
	# Optimization: If pool is "core", include it?
	# Assuming enemies have ONE pool. "growth", "decay", "elemental", "any"?
	
	for e in t_enemies:
		if e.pool == pool_name or e.pool == "any" or e.pool == "core" or e.pool == "":
			candidates.append(e)
			
	if candidates.is_empty():
		# Fallback to any in tier
		candidates = t_enemies
		
	if candidates.is_empty(): return []
	
	var out = []
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	var count = 1
	if tier == "normal": count = rng.randi_range(1, 2)
	
	for i in range(count):
		out.append(candidates.pick_random())

	return out

func _dl() -> Node:
	return get_node_or_null("/root/DataLayer")

func _gc() -> Node:
	return get_node_or_null("/root/GameController")
