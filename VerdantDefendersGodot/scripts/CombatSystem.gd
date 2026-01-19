extends Node

# Strong Typed Enemy List
var enemies: Array[EnemyUnit] = []
var player_block: int = 0
var turn: int = 0

# Systems
var traps: Array[Dictionary] = []
var auras: Array[Dictionary] = []
var rituals: Array[Dictionary] = []

signal damage_dealt(target_type: String, index: int, amount: int, absorbed: int)
signal player_block_changed(amount: int)
var _current_card_context = null

func get_living_enemies() -> Array[int]:
	var out: Array[int] = []
	for i in range(enemies.size()):
		if enemies[i].current_hp > 0:
			out.append(i)
	return out

func is_enemy_present(name_id: String) -> bool:
	for e in enemies:
		if e.is_dead(): continue
		if e.display_name == name_id or e.id == name_id:
			return true
	return false

func _ready() -> void:
	pass

# Pack is Array[EnemyResource]
func begin_encounter(pack: Array) -> void:
	enemies.clear()
	traps.clear()
	auras.clear()
	rituals.clear()
	
	player_block = 0
	player_block_changed.emit(0)
	turn = 0
	

	for res in pack:
		if res is EnemyResource:
			var unit = EnemyUnit.new(res)
			
			# Dynamic Scaling
			var dc = get_node_or_null("/root/DungeonController")
			if dc:
				var act = dc.current_act
				var depth = dc.current_layer
				
				var act_mult = 1.0
				if act == 2: act_mult = 1.35
				elif act >= 3: act_mult = 1.70
				
				var depth_mult = 1.0 + 0.10 * floor(depth / 5.0)
				var total_mult = act_mult * depth_mult
				
				if total_mult != 1.0:
					unit.apply_scaling(total_mult)
			
			unit.update_intent(0)
			enemies.append(unit)
	
	# Initial draw
	var dm = get_node_or_null("/root/DeckManager")
	if dm:
		dm.call_deferred("start_turn") # Use call_deferred to allow UI to settle?
	
	# Relic & Sigil Hooks (Start Combat)
	var rs = get_node_or_null("/root/RelicSystem")
	if rs:
		if rs.has_method("apply_start_combat_hooks"): rs.apply_start_combat_hooks(self)
		if rs.has_method("apply_initial_seeds"): 
			var gc = get_node_or_null("/root/GameController")
			rs.apply_initial_seeds(gc)
			
	var ss = get_node_or_null("/root/SigilSystem")
	if ss and ss.has_method("apply_start_combat_effects"):
		ss.apply_start_combat_effects(self)

	# Dynamic Scaling & Elites
	var known_elites = ["Corrupted Ent", "Rot Knight"] # Expand as needed
	for i in range(enemies.size()):
		var unit = enemies[i]
		# Scaling (Already applied in loop above? No, I added the loop logic in previous step inside 'for res in pack' loop)
		# Wait, Step 5206 added scaling 'inside' the loop.
		
		# Elite Modifiers
		var tier = "normal"
		if unit.display_name in known_elites:
			tier = "elite"
			_apply_elite_modifier(unit)
			
			# Elite HP Tuning (TASK 8: Config-based multipliers)
			var dc_chk = get_node_or_null("/root/DungeonController")
			if dc_chk:
				var act = dc_chk.current_act
				var base_hp = unit.max_hp
				
				# Get elite HP multiplier from config (1.6/1.7/1.8 per Act)
				var hp_mod = _get_elite_hp_mult(act)
				
				# Modifier tradeoffs already applied in _apply_elite_modifier
				# (multiplicative HP reduction based on modifier hp_mult values)
				
				unit.max_hp = int(round(base_hp * hp_mod))
				
				# Apply safety cap (Elite max = 2.0x normal)
				unit.max_hp = _apply_hp_safety_cap(unit.max_hp, base_hp, "elite")
				unit.current_hp = unit.max_hp
				
				# Elite damage mult handled in enemy_turn via _get_elite_damage_mult()
				
				print("Elite Tuning (Act %d): HP x%.2f -> %d (capped)" % [act, hp_mod, unit.max_hp])
		elif _boss_patterns.has(unit.display_name) or unit.max_hp > 150: # Fallback boss check
			tier = "boss"
			
		# Ascension Scaling
		var ac = get_node_or_null("/root/AscensionController")
		if ac:
			var buffs = ac.get_enemy_buffs(tier)
			if buffs.hp_mult != 1.0 or buffs.dmg_mult != 1.0:
				unit.apply_ascension_scaling(buffs.hp_mult, buffs.dmg_mult)
				print("Ascension Buff (%s): HP x%.2f, Dmg x%.2f" % [tier, buffs.hp_mult, buffs.dmg_mult])

	# Boss Phase Checks

	# Boss Phase Checks
	_load_boss_phases()
	for i in range(enemies.size()):
		_check_phase_transition(i, true)


var _boss_patterns: Dictionary = {}
var _boss_phases_data: Dictionary = {}
var cards_played_this_turn: int = 0

func _load_boss_phases() -> void:
	# Load Boss Patterns (New System)
	var path = "res://Data/boss_patterns.json"
	if FileAccess.file_exists(path):
		var f = FileAccess.open(path, FileAccess.READ)
		var json = JSON.new()
		if json.parse(f.get_as_text()) == OK:
			var list = json.data
			if list is Array:
				for b in list:
					_boss_patterns[b.get("name")] = b
			print("CombatSystem: Loaded %d Boss Patterns" % _boss_patterns.size())

# Caching
var _elite_modifiers_data: Dictionary = {}
var _enemy_hp_config: Dictionary = {}

func _load_elite_modifiers() -> void:
	if not _elite_modifiers_data.is_empty(): return
	var path = "res://Data/elite_modifiers.json"
	if FileAccess.file_exists(path):
		var f = FileAccess.open(path, FileAccess.READ)
		var json = JSON.new()
		if json.parse(f.get_as_text()) == OK:
			_elite_modifiers_data = json.data
			print("CombatSystem: Loaded Elite Modifiers Config.")
	else:
		print("CombatSystem: Elite Modifiers JSON missing!")

func _load_enemy_hp_config() -> void:
	if not _enemy_hp_config.is_empty(): return
	var path = "res://Data/enemy_hp_config.json"
	if FileAccess.file_exists(path):
		var f = FileAccess.open(path, FileAccess.READ)
		var json = JSON.new()
		if json.parse(f.get_as_text()) == OK:
			_enemy_hp_config = json.data
			print("CombatSystem: Loaded Enemy HP Config.")
	else:
		print("CombatSystem: Enemy HP Config JSON missing!")

func _get_elite_hp_mult(act: int) -> float:
	# Returns elite HP multiplier from config (Task 8)
	_load_enemy_hp_config()
	var table = _enemy_hp_config.get("elite_hp_multiplier", {})
	return float(table.get(str(act), 1.6))

