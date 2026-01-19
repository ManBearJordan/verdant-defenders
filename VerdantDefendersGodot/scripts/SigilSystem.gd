extends Node

# SigilSystem - manages active sigils and their hooks

var active_sigils: Array[Dictionary] = []

signal sigil_added(sigil: Dictionary)
signal sigil_removed(sigil: Dictionary)
signal sigil_triggered(sigil_id: String)

var override_game_controller: Node = null
var override_combat_system: Node = null

func _ready() -> void:
	pass

func add_sigil(sigil: Dictionary) -> void:
	"""Add a sigil to the active list"""
	active_sigils.append(sigil.duplicate(true))
	sigil_added.emit(sigil)
	print("SigilSystem: Added sigil %s" % sigil.get("name", "Unknown"))

func remove_sigil(sigil_id: String) -> void:
	"""Remove a sigil by ID"""
	for i in range(active_sigils.size()):
		if active_sigils[i].get("id", "") == sigil_id:
			var removed = active_sigils[i]
			active_sigils.remove_at(i)
			sigil_removed.emit(removed)
			print("SigilSystem: Removed sigil %s" % removed.get("name", "Unknown"))
			break

func get_active_sigils() -> Array[Dictionary]:
	"""Get all active sigils"""
	return active_sigils.duplicate()

func apply_hook(hook_name: String, ctx: Dictionary) -> Variant:
	"""Apply a sigil hook and return the result"""
	var result = null
	
	match hook_name:
		"start_turn_energy_bonus":
			result = _apply_start_turn_energy_bonus(ctx)
		"card_cost_discount":
			result = _apply_card_cost_discount(ctx)
		_:
			print("SigilSystem: Unknown hook %s" % hook_name)
	
	return result

func _apply_start_turn_energy_bonus(_ctx: Dictionary) -> int:
	"""Apply start_turn_energy_bonus hook - returns bonus energy"""
	var bonus = 0
	
	for sigil in active_sigils:
		if sigil.has("effects"):
			var effects = sigil.get("effects", {})
			if effects is Dictionary:
				var effect_dict = effects as Dictionary
				if effect_dict.has("start_turn_energy_bonus"):
					var amount = int(effect_dict.get("start_turn_energy_bonus", 0))
					bonus += amount
					print("SigilSystem: %s grants +%d energy" % [sigil.get("name", "Unknown"), amount])
					sigil_triggered.emit(sigil.get("id", ""))
	
	return bonus

func _apply_card_cost_discount(_ctx: Dictionary) -> int:
	"""Apply card_cost_discount hook - returns cost reduction"""
	var discount = 0
	
	for sigil in active_sigils:
		if sigil.has("effects"):
			var effects = sigil.get("effects", {})
			if effects is Dictionary:
				var effect_dict = effects as Dictionary
				if effect_dict.has("card_cost_discount"):
					var amount = int(effect_dict.get("card_cost_discount", 0))
					discount += amount
					print("SigilSystem: %s reduces card cost by %d" % [sigil.get("name", "Unknown"), amount])
					sigil_triggered.emit(sigil.get("id", ""))
	
	return discount

func has_sigil(sigil_id: String) -> bool:
	"""Check if a sigil is active"""
	for sigil in active_sigils:
		if sigil.get("id", "") == sigil_id:
			return true
	return false

func clear_all_sigils() -> void:
	"""Clear all active sigils"""
	active_sigils.clear()
	print("SigilSystem: Cleared all sigils")

	print("SigilSystem: Cleared all sigils")

# --- Tradeoff Sigil Logic ---

var cards_played_this_turn: int = 0

func on_turn_start() -> void:
	cards_played_this_turn = 0

func on_card_played(_card: Dictionary) -> void:
	cards_played_this_turn += 1

func should_double_cast() -> bool:
	# Check for "Ember Shard" effect: Double cast FIRST card
	if cards_played_this_turn == 0:
		for s in active_sigils:
			var fx = s.get("effect", {})
			# Note: sigils.json effect is {"type": "double_first_card", ...}
			# Check type OR key.
			if fx.get("type", "") == "double_first_card" or fx.has("double_first_card"):
				print("SigilSystem: Double Cast Triggered via %s" % s.name)
				sigil_triggered.emit(s.get("id", ""))
				return true
	return false

func get_hand_size_modifier() -> int:
	var mod = 0
	for s in active_sigils:
		var fx = s.get("effect", {})
		if fx.has("hand_size_malus"):
			mod -= int(fx.get("hand_size_malus"))
	return mod

func get_poison_bonus() -> int:
	var bonus = 0
	for s in active_sigils:
		var fx = s.get("effect", {})
		if fx.get("type", "") == "poison_bonus" or fx.has("poison_bonus"):
			# If structure is {"type": "poison_bonus", "amount": 2} ...
			if fx.has("amount"):
				bonus += int(fx.get("amount"))
			# Or if key "poison_bonus": 2
			elif fx.has("poison_bonus") and fx["poison_bonus"] is float: # check numeric
				bonus += int(fx.get("poison_bonus"))
	return bonus

func apply_start_combat_effects(cs: Node) -> void:
	for s in active_sigils:
		var fx = s.get("effect", {})
		if fx.has("start_combat_self_poison"):
			var amt = int(fx.get("start_combat_self_poison"))
			if cs.has_method("add_status"):
				# Warning: CombatSystem.add_status usually logs. 
				# Real application needs logic to target player? 
				# CombatSystem has 'add_status' method BUT it says "Stub for calling GC/Player".
				# Let's verify CombatSystem later.
				# Actually CombatSystem `add_status` is a stub.
				# We should probably apply status to GameController player state directly if CS doesn't handle it.
				# Or implement `add_player_status` in CombatSystem properly.
				pass 
			# Direct GC modification for now to ensure it works
			var gc = override_game_controller if override_game_controller else get_node_or_null("/root/GameController")
			if gc:
				var ps = gc.player_state.get("statuses", {})
				ps["poison"] = ps.get("poison", 0) + amt
				gc.player_state["statuses"] = ps
				print("SigilSystem: %s applied %d Self Poison" % [s.name, amt])
				sigil_triggered.emit(s.get("id", ""))
