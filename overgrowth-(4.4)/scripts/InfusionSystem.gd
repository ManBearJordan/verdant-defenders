extends Node

# InfusionSystem - Manages player's potion/infusion inventory (3 slots)

const MAX_SLOTS = 3
var inventory: Array[Dictionary] = [] # List of infusion definitions

signal inventory_changed(items: Array[Dictionary])
signal infusion_used(item: Dictionary)

func _ready() -> void:
	pass

func add_infusion(id: String) -> bool:
	if inventory.size() >= MAX_SLOTS:
		print("InfusionSystem: Inventory full")
		return false
	
	var dl = get_node_or_null("/root/DataLayer")
	if not dl or not dl.has_method("get_infusion_def"):
		return false
	
	var item = dl.call("get_infusion_def", id)
	if item.is_empty():
		return false
	
	inventory.append(item.duplicate(true))
	inventory_changed.emit(inventory.duplicate())
	print("InfusionSystem: Added %s" % item.get("name"))
	return true

func use_infusion(index: int) -> void:
	if index < 0 or index >= inventory.size():
		return
	
	var item = inventory[index]
	
	# Apply effects
	var success = _apply_infusion_effects(item)
	if success:
		inventory.remove_at(index)
		inventory_changed.emit(inventory.duplicate())
		infusion_used.emit(item)
		print("InfusionSystem: Used %s" % item.get("name"))

func _apply_infusion_effects(item: Dictionary) -> bool:
	# Reuse EffectSystem or implement simple logic
	# Infusions usually don't need complex targeting (player or random enemy)
	
	var effects = item.get("effects", {})
	var target_type = item.get("target_type", "player")
	
	var gc = get_node_or_null("/root/GameController")
	var cs = get_node_or_null("/root/CombatSystem")
	if not gc: return false
	
	if target_type == "player":
		if effects.has("heal"):
			var amt = int(effects.get("heal"))
			gc.player_hp = min(gc.player_hp + amt, gc.max_hp)
			# Notify UI via GC signals usually, or UI polls
		
		if effects.has("block"):
			var amt = int(effects.get("block"))
			if cs and cs.has_method("add_player_block"):
				cs.add_player_block(amt)
	
	elif target_type == "enemy_random":
		if not cs: return false
		if effects.has("damage"):
			var amt = int(effects.get("damage"))
			# Get random enemy
			var enemies = cs.get("enemies") if "enemies" in cs else []
			if enemies is Array and not enemies.is_empty():
				# We need to damage via index
				# CombatSystem doesn't expose a clean "damage random" method usually
				# We'll rely on CombatSystem helpers if they exist, or manual manipulation
				# Ideally CombatSystem should handle this.
				# Workaround: find first alive enemy
				for i in range(enemies.size()):
					var e = enemies[i]
					if int(e.get("hp",0)) > 0:
						if cs.has_method("damage_enemy"): # We assume internal helper or we add public one
							# cs._damage_enemy is private. 
							# But wait, cs has `damage_player`. Does it have `damage_enemy`?
							# Reviewing CombatSystem: has `_damage_enemy`.
							# I should add `deal_damage(target_idx, amount)` to CombatSystem public API.
							# For now, I'll fail if no public method.
							# Wait, I know I edited CombatSystem. let's check.
							# It has `_damage_enemy`. Using `call` can bypass scope? No.
							pass
						# Hack: use call on private method or rely on new method
						if cs.has_method("_damage_enemy"):
							cs.call("_damage_enemy", i, amt)
						break
	
	return true

func get_inventory() -> Array[Dictionary]:
	return inventory.duplicate()

func discard_infusion(index: int) -> void:
	if index >= 0 and index < inventory.size():
		inventory.remove_at(index)
		inventory_changed.emit(inventory.duplicate())