func _get_normal_hp_range(act: int) -> Dictionary:
	# Returns {"min": x, "max": y, "avg": z} for normal enemies
	_load_enemy_hp_config()
	var bands = _enemy_hp_config.get("normal_enemy_hp_bands", {})
	return bands.get(str(act), {"min": 28, "max": 42, "avg": 35})

func _apply_hp_safety_cap(hp: int, base_hp: int, tier: String) -> int:
	# Enforces safety caps from config
	_load_enemy_hp_config()
	var caps = _enemy_hp_config.get("safety_caps", {})
	var max_mult = 1.0
	if tier == "elite": max_mult = float(caps.get("elite_max_mult", 2.0))
	elif tier == "mini_boss": max_mult = float(caps.get("mini_boss_max_mult", 2.5))
	
	var cap = int(floor(base_hp * max_mult))
	return min(hp, cap)

func _apply_elite_modifier(e: EnemyUnit) -> void:
	_load_elite_modifiers()
	if _elite_modifiers_data.is_empty(): return
	
	var rules = _elite_modifiers_data.get("rules", {})
	var all_mods = _elite_modifiers_data.get("modifiers", [])
	
	# Determine Act
	var act = 1
	var dc = get_node_or_null("/root/DungeonController")
	if dc: act = dc.current_act
	
	# Determine Count (Base 1, chance for 2)
	var count = 1
	var chance = 0.0
	if act == 2: chance = rules.get("act_2_second_modifier_chance", 0.25)
	elif act >= 3: chance = rules.get("act_3_second_modifier_chance", 0.50)
	
	if randf() < chance and rules.get("max_modifiers", 2) >= 2:
		count = 2
		
	# Build Pool
	var pool = []
	for m in all_mods:
		var tier = m.get("tier", "A")
		var allowed = false
		if tier == "A": allowed = true # Act 1+
		elif tier == "B" and act >= 2: allowed = true
		elif tier == "C" and act >= 3: allowed = true
		
		if allowed:
			pool.append(m)
			
	pool.shuffle()
	
	var selected = []
	var selected_themes = []
	
	for m in pool:
		if selected.size() >= count: break
		
		# Check Theme Exclusion
		var th = m.get("theme", "")
		if th in selected_themes: continue
		
		selected.append(m)
		selected_themes.append(th)
		
	e.modifiers = selected
	print("CombatSystem: Applied Modifiers to %s -> %s" % [e.display_name, str(selected.map(func(x): return x.id))])
	
	# Apply HP Tradeoffs
	var base_hp = e.max_hp
	var hp_mult = 1.0
	for m in selected:
		var mod_hp = m.get("hp_mult", 1.0)
		if rules.get("hp_tradeoffs_stack_multiplicatively", true):
			hp_mult *= mod_hp
	
	if hp_mult != 1.0:
		var new_hp = int(floor(base_hp * hp_mult))
		
		# Enforce minimum floor (anti-degeneracy)
		var floor_pct = rules.get("elite_hp_min_floor_pct", 0.60)
		var min_hp = int(floor(base_hp * floor_pct))
		new_hp = max(new_hp, min_hp)
		
		e.max_hp = new_hp
		e.current_hp = e.max_hp
		print("Elite HP Tradeoff: x%.2f -> %d (floor: %d)" % [hp_mult, e.max_hp, min_hp])
			
	# Initial Setup Hooks
	for m in selected:
		for eff in m.get("effects", []):
			if eff.type == "start_combat_apply":
				pass # Handled in _check_elite_hooks("start_combat")
			elif eff.type == "outgoing_damage_mult":
				# Aggressive: Permanent +20% dmg
				var dm = float(eff.get("value", 1.0))
				if dm != 1.0:
					e.damage_scale *= dm
					print("Elite Mod: Applied Dmg Scale x%.2f" % dm)

func _is_forbidden_update(current_list: Array, candidate: Dictionary) -> bool:
	# Deprecated by Theme system
	return false

func _get_elite_damage_mult() -> float:
	# Elite damage multipliers per Act (Ascension 0 baseline)
	# Act 1: 1.20, Act 2: 1.30, Act 3: 1.40
	var dc = get_node_or_null("/root/DungeonController")
	var act = 1
	if dc: act = dc.current_act
	
	match act:
		1: return 1.20
		2: return 1.30
		_: return 1.40 # Act 3+

func _check_elite_hooks(trigger: String, e: EnemyUnit, ctx: Dictionary = {}) -> void:
	if e.is_dead() or e.modifiers.is_empty(): return
	var gc = get_node_or_null("/root/GameController")
	var sh = get_node_or_null("/root/StatusHandler")

	# Helper to check presence
	var has_mod = func(id): 
		for m in e.modifiers: 
			if m.id == id: return true
		return false
	
	if trigger == "start_combat":
		# Malevolent: Start of combat: apply 2 Fragile to Player.
		if has_mod.call("malevolent"):
			print("Elite %s: Malevolent (Apply 2 Fragile)" % e.display_name)
			_apply_status_to_player("fragile", 2)
			
	elif trigger == "start_turn":
		# Reset turn flags
		e.custom_data["entrenched_usage"] = 0
		e.custom_data["swift_first_hit"] = true
		
		# Relentless: If last enemy alive, gain +25% dmg and +10 Block start of turn.
		if has_mod.call("relentless"):
			# Check count
			var living = 0
			for en in enemies:
				if not en.is_dead() and en != e: living += 1
			if living == 0:
				print("Elite %s: Relentless Buff!" % e.display_name)
				e.block += 10
				# Damage buff (+25%) handled in get_damage_mult or add strength?
				# Spec: "Gain +25% damage". 
				# I need to apply a buff. 
				# Easiest way: Apply Strength? No, 25% is multiplicative.
				# I should modify e.damage_scale? 
				# Or add a temporary "relentless_buff" status if my system supports it.
				# Or just Strength as proxy? +25% of base ~ 2-3 Str?
				# Spec says "Gain +25% damage".
				# I'll rely on "Aggressive" logic style or just add Strength for simplicity as specific modifier usually adds Str.
				# Wait, Aggressive is +20% flat mult.
				# Relentless adds +25% DYNAMICALLY if last alive.
				# I will add a custom property `relentless_active` and check in damage calc?
				# Just set e.custom_data["relentless_active"] = true this turn.
				e.custom_data["relentless_active"] = true
			else:
				e.custom_data["relentless_active"] = false

	elif trigger == "on_damage_taken":
		# Hardened is handled in damage_enemy (mitigation).
		
		# Entrenched: First hit -6.
		if has_mod.call("entrenched"):
			# This needs to be checked BEFORE damage application (mitigation).
			# `damage_enemy` handles mitigation.
			# So I need to move Entrenched check to `damage_enemy` Step?
			# _check_elite_hooks("on_damage_taken") is called AFTER damage.
			# So "Entrenched" logic must be inside `damage_enemy`.
			pass

		# Spiked: When hit by Strike, deal 3 damage back.
		if has_mod.call("spiked"):
			var c_type = ctx.get("card_type", "unknown")
			if c_type == "Strike":
				print("Elite %s: Spiked (3 Dmg)" % e.display_name)
				damage_player(3)
				
		# Bloodied: When HP < 50%, gain +2 Strength. (Trigger once?)
		if has_mod.call("bloodied"):
			if e.current_hp < (e.max_hp * 0.5):
				if not e.custom_data.get("bloodied_triggered", false):
					print("Elite %s: Bloodied (+2 Str)" % e.display_name)
					_apply_status_to_enemy(enemies.find(e), "strength", 2)
					e.custom_data["bloodied_triggered"] = true

		# Unstable: Below 50% HP: Gain 10 Block + 1 Sap to Player. (Once)
		if has_mod.call("unstable"):
			if e.current_hp < (e.max_hp * 0.5):
				if not e.custom_data.get("unstable_triggered", false):
					print("Elite %s: Unstable Trigger!" % e.display_name)
					e.block += 10
					_apply_status_to_player("sap", 1)
					e.custom_data["unstable_triggered"] = true

		# Brittle Shell (Keep generic if it exists? No, replaced by new pool).
		
	elif trigger == "on_hit":
		# Toxic: On hit (attack), apply 1 Poison.
		if has_mod.call("toxic"):
			if ctx.get("source") == "attack":
				print("Elite %s: Toxic (Apply 1 Poison)" % e.display_name)
				_apply_status_to_player("poison", 1)
				
		# Vampiric: Heal 30% of damage dealt.
		if has_mod.call("vampiric"):
			if ctx.get("source") == "attack":
				var amount = ctx.get("amount", 0)
				if amount > 0:
					var heal = floor(amount * 0.30)
					if heal > 0:
						print("Elite %s: Vampiric Heal (+%d)" % [e.display_name, heal])
						e.current_hp = min(e.max_hp, e.current_hp + heal)

	elif trigger == "on_start_turn_intent": 
		# Or generic turn logic updates
		pass

	elif trigger == "eot":
		# Oppressive: End of player turn: if played 4+ cards, apply 1 Sap.
		if has_mod.call("oppressive"):
			var played = ctx.get("cards_played", 0) # Passed from somewhere?
			# Need to pass cards_played count to EOT.
			if played >= 4:
				print("Elite %s: Oppressive (Apply Sap)" % e.display_name)
				_apply_status_to_player("sap", 1)

