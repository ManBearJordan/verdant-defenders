extends Node

# CardRules resolves effects of a CardResource.
# Uses `logic_meta` for complex effects, and CardResource properties for basics.

func resolve(card: CardResource, cs: Node, dm: Node, target_index: int) -> void:
	var meta = card.logic_meta
	
	# Process effects array if present
	if meta.has("effects") and meta["effects"] is Array:
		var effects: Array = meta["effects"] as Array
		for effect in effects:
			if effect is Dictionary:
				apply_effect(effect, cs, dm, target_index)
	
	# Resolve basic properties (Cost handled by internal rules usually, but effect processing is here)
	# NOTE: CombatSystem.play_card ALREADY applies damage/block directly via fallback if CardRules fails?
	# No, CombatSystem calls `cr.resolve`. If that exists, it assumes CR handles it.
	# So CR MUST apply damage/block from properties too.
	
	_resolve_standard_properties(card, meta, cs, dm, target_index)

func _resolve_standard_properties(card: CardResource, meta: Dictionary, cs: Node, dm: Node, target_index: int) -> void:
	# Damage
	if card.damage > 0:
		var target_all = meta.get("target", "") == "all"
		if target_all:
			if cs and cs.has_method("damage_enemy"):
				var enemies = cs.get_enemies()
				for i in range(enemies.size()):
					cs.damage_enemy(i, card.damage)
		else:
			if cs and cs.has_method("damage_enemy"):
				cs.damage_enemy(target_index, card.damage)
				
	# Block
	if card.block > 0:
		if cs and cs.has_method("add_block"):
			cs.add_block(card.block)
			
	# Apply Status (Legacy/Simple field)
	if meta.has("apply") and meta["apply"] is Dictionary:
		var app = meta["apply"] as Dictionary
		if target_index >= 0:
			for k in app.keys():
				var amt = int(app[k])
				# Access CS inner method or helper
				if cs and cs.has_method("_apply_status_to_enemy"):
					cs._apply_status_to_enemy(target_index, String(k), amt)
					
	# Draw
	if meta.has("draw"):
		var n = int(meta["draw"])
		if dm and dm.has_method("draw_cards"):
			dm.draw_cards(n)
			
	# Energy Gain
	if meta.has("energy_gain"):
		var n = int(meta["energy_gain"])
		if dm and dm.has_method("gain_energy"):
			dm.gain_energy(n)

# Effect Logic (Copied/Adapted from previous version)

func apply_effects(target_node_unused, effects: Array, ctx: Dictionary) -> void:
	# target_node_unused is for compatibility if we had it, but we use indexes usually.
	# We rely on ctx for context like "attacker_index", or we assume "target_index" is global/passed?
	# CombatSystem calls this. 
	
	var cs = get_node_or_null("/root/CombatSystem")
	var dm = get_node_or_null("/root/DeckManager")
	var gc = get_node_or_null("/root/GameController")
	
	# Default target from ctx
	var t_idx = ctx.get("target_index", -1)
	if ctx.has("attacker_index"): t_idx = ctx.attacker_index # Trap context usually implies attacker is target
	
	for effect in effects:
		if effect is Dictionary:
			apply_effect(effect, cs, dm, t_idx)

