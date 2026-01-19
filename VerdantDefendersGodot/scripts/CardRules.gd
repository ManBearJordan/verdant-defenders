extends Node

# CardRules resolves the effects of a card against the CombatSystem and
# DeckManager per EFFECT_VERBS.md. Cards contain "effects" array with
# effect verbs like deal_damage, gain_block, draw_cards.

# New apply_effects method that matches the task requirements
func apply_effects(target: Node, effects: Array, ctx: Dictionary) -> void:
	"""Apply effects array to target with context"""
	for effect in effects:
		if effect is Dictionary:
			var effect_dict: Dictionary = effect as Dictionary
			var effect_type: String = String(effect_dict.get("type", ""))
			
			match effect_type:
				"deal_damage":
					var amount: int = int(effect_dict.get("amount", 0))
					_deal_damage_to_target(target, amount)
				"gain_block":
					var amount: int = int(effect_dict.get("amount", 0))
					_gain_player_block(amount)
				"draw_cards":
					var amount: int = int(effect_dict.get("amount", 1))
					_draw_cards(amount)
				"heal":
					var amount: int = int(effect_dict.get("amount", 0))
					_heal_player(amount)
				"aoe_damage":
					var amount: int = int(effect_dict.get("amount", 0))
					_aoe_damage(amount)
				"apply_status":
					var status: String = String(effect_dict.get("status", ""))
					var amount: int = int(effect_dict.get("amount", 1))
					_apply_status_to_target(target, status, amount)
				_:
					print("CardRules: Unknown effect type: %s" % effect_type)

func resolve(card: Dictionary, cs: Node, dm: Node, target_index: int) -> void:
	# Process effects array if present
	if card.has("effects") and card["effects"] is Array:
		var effects: Array = card["effects"] as Array
		for effect in effects:
			if effect is Dictionary:
				apply_effect(effect as Dictionary, cs, dm, target_index)
	
	# Legacy support for direct card properties (damage, block, etc.)
	_resolve_legacy_format(card, cs, dm, target_index)

func apply_effect(effect: Dictionary, cs: Node, dm: Node, target_index: int) -> void:
	var effect_type: String = String(effect.get("type", ""))
	
	match effect_type:
		"deal_damage":
			var amount: int = int(effect.get("amount", 0))
			deal_damage(cs, target_index, amount)
		"gain_block":
			var amount: int = int(effect.get("amount", 0))
			gain_block(cs, amount)
		"draw_cards":
			var amount: int = int(effect.get("amount", 1))
			draw_cards(dm, amount)
		"apply_status":
			var status: String = String(effect.get("status", ""))
			var amount: int = int(effect.get("amount", 1))
			apply_status(cs, target_index, status, amount)
		"heal":
			var amount: int = int(effect.get("amount", 0))
			heal(cs, amount)
		"aoe_damage":
			var amount: int = int(effect.get("amount", 0))
			aoe_damage(cs, amount)
		_:
			# Unknown effect - add stub and continue
			print("Unknown effect type: %s" % effect_type)

# Effect verb implementations per EFFECT_VERBS.md
func deal_damage(cs: Node, target_index: int, amount: int) -> void:
	if cs != null and cs.has_method("_damage_enemy"):
		cs.call("_damage_enemy", target_index, amount)

func gain_block(cs: Node, amount: int) -> void:
	if cs != null:
		var cur: int = 0
		if "player_block" in cs:
			cur = int(cs.player_block)
			cs.player_block = cur + amount
		elif cs.has_method("add_player_block"):
			cs.call("add_player_block", amount)

func draw_cards(dm: Node, amount: int) -> void:
	if dm != null and dm.has_method("draw_cards"):
		dm.call("draw_cards", amount)

func apply_status(cs: Node, target_index: int, status: String, amount: int) -> void:
	if cs != null and cs.has_method("_apply_status_to_enemy"):
		cs.call("_apply_status_to_enemy", target_index, status.to_lower(), amount)

func heal(cs: Node, amount: int) -> void:
	# Heal player - access GameController for player_hp
	var gc: Node = get_node_or_null("/root/GameController")
	if gc != null and gc.has("player_hp"):
		var current_hp: int = int(gc.get("player_hp"))
		var max_hp: int = 80
		if gc.has("max_hp"):
			max_hp = int(gc.get("max_hp"))
		gc.set("player_hp", min(max_hp, current_hp + amount))

func aoe_damage(cs: Node, amount: int) -> void:
	"""Deal damage to all enemies"""
	if cs != null and cs.has("enemies"):
		var enemies: Array = cs.get("enemies")
		for i in range(enemies.size()):
			if cs.has_method("_damage_enemy"):
				cs.call("_damage_enemy", i, amount)