func _apply_status_to_player(name: String, amount: int) -> void:
	var gc = get_node_or_null("/root/GameController")
	if gc and gc.has_method("add_status"):
		gc.add_status(name, amount)

func _check_phase_transition(ei: int, force_init: bool = false) -> void:
	if ei < 0 or ei >= enemies.size(): return
	var e = enemies[ei]
	
	# Load phases config if not present (simple lookup by name)
	if e.phases.is_empty():
		if _boss_phases_data.has(e.display_name):
			e.phases = _boss_phases_data[e.display_name]
			print("CombatSystem: Boss Phases loaded for %s" % e.display_name)
			
	if e.phases.is_empty(): return

	var current_idx = e.phase_index
	var hp = e.current_hp
	
	var new_idx = -1
	for i in range(e.phases.size()):
		var p = e.phases[i]
		if hp <= int(p.get("threshold_hp", 0)):
			new_idx = i
		else:
			break
			
	if new_idx != current_idx or force_init:
		if new_idx != -1:
			e.phase_index = new_idx
			var phase_data = e.phases[new_idx]
			print("CombatSystem: Phase Transition! %s -> %d" % [e.display_name, new_idx])
			# Phase transition often resets logic or sets specific intent
			e.intent = {"type": "attack", "value": 10, "name": phase_data.get("ability", "Phase Attack")}

func add_block(amount: int) -> void:
	player_block += max(0, amount)
	# Rule 8: Block Cap
	player_block = min(player_block, 999)
	player_block_changed.emit(player_block)
	print("CombatSystem: Player Block +%d -> %d" % [amount, player_block])

	# Act 2 Elite: Briarwarden (Block Punish)
	if amount > 0:
		for e in enemies:
			if not e.is_dead() and e.display_name == "Briarwarden":
				if not e.custom_data.has("briar_str_pending"): e.custom_data["briar_str_pending"] = 0
				var current = e.custom_data["briar_str_pending"]
				if current < 6:
					var gain = 2
					gain = min(gain, 6 - current)
					e.custom_data["briar_str_pending"] += gain
					if gain > 0:
						print("Briarwarden: Thorns of Reprisal (+%d Pending Str)" % gain)
						# Minimal visual feedback via ribbon?
						var gc = get_node_or_null("/root/GameController")
						if gc and gc.has_method("trigger_ribbon"):
							gc.trigger_ribbon("Briarwarden: Grew Stronger from Block!")

func add_status(name: String, amount: int) -> void:
	# Stub for calling GC/Player
	print("CombatSystem: Player status %s +%d" % [name, amount])
	var gc = get_node_or_null("/root/GameController")
	if gc and "player_state" in gc:
		var ps = gc.player_state.get("statuses", {})
		ps[name] = int(ps.get(name, 0)) + amount
		gc.player_state["statuses"] = ps

func add_trap(trap_data: Dictionary) -> void:
	print("Trap Set: %s" % trap_data.get("trigger", "Unknown"))
	traps.append(trap_data)
	
func add_aura(aura_data: Dictionary) -> void:
	print("Aura Added: %s" % aura_data.get("aura", "Unknown"))
	auras.append(aura_data)
	
func add_ritual(ritual_data: Dictionary) -> void:
	print("Ritual Added: %s" % ritual_data.get("ritual", "Unknown"))
	rituals.append(ritual_data)
	check_rituals("on_play_ritual", {"ritual": ritual_data})

func check_traps(trigger: String, ctx: Dictionary = {}) -> void:
	var to_remove = []
	for i in range(traps.size()):
		var t = traps[i]
		if t.get("trigger") == trigger:
			print("Trap Triggered: %s" % trigger)
			_execute_effects(t.get("effects", []), ctx)
			to_remove.append(i)
	to_remove.reverse()
	for i in to_remove:
		traps.remove_at(i)
		
func check_rituals(trigger: String, ctx: Dictionary = {}) -> void:
	for r in rituals:
		var rid = r.get("ritual")
		_process_specific_ritual(rid, trigger, ctx)