func apply_effect(effect: Dictionary, cs: Node, dm: Node, target_index: int) -> void:
	var effect_type = String(effect.get("type", ""))
	
	match effect_type:
		"deal_damage":
			var amount = int(effect.get("amount", 0))
			if cs: cs.damage_enemy(target_index, amount)
		"gain_block":
			var amount = int(effect.get("amount", 0))
			if cs: cs.add_block(amount)
		"draw_cards":
			var amount = int(effect.get("amount", 1))
			if dm: dm.draw_cards(amount)
		"apply_status":
			var status = String(effect.get("status", ""))
			var amount = int(effect.get("amount", 1))
			var target_override = String(effect.get("target", ""))
			if target_override == "player":
				_apply_player_status(status, amount)
			else:
				if cs: cs._apply_status_to_enemy(target_index, status, amount)
		"heal":
			var amount = int(effect.get("amount", 0))
			_heal_player(amount)
		"aoe_damage":
			var amount = int(effect.get("amount", 0))
			if cs:
				var enemies = cs.get_enemies()
				for i in range(enemies.size()):
					cs.damage_enemy(i, amount)
		"gain_energy":
			var amount = int(effect.get("amount", 1))
			if dm: dm.gain_energy(amount)
		"plant_seed":
			var amount = int(effect.get("amount", 1))
			if cs: cs._apply_status_to_enemy(target_index, "seeded", amount)
		"gain_seed":
			var amount = int(effect.get("amount", 1))
			var gc = get_node_or_null("/root/GameController")
			if gc: gc.add_seeds(amount)
			
		# --- DECAY V2 & NEW LOGIC ---
		"set_trap":
			if cs: cs.add_trap(effect)
		"set_aura":
			if cs: cs.add_aura(effect)
		"set_ritual":
			if cs: cs.add_ritual(effect)
			
		"repeat":
			var times = int(effect.get("times", 1))
			var sub_effects = effect.get("effects", [])
			for i in range(times):
				apply_effects(null, sub_effects, {"target_index": target_index})
				
		"if_target_has_status":
			var status = effect.get("status", "")
			var min_val = int(effect.get("min", 1))
			if cs:
				var enemies = cs.get_enemies()
				if target_index >= 0 and target_index < enemies.size():
					var e = enemies[target_index]
					if e.get_status(status) >= min_val:
						apply_effects(null, effect.get("then", []), {"target_index": target_index})
						
		"if_target_hp_below_pct":
			var pct = float(effect.get("pct", 50))
			if cs:
				var enemies = cs.get_enemies()
				if target_index >= 0 and target_index < enemies.size():
					var e = enemies[target_index]
					var threshold = float(e.max_hp) * (pct / 100.0)
					if float(e.current_hp) < threshold:
						apply_effects(null, effect.get("then", []), {"target_index": target_index})
						
		"if_any_enemy_has_status":
			var status = effect.get("status", "")
			var min_val = int(effect.get("min", 1))
			if cs:
				var enemies = cs.get_enemies()
				var found = false
				for e in enemies:
					if not e.is_dead() and e.get_status(status) >= min_val:
						found = true
						break
				if found:
					apply_effects(null, effect.get("then", []), {"target_index": target_index})
					
		"for_each_enemy_with_status":
			var status = effect.get("status", "")
			var min_val = int(effect.get("min", 1))
			var do_effects = effect.get("do", [])
			if cs:
				var enemies = cs.get_enemies()
				for i in range(enemies.size()):
					var e = enemies[i]
					if not e.is_dead() and e.get_status(status) >= min_val:
						# Context shift: "that_enemy" often implies setting target_index to i
						apply_effects(null, do_effects, {"target_index": i})
						
		"if_attacker_has_status":
			# Trap context usually. target_index should be attacker.
			var status = effect.get("status", "")
			var min_val = int(effect.get("min", 1))
			if cs:
				var enemies = cs.get_enemies()
				if target_index >= 0 and target_index < enemies.size():
					var e = enemies[target_index]
					if e.get_status(status) >= min_val:
						apply_effects(null, effect.get("then", []), {"target_index": target_index})
		
		# Compound Removals
		"remove_status":
			var status = effect.get("status", "")
			var amount = int(effect.get("amount", 1))
			if cs: cs._apply_status_to_enemy(target_index, status, -amount)
			
		"remove_status_up_to":
			var status = effect.get("status", "")
			var max_rem = int(effect.get("max", 999))
			if cs:
				var enemies = cs.get_enemies()
				if target_index >= 0 and target_index < enemies.size():
					var e = enemies[target_index]
					var cur = e.get_status(status)
					var actual = min(cur, max_rem)
					cs._apply_status_to_enemy(target_index, status, -actual)
					
		"remove_status_up_to_then_deal_damage_per_removed":
			var status = effect.get("status", "")
			var max_rem = int(effect.get("max", 999))
			var dmg_per = int(effect.get("damage_per_removed", 0))
			if cs:
				var enemies = cs.get_enemies()
				if target_index >= 0 and target_index < enemies.size():
					var e = enemies[target_index]
					var cur = e.get_status(status)
					var actual = min(cur, max_rem)
					if actual > 0:
						cs._apply_status_to_enemy(target_index, status, -actual) # Remove
						
						# Signal? Trigger ritual?
						cs.check_rituals("on_remove_status", {"status": status, "amount": actual, "target_unit": e})
						
						var dmg = actual * dmg_per
						cs.damage_enemy(target_index, dmg)
						
		"remove_status_up_to_then_gain_block_per_removed":
			var status = effect.get("status", "")
			var max_rem = int(effect.get("max", 999))
			var blk_per = int(effect.get("block_per_removed", 0))
			if cs:
				var enemies = cs.get_enemies()
				if target_index >= 0 and target_index < enemies.size():
					var e = enemies[target_index]
					var cur = e.get_status(status)
					var actual = min(cur, max_rem)
					if actual > 0:
						cs._apply_status_to_enemy(target_index, status, -actual)
						cs.check_rituals("on_remove_status", {"status": status, "amount": actual, "target_unit": e})
						cs.add_block(actual * blk_per)
						
		"remove_status_up_to_then_gain_energy_if_removed_at_least":
			var status = effect.get("status", "")
			var max_rem = int(effect.get("max", 999))
			var req = int(effect.get("min_removed", 1))
			var en = int(effect.get("energy", 0))
			if cs:
				var enemies = cs.get_enemies()
				if target_index >= 0 and target_index < enemies.size():
					var e = enemies[target_index]
					var cur = e.get_status(status)
					var actual = min(cur, max_rem)
					if actual > 0:
						cs._apply_status_to_enemy(target_index, status, -actual)
						cs.check_rituals("on_remove_status", {"status": status, "amount": actual, "target_unit": e})
						if actual >= req and dm:
							dm.gain_energy(en)
							
		"remove_status_up_to_then_draw_per_removed":
			var status = effect.get("status", "")
			var max_rem = int(effect.get("max", 999))
			var draw_per = int(effect.get("draw_per_removed", 1))
			var cap = int(effect.get("draw_cap", 99))
			if cs:
				var enemies = cs.get_enemies()
				if target_index >= 0 and target_index < enemies.size():
					var e = enemies[target_index]
					var cur = e.get_status(status)
					var actual = min(cur, max_rem)
					if actual > 0:
						cs._apply_status_to_enemy(target_index, status, -actual)
						cs.check_rituals("on_remove_status", {"status": status, "amount": actual, "target_unit": e})
						var total_draw = min(actual * draw_per, cap)
						if dm: dm.draw_cards(total_draw)

		"remove_status_random_enemy_with_status_up_to_then_gain_block_per_removed":
			var status = effect.get("status", "")
			var max_rem = int(effect.get("max", 2))
			var blk_per = int(effect.get("block_per_removed", 3))
			if cs:
				var indices = []
				var enemies = cs.get_enemies()
				for i in range(enemies.size()):
					if not enemies[i].is_dead() and enemies[i].get_status(status) > 0:
						indices.append(i)
				
				if not indices.is_empty():
					var i = indices.pick_random()
					var e = enemies[i]
					var cur = e.get_status(status)
					var actual = min(cur, max_rem)
					if actual > 0:
						cs._apply_status_to_enemy(i, status, -actual)
						cs.check_rituals("on_remove_status", {"status": status, "amount": actual, "target_unit": e})
						cs.add_block(actual * blk_per)
						
		"remove_status_attacker_up_to_then_deal_damage_per_removed":
			# Attacker implies target_index IS attacker in trap context
			var status = effect.get("status", "")
			var max_rem = int(effect.get("max", 3))
			var dmg_per = int(effect.get("damage_per_removed", 2))
			if cs:
				var enemies = cs.get_enemies()
				if target_index >= 0 and target_index < enemies.size():
					var e = enemies[target_index]
					var cur = e.get_status(status)
					var actual = min(cur, max_rem)
					if actual > 0:
						cs._apply_status_to_enemy(target_index, status, -actual)
						cs.check_rituals("on_remove_status", {"status": status, "amount": actual, "target_unit": e})
						cs.damage_enemy(target_index, actual * dmg_per)
		_:
			print("CardRules: Unknown effect %s" % effect_type)

func _heal_player(amount: int) -> void:
	var gc = get_node_or_null("/root/GameController")
	if gc:
		gc.heal_player(amount)

func _apply_player_status(status: String, amount: int) -> void:
	var gc = get_node_or_null("/root/GameController")
	if gc and gc.has_method("add_status"):
		gc.add_status(status, amount)
		print("CardRules: Player %s +%d" % [status, amount])
	elif gc and "player_state" in gc:
		# Fallback
		var ps = gc.player_state.get("statuses", {})
		ps[status] = int(ps.get(status, 0)) + amount
		gc.player_state["statuses"] = ps
		print("CardRules: Player %s +%d (Fallback)" % [status, amount])