# New helper methods for apply_effects
func _deal_damage_to_target(target: Node, amount: int) -> void:
	"""Deal damage to a specific target node"""
	if target == null:
		return
	
	if target.has_method("take_damage"):
		target.call("take_damage", amount)
		print("CardRules: Dealt %d damage to %s" % [amount, target.name])
	else:
		# Fallback: try to find target in CombatSystem enemies
		var cs: Node = get_node_or_null("/root/CombatSystem")
		if cs != null and cs.has("enemies"):
			var enemies: Array = cs.get("enemies")
			var target_index = -1
			# This is a simplified approach - in a full implementation you'd have proper target tracking
			for i in range(enemies.size()):
				if enemies[i].get("name", "") == target.name:
					target_index = i
					break
			if target_index >= 0 and cs.has_method("_damage_enemy"):
				cs.call("_damage_enemy", target_index, amount)

func _gain_player_block(amount: int) -> void:
	"""Gain block for the player"""
	var cs: Node = get_node_or_null("/root/CombatSystem")
	if cs != null and cs.has_method("add_player_block"):
		cs.call("add_player_block", amount)
	elif cs != null and cs.has("player_block"):
		cs.player_block = int(cs.get("player_block")) + amount

func _draw_cards(amount: int) -> void:
	"""Draw cards"""
	var dm: Node = get_node_or_null("/root/DeckManager")
	if dm != null and dm.has_method("draw_cards"):
		dm.call("draw_cards", amount)

func _heal_player(amount: int) -> void:
	"""Heal the player"""
	var gc: Node = get_node_or_null("/root/GameController")
	if gc != null and gc.has("player_hp"):
		var current_hp: int = int(gc.get("player_hp"))
		var max_hp: int = 80
		if gc.has("max_hp"):
			max_hp = int(gc.get("max_hp"))
		gc.set("player_hp", min(max_hp, current_hp + amount))
		print("CardRules: Healed player for %d HP" % amount)

func _aoe_damage(amount: int) -> void:
	"""Deal damage to all enemies"""
	var cs: Node = get_node_or_null("/root/CombatSystem")
	if cs != null and cs.has("enemies"):
		var enemies: Array = cs.get("enemies")
		for i in range(enemies.size()):
			if cs.has_method("_damage_enemy"):
				cs.call("_damage_enemy", i, amount)
		print("CardRules: Dealt %d AoE damage to all enemies" % amount)

func _apply_status_to_target(target: Node, status: String, amount: int) -> void:
	"""Apply status to a specific target"""
	if target == null:
		return
	
	if target.has_method("apply_status"):
		target.call("apply_status", status.to_lower(), amount)
		print("CardRules: Applied %d %s to %s" % [amount, status, target.name])
	else:
		# Fallback: try CombatSystem
		var cs: Node = get_node_or_null("/root/CombatSystem")
		if cs != null and cs.has("enemies"):
			var enemies: Array = cs.get("enemies")
			var target_index = -1
			for i in range(enemies.size()):
				if enemies[i].get("name", "") == target.name:
					target_index = i
					break
			if target_index >= 0 and cs.has_method("_apply_status_to_enemy"):
				cs.call("_apply_status_to_enemy", target_index, status.to_lower(), amount)

# Legacy support for old card format (damage, block, apply, draw, energy_gain, exhaust)
func _resolve_legacy_format(card: Dictionary, cs: Node, dm: Node, target_index: int) -> void:
	# Determine whether the card targets all enemies or a single target.
	var target_all: bool = String(card.get("target", "single")) == "all"

	# ----- Damage -----
	if card.has("damage"):
		var dmg: int = int(card["damage"])
		if target_all:
			# Damage all enemies
			if cs != null and cs.has("enemies"):
				var arr: Array = cs.get("enemies") as Array
				for i in range(arr.size()):
					if cs.has_method("_damage_enemy"):
						cs.call("_damage_enemy", i, dmg)
		else:
			# Damage single target
			deal_damage(cs, target_index, dmg)

	# ----- Block -----
	if card.has("block"):
		var blk: int = int(card["block"])
		gain_block(cs, blk)

	# ----- Status apply -----
	if card.has("apply"):
		var eff: Variant = card.get("apply")
		if eff is Dictionary:
			var eff_dict: Dictionary = eff as Dictionary
			# Only apply statuses to single targets; cards targeting all could be extended
			if not target_all and target_index >= 0:
				for status_name in eff_dict.keys():
					var amt: int = int(eff_dict[status_name])
					apply_status(cs, target_index, String(status_name), amt)

	# ----- Draw cards -----
	if card.has("draw"):
		var n: int = int(card["draw"])
		draw_cards(dm, n)

	# ----- Gain energy -----
	if card.has("energy_gain"):
		var inc: int = int(card["energy_gain"])
		if dm != null and dm.has_method("gain_energy"):
			dm.call("gain_energy", inc)

	# ----- Exhaust card -----
	if bool(card.get("exhaust", false)):
		# In a fuller implementation, exhausted cards would be removed from
		# the deck for the remainder of the combat.  Here we simply
		# acknowledge the flag; DeckManager already discards cards after play.
		pass

# Example usage (pseudo-code):
# var card = {"effects": [{"type": "deal_damage", "amount": 6}, {"type": "draw_cards", "amount": 1}]}
# CardRules.resolve(card, combat_system, deck_manager, target_index)