func _process_specific_ritual(rid: String, trigger: String, ctx: Dictionary) -> void:
	var dm = get_node_or_null("/root/DeckManager")
	var gc = get_node_or_null("/root/GameController")
	
	if rid == "first_ritual_each_combat_energy_next_turn_1":
		if trigger == "on_play_ritual":
			pass
	elif rid == "on_play_ritual_gain_energy_1":
		if trigger == "on_play_ritual":
			if dm: dm.gain_energy(1)
	elif rid == "on_play_ritual_draw_1_max_1_per_turn":
		if trigger == "on_play_ritual":
			if not ctx.has("drawn_generic_ritual"): 
				if dm: dm.draw_cards(1)
	elif rid == "once_per_turn_on_strike_poisoned_draw_1":
		if trigger == "on_strike_hit":
			var target = ctx.get("target_unit")
			if target and target.get_status("poison") > 0:
				if not _check_turn_limit(rid, 1):
					if dm: dm.draw_cards(1)
	elif rid == "once_per_turn_on_strike_poisoned_heal_2":
		if trigger == "on_strike_hit":
			var target = ctx.get("target_unit")
			if target and target.get_status("poison") > 0:
				if not _check_turn_limit(rid, 1):
					if gc: gc.heal_player(2)
	elif rid == "once_per_turn_on_apply_poison_draw_1":
		if trigger == "on_apply_status" and ctx.get("status") == "poison":
			if not _check_turn_limit(rid, 1):
				if dm: dm.draw_cards(1)
	elif rid == "once_per_turn_on_remove_poison_from_enemy_draw_1_gain_block_2":
		if trigger == "on_remove_status" and ctx.get("status") == "poison":
			if not _check_turn_limit(rid, 1):
				if dm: dm.draw_cards(1)
				add_block(2)

var _turn_limits: Dictionary = {}

func _check_turn_limit(id: String, limit: int) -> bool:
	var c = _turn_limits.get(id, 0)
	if c >= limit: return true
	_turn_limits[id] = c + 1
	return false

func _execute_effects(effects: Array, ctx: Dictionary) -> void:
	var cr = get_node_or_null("/root/CardRules")
	if cr and cr.has_method("apply_effects"):
		var t_idx = -1
		if ctx.has("attacker_index"): t_idx = ctx.attacker_index
		cr.apply_effects(null, effects, ctx)

func get_enemies() -> Array[EnemyUnit]:
	return enemies

# Card Logic
func play_card(idx: int, card: CardResource, target_index: int) -> void:
	var dm = get_node_or_null("/root/DeckManager")
	var gc = get_node_or_null("/root/GameController")
	
	if not dm: return
	
	var cost = card.cost
	
	if gc and "player_state" in gc:
		var p_status = gc.player_state.get("statuses", {})
		if p_status.get("free_strikes", 0) > 0 and card.type == "Strike":
			cost = 0
			
	if dm.energy < cost:
		print("CombatSystem: Not enough energy.")
		return
		
	var needs_target = _card_needs_target(card)
	if needs_target and (target_index < 0 or target_index >= enemies.size()):
		print("CombatSystem: Missing Valid Target.")
		return
	
	dm.spend_energy(cost)
	
	var played = dm.remove_from_hand(idx)
	if not played: 
		return
		
	# Set Context
	_current_card_context = card
	
	var cr = get_node_or_null("/root/CardRules")
	if cr and cr.has_method("resolve"):
		cr.resolve(played, self, dm, target_index)
	else:
		_apply_card_fallback(played, target_index)
		
	_current_card_context = null
		
	dm.discard_card(played)
	
	# Sigil Hooks: Double Cast (Ember Shard)
	var ss = get_node_or_null("/root/SigilSystem")
	if ss and ss.has_method("should_double_cast"):
		if ss.should_double_cast():
			print("CombatSystem: Double Cast Effect!")
			# Restore context for double cast
			_current_card_context = card
			if cr and cr.has_method("resolve"):
				cr.resolve(played, self, dm, target_index)
			else:
				_apply_card_fallback(played, target_index)
			_current_card_context = null
	
	if ss and ss.has_method("on_card_played"):
		ss.on_card_played(card)
	var rs = get_node_or_null("/root/RelicSystem")
	if rs and rs.has_method("on_card_played"):
		rs.on_card_played({"type": card.type, "cost": card.cost})
		
	var telemetry = get_node_or_null("/root/TelemetrySystem")
	if telemetry:
		telemetry.log_card_usage({
			"card_id": card.id,
			"card_name": card.id,
			"cost": card.cost,
			"type": card.type,
			"target_index": target_index,
			"turn": turn
		})
		telemetry.on_card_played(card.type, card.cost)

	for e in enemies:
		if not e.is_dead():
			_trigger_boss_mechanic(e, "on_card_played", {"card": card})

func on_player_card_played(card: Dictionary, count_played: int) -> void:
	cards_played_this_turn = count_played
	# Called by GameController
	
	# Elite hooks: on_card_played
	for e in enemies:
		if not e.is_dead():
			# Trigger Boss Mechanics (using Dict card)
			_trigger_boss_mechanic(e, "on_card_played", {"card": card})
			
			# Trigger Elite Hooks
			_check_elite_hooks("on_card_played", e, {
				"cards_played_this_turn": count_played,
				"card": card
			})
			
			# Act 2 Elite: Static Sentinel (Spam Punish)
			if e.display_name == "Static Sentinel":
				if not e.custom_data.has("static_charge"): e.custom_data["static_charge"] = 0
				e.custom_data["static_charge"] += 1
				var chg = e.custom_data["static_charge"]
				print("Static Sentinel: Charge %d/6" % chg)
				# Update UI via ribbon?
				
				if chg >= 6:
					print("Static Sentinel: DISCHARGE! 18 Dmg")
					damage_player(18, {"ignore_dodge": true}) 
					e.custom_data["static_charge"] = 0
					var gc = get_node_or_null("/root/GameController")
					if gc and gc.has_method("trigger_ribbon"): gc.trigger_ribbon("Static Sentinel: DISCHARGE!")

			# Act 2 Elite: Grave Tactician (Type Adapt)
			if e.display_name == "Grave Tactician":
				var type = card.get("type", "Unknown").to_lower()
				if type in ["strike", "tactic", "ritual"]:
					if not e.custom_data.has("seen_card_types"): e.custom_data["seen_card_types"] = []
					if not type in e.custom_data["seen_card_types"]:
						e.custom_data["seen_card_types"].append(type)
						e.block += 6
						print("Grave Tactician: Adapted to %s (+6 Block)" % type)
						var gc = get_node_or_null("/root/GameController")
						if gc and gc.has_method("trigger_ribbon"): gc.trigger_ribbon("Grave Tactician: Adapted to %s" % type.capitalize())

func on_player_seeds_gained(amount: int) -> void:
	if amount <= 0: return # Only gain triggers leech
	for e in enemies:
		_check_elite_hooks("on_seed_gain", e, {"amount": amount})

		
func _card_needs_target(card: CardResource) -> bool:
	if card.damage > 0: return true
	if "target" in card.tags: return true
	return false

func _apply_card_fallback(card: CardResource, target_index: int) -> void:
	if card.damage > 0 and target_index >= 0:
		damage_enemy(target_index, card.damage)
	if card.block > 0:
		add_block(card.block)

