extends Node

# RelicSystem - manages persistent passive items (Relics)
# Relics are loaded from Data/relics.json via DataLayer

var active_relics: Array[Dictionary] = []
signal relic_added(relic: Dictionary)
signal relic_removed(relic: Dictionary)

var override_datalayer: Node = null
var override_game_controller: Node = null
var override_combat_system: Node = null
var override_deck_manager: Node = null

func _ready() -> void:
	pass

func add_relic(relic_id: String) -> void:
	# Fetch full definition from DataLayer
	var dl = override_datalayer if override_datalayer else get_node_or_null("/root/DataLayer")
	if not dl: return
	
	var relic_def = dl.call("get_relic_def", relic_id)
	if relic_def.is_empty():
		print("RelicSystem: Relic ID '%s' not found" % relic_id)
		return
	
	# Avoid duplicates if unique
	for r in active_relics:
		if r.get("id") == relic_id:
			print("RelicSystem: Already have relic %s" % relic_id)
			return

	active_relics.append(relic_def.duplicate(true))
	relic_added.emit(relic_def)
	print("RelicSystem: Added relic %s" % relic_def.get("name"))
	
	# Immediate "on_obtain" effects
	_apply_immediate_effects(relic_def)

func _apply_immediate_effects(relic: Dictionary) -> void:
	var effects = relic.get("effects", {})
	if effects.has("on_obtain_max_hp"):
		var val = int(effects.get("on_obtain_max_hp"))
		var gc = override_game_controller if override_game_controller else get_node_or_null("/root/GameController")
		if gc:
			gc.max_hp += val
			gc.player_hp += val # heal the amount gained
			print("RelicSystem: Increased Max HP by %d" % val)
			# Notify UI update if needed (GameController signals usually handle this)

func get_relics() -> Array[Dictionary]:
	return active_relics.duplicate()

func has_relic(relic_id: String) -> bool:
	for r in active_relics:
		if r.get("id") == relic_id: return true
	return false

# --- Hooks called by other systems ---

func apply_start_combat_hooks(player: Node) -> void:
	for r in active_relics:
		var fx = r.get("effects", {})
		
		# Block
		if fx.has("start_combat_block"):
			var amt = int(fx.get("start_combat_block"))
			if player.has_method("add_block"):
				player.add_block(amt)
				print("RelicSystem: %s applied %d block" % [r.name, amt])
		
		# Thorns
		if fx.has("start_combat_thorns"):
			var amt = int(fx.get("start_combat_thorns"))
			if player.has_method("add_status"):
				player.add_status("thorns", amt)
				print("RelicSystem: %s applied %d thorns" % [r.name, amt])

func apply_end_combat_hooks(player_state: Dictionary) -> void:
	# Note: player_state usually managed by GC, but here we might need GC reference
	# Logic usually runs in GameController or RewardSystem
	var gc = override_game_controller if override_game_controller else get_node_or_null("/root/GameController")
	if not gc: return
	
	for r in active_relics:
		var fx = r.get("effects", {})
		
		if fx.has("end_combat_heal"):
			var amt = int(fx.get("end_combat_heal"))
			gc.player_hp = min(gc.player_hp + amt, gc.max_hp)
			print("RelicSystem: %s healed %d HP" % [r.name, amt])

# --- Event Hooks ---

func on_card_played(card: Dictionary) -> void:
	_check_triggers("card_played", {"card": card})

func on_turn_start() -> void:
	apply_start_turn_hooks() # Legacy call
	_check_triggers("turn_start", {})

func on_turn_end() -> void:
	_check_triggers("turn_end", {})

func on_player_block_changed(old: int, new: int) -> void:
	if new < old:
		_check_triggers("block_lost", {"amount": old - new})

func on_combat_start() -> void:
	# Called by apply_start_combat_hooks wrapper usually
	_check_triggers("combat_start", {})

func on_combat_victory() -> void:
	_check_triggers("victory", {})

# --- Trigger Logic ---

func _check_triggers(trigger_name: String, ctx: Dictionary) -> void:
	var gc = override_game_controller if override_game_controller else get_node_or_null("/root/GameController") # For context checks
	
	for r in active_relics:
		if r.get("trigger") == trigger_name:
			# Check conditions
			if _check_condition(r.get("condition", {}), ctx, gc):
				# Check limits (once per combat etc)
				if _check_limit(r, ctx):
					_apply_effect(r.get("effect", {}), ctx)
					# Flash UI?
					print("RelicSystem: %s triggered!" % r.get("name"))

func _check_condition(cond: Dictionary, ctx: Dictionary, gc: Node) -> bool:
	if cond.is_empty(): return true
	
	if cond.has("type") and cond["type"] == "attack":
		var card = ctx.get("card", {})
		if card.get("type", "").to_lower() != "strike": return false
		# TODO: Count tracking (every 2 attacks) logic is needed here
		# For now, simplest implementation
	
	if cond.has("no_attacks_this_turn"):
		# Requires GC tracking
		pass 
		
	return true # Placeholder for deep condition logic

func _check_limit(r: Dictionary, ctx: Dictionary) -> bool:
	# Improve later
	return true

func _apply_effect(eff: Dictionary, ctx: Dictionary) -> void:
	var type = eff.get("type", "")
	var gc = override_game_controller if override_game_controller else get_node_or_null("/root/GameController")
	var dm = override_deck_manager if override_deck_manager else get_node_or_null("/root/DeckManager")
	
	match type:
		"gain_energy":
			if dm: dm.gain_energy(int(eff.get("amount", 1)))
		"draw_cards":
			if dm: dm.draw_cards(int(eff.get("count", 1)))
		"gain_block":
			if gc and gc.has_method("add_player_block"):
				gc.add_player_block(int(eff.get("amount", 0)))
		"heal":
			if gc: gc.heal_player(int(eff.get("amount", 0)))
		"gain_strength":
			# Needs status system
			var cs = override_combat_system if override_combat_system else get_node_or_null("/root/CombatSystem")
			if cs: cs.apply_status_to_player("strength", int(eff.get("stacks", 1)))
		_:
			print("RelicSystem: Unknown effect type %s" % type)

func apply_start_turn_hooks() -> void:
	# Legacy hook (keep for now or refactor)
	var dl = override_deck_manager if override_deck_manager else get_node_or_null("/root/DeckManager")
	if not dl: return
	for r in active_relics:
		var fx = r.get("effects", {}) # Legacy style
		if fx.has("start_turn_energy"):
			dl.gain_energy(int(fx.get("start_turn_energy")))

func clear_relics() -> void:
	active_relics.clear()

# --- Relic Hooks (Growth Tradeoff) ---

func on_seed_spent(amount: int) -> void:
	var dmg_per_seed = 0
	for r in active_relics:
		var fx = r.get("effects", {})
		if fx.has("spend_seed_damage"):
			dmg_per_seed += int(fx.get("spend_seed_damage"))
			
	if dmg_per_seed > 0:
		var total_dmg = amount * dmg_per_seed
		print("RelicSystem: Seed Spend Penalty! Taking %d damage." % total_dmg)
		var cs = override_combat_system if override_combat_system else get_node_or_null("/root/CombatSystem")
		if cs: cs.damage_player(total_dmg)

func apply_initial_seeds(gc: Node) -> void:
	for r in active_relics:
		var fx = r.get("effects", {})
		if fx.has("start_combat_seeds"):
			var amt = int(fx.get("start_combat_seeds"))
			if gc:
				gc.player_state.seeds = gc.player_state.get("seeds", 0) + amt
				gc.update_seeds_ui()
				print("RelicSystem: %s granted %d Seeds" % [r.name, amt])
