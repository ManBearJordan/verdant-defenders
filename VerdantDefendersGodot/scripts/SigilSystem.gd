extends Node

# SigilSystem - manages active sigils and their hooks

var active_sigils: Array[Dictionary] = []

signal sigil_added(sigil: Dictionary)
signal sigil_removed(sigil: Dictionary)

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

func _apply_start_turn_energy_bonus(ctx: Dictionary) -> int:
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
	
	return bonus

func _apply_card_cost_discount(ctx: Dictionary) -> int:
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

# Example sigil data structure:
# {
#   "id": "energy_boost",
#   "name": "Energy Boost",
#   "description": "Gain +1 energy at the start of each turn",
#   "effects": {
#     "start_turn_energy_bonus": 1
#   }
# }