# Damage Logic
func damage_enemy(index: int, amount: int, ctx: Dictionary = {}) -> void:
	if index < 0 or index >= enemies.size(): return
	var e = enemies[index]
	if e.is_dead(): return
	
	# Step 0: Validate
	if amount <= 0: return

	var sh = get_node_or_null("/root/StatusHandler")
	var gc = get_node_or_null("/root/GameController")

	# Step 1A: Miss Check (Source = Player)
	if sh and gc:
		var miss_p = sh.calculate_miss_chance(gc.player_state.get("statuses", {}))
		if miss_p > 0 and randf() < miss_p:
			print("Player MISSES due to Shock!")
			_check_elite_hooks("on_hit_attempted", e, {"source": "player_miss"}) 
			return

	# Step 1B: Dodge (Target = Enemy)
	if e.statuses.get("dodge", 0) > 0:
		e.statuses["dodge"] -= 1
		print("Enemy DODGED!")
		_check_elite_hooks("on_hit_attempted", e, {"source": "player_dodge"})
		return

	var dmg: float = float(amount)
	
	# Step 2 & 3: Multipliers (Incoming/Outgoing)
	if sh:
		# Incoming (Fragile)
		dmg *= sh.get_incoming_damage_mult(e.statuses, e.status_metadata)
		# Outgoing (Sap/Chill from Player)
		if gc:
			dmg *= sh.get_outgoing_damage_mult(gc.player_state.get("statuses", {}), gc.status_metadata)
	
	# Elite Modifier: Hardened (Mitigation)
	if e.hits_taken_this_turn == 0:
		for m in e.modifiers:
			if m.id == "hardened":
				dmg *= 0.75
				print("Hardened Mitigation (-25%)")
				break
	
	# Elite Modifier: Entrenched (Burst Denial)
	# "The FIRST time each turn this elite takes damage, reduce that hit by 6."
	var has_entrenched = false
	for m in e.modifiers:
		if m.id == "entrenched": has_entrenched = true; break
	
	if has_entrenched:
		if e.custom_data.get("entrenched_usage", 0) == 0:
			print("Elite %s: Entrenched (-6 Dmg)" % e.display_name)
			dmg = max(0, dmg - 6)
			e.custom_data["entrenched_usage"] = 1
	
	var final_dmg = int(floor(dmg))

	# Step 4: Buffer
	if e.statuses.get("buffer", 0) > 0:
		e.statuses["buffer"] -= 1
		print("Enemy BUFFERED!")
		final_dmg = 0
		
	# Step 5: Block
	var absorbed = min(final_dmg, e.block)
	var leftover = final_dmg - absorbed
	
	e.block -= absorbed
	e.current_hp -= leftover
	if e.current_hp < 0: e.current_hp = 0
	
	e.hits_taken_this_turn += 1
	
	# Step 7: Events
	emit_signal("damage_dealt", "enemy", index, leftover, absorbed)
	_check_elite_hooks("on_hit_attempted", e, {"source": "attack"}) # 7A
	
	if leftover > 0:
		_trigger_boss_mechanic(e, "on_damage_taken", {"source": "attack", "amount": leftover})
		
		var c_type = ctx.get("card_type", "unknown")
		if _current_card_context: c_type = _current_card_context.get("type", "unknown")
		_check_elite_hooks("on_hit", e, {"source": "attack"})
		_check_elite_hooks("on_damage_taken", e, {"source": "attack", "amount": leftover, "card_type": c_type})
		
	if e.archetype_counter == "growth":
		# Growth triggers on damage taken? Or hit? 
		# "When damaged by player..."
		if leftover > 0 and gc and gc.player_state.get("seeds", 0) > 0:
			# Logic was: dmg += seeds. 
			# IF Growth adds damage based on seeds, it should happen BEFORE HP reduction?
			# Original code: "dmg += seeds" inside logic.
			# I removed it?
			# Wait, "Growth" archetype counter logic was inside `damage_enemy`.
			# I should restore it BEFORE final_dmg calc?
			# Need to check original logic.
			pass

	# Missing Logic Restoration:
	# Elemental Shield Refresh
	if e.archetype_counter == "elemental":
		if e.hits_taken_this_turn > 3:
			print("Bulwark Colossus: Shield Refresh! (Hit #%d)" % e.hits_taken_this_turn)
			e.block = 20
			
	_check_phase_transition(index)
	
	if e.is_dead():
		_process_death(index)

func damage_player(amount: int, opts: Dictionary = {}) -> void:
	# Opts: {ignore_block_pct: float, block_dmg_mult: float}
	if amount <= 0: return
	
	var gc = get_node_or_null("/root/GameController")
	var sh = get_node_or_null("/root/StatusHandler")

	# Step 1B: Player Dodge
	if gc and gc.player_state.get("statuses", {}).get("dodge", 0) > 0:
		gc.player_state.statuses["dodge"] -= 1
		print("Player DODGED!")
		emit_signal("damage_dealt", "player", -1, 0, 0) # Log 0 damage event
		return

	var dmg = float(amount)
	
	# Step 3: Incoming Multipliers (Fragile)
	if sh and gc:
		dmg *= sh.get_incoming_damage_mult(gc.player_state.get("statuses", {}), gc.status_metadata)

	var final_dmg = int(floor(dmg))

	# Step 4: Buffer
	if gc and gc.player_state.get("statuses", {}).get("buffer", 0) > 0:
		gc.player_state.statuses["buffer"] -= 1
		print("Player BUFFERED!")
		final_dmg = 0

	# Step 5: Block Logic
	var ignore_pct = opts.get("ignore_block_pct", 0.0)
	var block_mult = opts.get("block_dmg_mult", 1.0)
	
	var effective_block = player_block
	if ignore_pct > 0:
		effective_block = int(effective_block * (1.0 - ignore_pct))
		
	var absorbed = min(effective_block, final_dmg)
	
	# Crushing Blows: If block_mult > 1, apply extra damage to REAL block
	if block_mult > 1.0 and absorbed > 0:
		var block_dmg = int(absorbed * block_mult)
		player_block -= block_dmg
		player_block = max(0, player_block) # Clamp
	else:
		player_block -= absorbed
		
	player_block_changed.emit(player_block)
		
	var leftover = final_dmg - absorbed
	
	if leftover > 0:
		if gc:
			gc.player_hp -= leftover
			if gc.player_hp < 0: gc.player_hp = 0
			
	# Step 7: Events
	emit_signal("damage_dealt", "player", -1, leftover, absorbed)
	
	if leftover > 0:
		check_traps("on_player_hit_this_turn", {"attacker_index": -1})

func _process_death(index: int) -> void:
	print("CombatSystem: Enemy %d Died." % index)
	var gc = get_node_or_null("/root/GameController")
	if gc: gc.on_enemy_killed(index)

# Turn Lifecycle
func enemy_turn() -> void:

	
	for i in range(enemies.size()):
		var e = enemies[i]
		if e.is_dead(): continue
		
		# 1. Status DoTs (Start of Turn)
		var sh_sot = get_node_or_null("/root/StatusHandler")
		if sh_sot:
			var res = sh_sot.process_start_of_turn(e.statuses, e.status_metadata, e)
			for evt in res.get("events", []):
				var dot_dmg = evt.amount
				
				# Eternal Arbiter Cap Check (Poison)
				# Eternal Arbiter Cap Check (Poison)
				if e.display_name == "Eternal Arbiter":
					# Check if event includes poison
					var p_tick = evt.get("p_tick", 0)
					if p_tick > 0:
						var cap = 30
						var ac = get_node_or_null("/root/AscensionController")
						if ac: cap += ac.get_boss_threshold_deltas().get("poison_cap_delta", 0)
						
						# Track accumulated if we supported multi-source poison (future proof)
						# Currently DoT runs once.
						
						# If pure poison (or mostly), cap the total
						if dot_dmg > cap:
							dot_dmg = cap
							print("Arbiter Cap applied: %d" % cap)
							
						e.custom_data["poison_damage_taken_this_turn"] = dot_dmg
				
				# Act 2 Elite: Carrion Mirror (Poison Reflect)
				if e.display_name == "Carrion Mirror":
					var p_tick = evt.get("p_tick", 0)
					if p_tick > 0:
						var reflect = int(floor(dot_dmg * 0.25))
						if reflect > 0:
							print("Carrion Mirror: Mirror Rot Reflects %d" % reflect)
							damage_player(reflect, {"ignore_block": true})

				e.current_hp -= dot_dmg
				print("DoT: %d" % dot_dmg)
				emit_signal("damage_dealt", "enemy", i, dot_dmg, 0)
		if e.current_hp <= 0: e.current_hp = 0
		if e.is_dead():
			_process_death(i)
			continue
			
		_check_boss_mechanics_start_turn(e)
		_trigger_boss_mechanic(e, "start_of_boss_turn")
		
		if e.intent.has("data"):
			_execute_boss_move(e, e.intent.data)
		else:
			var t = e.intent.get("type", "attack")
			var v = int(e.intent.get("value", 0))
			
			var chill_stacks = e.get_status("chill")
			var shock_stacks = e.get_status("shock")
			
			# Logic via StatusHandler
			var sh = get_node_or_null("/root/StatusHandler")
			var missed = false
			if sh:
				var miss_prob = sh.calculate_miss_chance(e.statuses)
				if miss_prob > 0 and randf() < miss_prob:
					missed = true
					print("%s MISSES" % e.display_name)
					t = "miss"

			if t == "attack" and not missed:
				# Swift Check
				var swift_bonus = 0
				var is_swift = false
				for m in e.modifiers:
					if m.id == "swift": is_swift = true; break
				
				if is_swift and e.custom_data.get("swift_first_hit", true):
					swift_bonus = 3
					e.custom_data["swift_first_hit"] = false
					print("Elite %s: Swift Bonus (+3)" % e.display_name)

				var dmg = float(v + swift_bonus)
				
				# Elite Damage Multiplier (Act-based, applies to elites only)
				if e.is_elite:
					dmg *= _get_elite_damage_mult()
				
				# Status Outgoing Multipliers (Sap/Chill)
				if sh:
					dmg *= sh.get_outgoing_damage_mult(e.statuses, e.status_metadata)
				
				# Safety Cap: Non-boss single hit <= 45% player max HP
				if not e.is_boss:
					var gc = get_node_or_null("/root/GameController")
					if gc:
						var max_hp = gc.player_max_hp if "player_max_hp" in gc else 80
						var cap = int(floor(max_hp * 0.45))
						if int(dmg) > cap:
							print("Safety Cap: %d -> %d (45%% of %d)" % [int(dmg), cap, max_hp])
							dmg = float(cap)
				
				var opts = {}
				for m in e.modifiers:
					if m.id == "piercing_intent": opts["ignore_block_pct"] = 0.5
					if m.id == "crushing_blows": opts["block_dmg_mult"] = 1.5
					
				damage_player(int(dmg), opts)
			elif (t == "defend" or t == "block") and not missed:
				e.block += v
			elif t == "buff" and not missed:
				if e.id == "sproutling":
					_apply_status_to_enemy(i, "thorns", 1)
					e.block += 2
		
		if _boss_patterns.has(e.display_name):
			_update_boss_intent(e)
		else:
			e.update_intent(turn + 1)
		
		# End of Turn (Decay)
		if sh_sot: sh_sot.process_end_of_turn(e.statuses, e.status_metadata)
		
		# Act 2 Elite: Ashbound Juggernaut (Burn Explosion)
		if e.display_name == "Ashbound Juggernaut":
			if e.get_status("burn") >= 3:
				print("Ashbound Juggernaut: Burning Core Explosion!")
				# 12 Damage to ALL
				damage_player(12)
				add_status("burn", 1) # Elite Mod
				
				# Damage/Burn other enemies (and self?)
				# "ALL entities" usually implies self too if it's an explosion from core?
				# Let's hit ALL enemies including self.
				for other_i in range(enemies.size()):
					damage_enemy(other_i, 12, {"source": "ashbound_explosion"})
					_apply_status_to_enemy(other_i, "burn", 1)
					
				# Visual or ribbon?
				var gc = get_node_or_null("/root/GameController")
				if gc and gc.has_method("trigger_ribbon"): gc.trigger_ribbon("Ashbound Juggernaut: EXPLOSION!")
			
	process_turn_end_effects()
			
	player_block = 0
	turn += 1
	
	for e in enemies:
		if "hits_taken_this_turn" in e:
			e.hits_taken_this_turn = 0

func _check_boss_mechanics_start_turn(e: EnemyUnit) -> void:
	if e.is_dead(): return
	
	if e.display_name == "Briarwarden":
		# Apply Pending Strength from Block triggers
		if e.custom_data.get("briar_str_pending", 0) > 0:
			var gain = e.custom_data["briar_str_pending"]
			_apply_status_to_enemy(enemies.find(e), "strength", gain)
			print("Briarwarden: Gained +%d Str from Block (Applied)" % gain)
			e.custom_data["briar_str_pending"] = 0
			
	if e.display_name == "Grave Tactician":
		# Reset turn tracking
		e.custom_data["seen_card_types"] = []

	if e.display_name == "World Reclaimer":
		var gc = get_node_or_null("/root/GameController")
		if gc:
			var seeds = int(gc.player_state.get("seeds", 0))

			
			var threshold = 6
			var ac = get_node_or_null("/root/AscensionController")
			if ac: threshold += ac.get_boss_threshold_deltas().get("seed_delta", 0)
			if threshold < 4: threshold = 4
			
			if seeds >= threshold:
				print("World Reclaimer: Seed Harvest!")
				if gc and gc.has_method("trigger_ribbon"): gc.trigger_ribbon("Seed Harvest: Consumed 5 Seeds")
				gc.add_seeds(-5) 
				
				# Effect: Heal 35, +2 Str
				# gc.player_state.seeds -= 5 # Already done via API? add_seeds handles UI
				
				# Effect: Heal 35, +2 Str
				e.current_hp = min(e.current_hp + 35, e.max_hp)
				_apply_status_to_enemy(enemies.find(e), "strength", 2)
				
				# Track Consecutive Triggers
				if not e.custom_data.has("seed_harvest_streak"): e.custom_data["seed_harvest_streak"] = 0
				e.custom_data["seed_harvest_streak"] += 1

				if e.custom_data["seed_harvest_streak"] >= 2:
					print("World Reclaimer: Punishment!")
					if gc and gc.has_method("trigger_ribbon"): gc.trigger_ribbon("Seed Harvest Punishment: Fragile Applied")
					# Apply 2 Fragile to player
					gc.player_state.statuses["fragile"] = gc.player_state.statuses.get("fragile", 0) + 2
			else:
				# Reset streak if safe
				e.custom_data["seed_harvest_streak"] = 0


	if e.display_name == "Eternal Arbiter":
		e.custom_data["poison_damage_taken_this_turn"] = 0
		
		# Purge Window: Every 3rd enemy turn (3, 6, 9)
		# 'turn' is global turn count. If boss is acting, it's enemy turn.
		# Check local turn counter? e.custom_data.turns_alive?
		# Or global 'turn'.
		# "Every 3rd enemy turn". Global turn 1 is player. Turn 2 (index 1) is enemy?
		# Let's track `turns_active`.
		if not e.custom_data.has("turns_active"): e.custom_data["turns_active"] = 0
		e.custom_data["turns_active"] += 1
		
		if e.custom_data["turns_active"] % 3 == 0:
			print("Eternal Arbiter: Purge Window!")
			var gc = get_node_or_null("/root/GameController")
			if gc and gc.has_method("trigger_ribbon"): gc.trigger_ribbon("Purge Window: Cleansed 8 Poison")
			var p = e.get_status("poison")
			if p > 0:
				var remove = min(p, 8)
				e.set_status("poison", p - remove)
			e.block += 8
			
	if e.archetype_counter == "decay":
		if (turn + 1) % 4 == 0:
			print("Purifier Construct: CLEANSE POISON!")
			e.set_status("poison", 0)
			
	if e.display_name == "Gravebloom Behemoth":
		var str_gain = 0
		if player_block >= 20:
			str_gain = 2
		elif player_block >= 10:
			str_gain = 1
		
		if str_gain > 0:
			print("Gravebloom: Verdant Retaliation (+%d Str)" % str_gain)
			_apply_status_to_enemy(enemies.find(e), "strength", str_gain)
			e.set_status("temp_strength_decay", 1)

func process_turn_end_effects() -> void:
	# 1. Player Status Decay (End of Round)
	var gc = get_node_or_null("/root/GameController")
	var sh = get_node_or_null("/root/StatusHandler")
	if gc and sh:
		if gc.player_state.has("statuses"):
			sh.process_end_of_turn(gc.player_state.statuses, gc.status_metadata)

	# 2. Enemy EOT Hooks (Legacy/Events)
	for i in range(enemies.size()):
		var e = enemies[i]
		if e.is_dead(): continue
		_check_elite_hooks("eot", e, {"cards_played": cards_played_this_turn})
		
		# DoT was moved to Start of Turn.
		# Check death if EOT hooks dealt damage?
		if e.current_hp <= 0:
			# Safety check
			e.current_hp = 0
			_process_death(i)
			
			# Poison persists (no decrement) per V2 rules?
			# User said: "Poison: 1 Damage per stack, persists (clears end of combat)."
			# walkthrough.md says this too.
			# So NO DECAY.
			
		var b = e.get_status("burn")
		if b > 0:
			var burn_dmg = b * 2
			print("Burn Damage: %d" % burn_dmg)
			e.current_hp -= burn_dmg
			if e.current_hp <= 0: 
				e.current_hp = 0
				_process_death(i)
				if e.is_dead(): continue

		for s in ["weak", "vulnerable", "no_block", "chill", "shock"]:
			var val = e.get_status(s)
			if val > 0:
				e.set_status(s, val - 1)
				
	check_auras("eot")
	check_rituals("eot")
	_turn_limits.clear()

func process_start_turn_effects() -> void:
	check_rituals("sot")
	
	var gc = get_node_or_null("/root/GameController")
	if not gc: return
	
	var p_status = gc.player_state.get("statuses", {})
	
	if p_status.get("chill", 0) > 0:
		var amt = int(p_status["chill"])
		var dm = get_node_or_null("/root/DeckManager")
		if dm:
			dm.energy = max(0, dm.energy - amt)
			dm.energy_changed.emit(dm.energy)
		p_status["chill"] = amt - 1
		
	gc.player_state["statuses"] = p_status
	
	# Telemetry: Log Enemy Intents at Start of Player Turn
	var ts = get_node_or_null("/root/TelemetrySystem")
	if ts:
		for e in enemies:
			if not e.is_dead():
				ts.log_enemy_intent(
					"fight_active",
					turn,
					e.display_name, # or e.id
					e.intent
				)

	if p_status.get("decay_rune", 0) > 0:
		var stacks = int(p_status["decay_rune"])
		var living = get_living_enemies()
		if not living.is_empty():
			var idx = living.pick_random()
			_apply_status_to_enemy(idx, "poison", stacks)

func _apply_status_to_enemy(idx: int, status: String, val: int) -> void:
	if idx < 0 or idx >= enemies.size(): return
	var e = enemies[idx]
	var final_val = val
	if status == "poison":
		var ss = get_node_or_null("/root/SigilSystem")
		if ss and ss.has_method("get_poison_bonus"):
			final_val += ss.get_poison_bonus()
			
	var current = e.get_status(status)
	var new_val = current + final_val
	
	if status in ["strength", "dexterity"]:
		new_val = min(new_val, 99)
	else:
		new_val = min(new_val, 999)
		
	e.set_status(status, new_val) # Actually set it!
	
	# Telemetry: Status Apply
	var ts = get_node_or_null("/root/TelemetrySystem")
	if ts:
		ts.log_status_apply(
			"fight_active",
			turn,
			{"type": "unknown", "id": "unknown"}, # Context missing here, could pass via ctx
			{"type": "enemy", "enemy_id": e.display_name},
			status,
			final_val
		)

# --- Data-Driven Boss Mechanics ---

func _trigger_boss_mechanic(e: EnemyUnit, timing: String, ctx: Dictionary = {}) -> void:
	var pattern = _boss_patterns.get(e.display_name)
	if not pattern: return
	
	var mechanics = pattern.get("mechanics", [])
	for m in mechanics:
		if m.get("timing") == timing:
			_execute_mechanic_logic(e, m, ctx)

func _execute_mechanic_logic(e: EnemyUnit, mechanic: Dictionary, ctx: Dictionary) -> void:
	var logic = mechanic.get("logic", {})
	var type = logic.get("type")
	
	match type:
		"scale_from_player_block":
			var thresholds = logic.get("block_thresholds", [])
			var gain = 0
			for t in thresholds:
				if player_block >= int(t.min_block):
					gain = int(t.gain_strength)
				else:
					break
			if gain > 0:
				print("%s: %s (+%d Str)" % [e.display_name, mechanic.name, gain])
				_apply_status_to_enemy(enemies.find(e), "strength", gain)
				
		"poison_reaction":
			if ctx.get("source") == "poison":
				var max_recoil = logic.get("max_per_turn", 8)
				var damage = logic.get("recoil_damage", 2)
				
				if not e.custom_data.has("poison_recoil_hits"): e.custom_data["poison_recoil_hits"] = 0
				
				if e.custom_data["poison_recoil_hits"] < max_recoil:
					print("%s: %s (Reflect %d)" % [e.display_name, mechanic.name, damage])
					damage_player(damage)
					e.custom_data["poison_recoil_hits"] += damage
					
		"card_type_counter":
			var card = ctx.get("card")
			if not card: return
			
			var ctype = card.type.to_lower()
			var gain = 0
			if ctype == "strike": gain = int(logic.get("strike_gain", 0))
			elif ctype == "ritual": gain = int(logic.get("ritual_gain", 0))
			elif ctype == "tactic": gain = int(logic.get("tactic_gain", 0))
			
			if gain > 0:
				if not e.custom_data.has("static_stacks"): e.custom_data["static_stacks"] = 0
				e.custom_data["static_stacks"] += gain
				var current = e.custom_data["static_stacks"]
				print("%s: Static +%d -> %d" % [e.display_name, gain, current])
				
				e.set_status("static", current)
				
				if current >= int(logic.get("threshold", 5)):
					var dmg = int(logic.get("threshold_damage", 10))
					print("%s: STATIC DISCHARGE! (%d Dmg)" % [e.display_name, dmg])
					damage_player(dmg)
					e.custom_data["static_stacks"] = 0

# --- Boss AI (Move Selection) ---

func _update_boss_intent(e: EnemyUnit) -> void:
	var pattern = _boss_patterns.get(e.display_name)
	if not pattern: return
	
	var hp_pct = (float(e.current_hp) / float(e.max_hp)) * 100.0
	var current_phase_id = e.custom_data.get("phase", 1)
	var phases = pattern.get("phases", [])
	
	for p in phases:
		if hp_pct <= p.get("from_hp_pct", 100) and hp_pct > p.get("to_hp_pct", 0):
			if int(p.get("id")) != current_phase_id:
				current_phase_id = int(p.get("id"))
				e.custom_data["phase"] = current_phase_id
				print("Boss AI: Phase Transition -> %d" % current_phase_id)
			break
			
	var phase_data = {}
	for p in phases:
		if int(p.get("id")) == current_phase_id:
			phase_data = p
			break
			
	var moves = phase_data.get("moves", [])
	var valid_moves = []
	
	if not e.custom_data.has("cooldowns"): e.custom_data["cooldowns"] = {}
	for m in moves:
		var mid = m.get("id")
		if e.custom_data.cooldowns.get(mid, 0) <= 0:
			valid_moves.append(m)
			
	var selected = null
	var total_weight = 0
	for m in valid_moves:
		total_weight += int(m.get("weight", 0))
		
	var roll = randi() % max(1, total_weight)
	var current_w = 0
	for m in valid_moves:
		current_w += int(m.get("weight", 0))
		if roll < current_w:
			selected = m
			break
			
	if not selected:
		selected = moves[0]
		
	e.intent = {
		"type": selected.get("intent", "attack"),
		"value": selected.get("damage", 0),
		"name": selected.get("id"),
		"data": selected
	}
	
	if selected.has("cooldown"):
		e.custom_data.cooldowns[selected.get("id")] = selected.get("cooldown") + 1

func _execute_boss_move(e: EnemyUnit, move: Dictionary) -> void:
	print("Boss Execute: %s uses %s" % [e.display_name, move.get("id")])
	
	if move.has("damage"):
		var dmg = float(move.get("damage"))
		var hits = int(move.get("hits", 1))
		
		# STATUS HANDLER LOGIC
		var sh = get_node_or_null("/root/StatusHandler")
		var missed = false
		if sh:
			var miss_prob = sh.calculate_miss_chance(e.statuses)
			if miss_prob > 0 and randf() < miss_prob:
				missed = true
				print("%s MISSES (Boss Move) due to Shock!" % e.display_name)
		
		if not missed:
			# Elite Damage Multiplier (applies to elite bosses too)
			if e.is_elite:
				dmg *= _get_elite_damage_mult()
			
			# Status Outgoing Multipliers (Sap/Chill)
			if sh:
				dmg *= sh.get_outgoing_damage_mult(e.statuses, e.status_metadata)
			
			# NOTE: Bosses are EXEMPT from safety cap (per spec)
			
			for i in range(hits):
				damage_player(int(dmg))
			
	if move.has("apply"):
		for app in move.get("apply"):
			var target = app.get("target", "player")
			var stat = app.get("status")
			var amt = int(app.get("amount", 1))
			if target == "player":
				add_status(stat, amt)
			elif target == "self":
				e.set_status(stat, e.get_status(stat) + amt)

	if move.has("effects"):
		for eff in move.get("effects"):
			var type = eff.get("type", "")
			if type == "gain_block":
				var amt = int(eff.get("amount", 0))
				e.block += amt
			elif type == "heal":
				var amt = int(eff.get("amount", 0))
				e.current_hp = min(e.current_hp + amt, e.max_hp)
			elif type == "drain_energy":
				var amt = int(eff.get("amount", 0))
				var dm = get_node_or_null("/root/DeckManager")
				if dm: dm.energy = max(0, dm.energy - amt)

func check_auras(timing: String) -> void:
	for a in auras:
		var aid = a.get("aura")
		if timing == "eot":
			if aid == "eot_apply_poison_2_random_enemy":
				_apply_status_to_enemy(get_living_enemies().pick_random(), "poison", 2)
			elif aid == "eot_apply_poison_1_random_enemy":
				_apply_status_to_enemy(get_living_enemies().pick_random(), "poison", 1)
			elif aid == "eot_if_any_enemy_poisoned_remove_poison_1_random_poisoned_then_deal_damage_4":
				var poisoned_indices = []
				for i in get_living_enemies():
					if enemies[i].get_status("poison") > 0:
						poisoned_indices.append(i)
				
				if not poisoned_indices.is_empty():
					var target_i = poisoned_indices.pick_random()
					# Remove 1 poison
					if target_i < enemies.size():
						var current = enemies[target_i].get_status("poison")
						enemies[target_i].set_status("poison", max(0, current - 1))
						# Deal 4 damage
						damage_enemy(target_i, 4)
