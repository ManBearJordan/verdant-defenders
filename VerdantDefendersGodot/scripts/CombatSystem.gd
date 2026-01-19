extends Node

# List of enemies currently engaged in combat.  Each entry is a dictionary
# containing at minimum: name, hp, max_hp, block, intent and statuses.
var enemies: Array[Dictionary] = []

# Amount of block the player currently has.  Block absorbs incoming damage
# during the enemy turn and resets at the start of each enemy phase.
var player_block: int = 0

# Turn counter to track enemy intent cycles.  Increments each time the
# enemies act.
var turn: int = 0

func _ready() -> void:
	# Combat does not start until begin_encounter() is called by the
	# RoomController.  Nothing happens here.
	pass

# Begin a new encounter by loading the specified enemy pack.  Each entry in
# `pack` should be a dictionary with at least a "name" and "hp" field.  The
# CombatSystem will normalise the enemy structure and prepare their intents.
func begin_encounter(pack: Array) -> void:
	enemies.clear()
	player_block = 0
	turn = 0
	for v in pack:
		if v is Dictionary:
			var base: Dictionary = (v as Dictionary).duplicate(true)
			var e: Dictionary = {}
			e["name"] = String(base.get("name", "Enemy"))
			var hp_val: int = int(base.get("hp", 0))
			e["hp"] = hp_val
			e["max_hp"] = hp_val
			e["block"] = int(base.get("block", 0))
			# Copy or default the intent
			var intent_v: Variant = base.get("intent", {})
			var intent_dict: Dictionary = {} if not (intent_v is Dictionary) else intent_v as Dictionary
			# Ensure intent has type/value keys
			var i_type: String = String(intent_dict.get("type", "attack"))
			var i_val: int = int(intent_dict.get("value", 6))
			e["intent"] = {"type": i_type, "value": i_val}
			# Add a statuses dictionary for poison/weak/vulnerable etc
			e["statuses"] = {}
			enemies.append(e)
	# Immediately grant the player a starting hand and energy for the first turn
	var dm: Node = get_node_or_null("/root/DeckManager")
	if dm != null and dm.has_method("start_turn"):
		dm.call_deferred("start_turn")

# Returns a duplicate of the current enemies list.  UI callers should treat
# the returned data as read‑only.
func get_enemies() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e in enemies:
		if e is Dictionary:
			out.append((e as Dictionary).duplicate(true))
	return out

# Play a card from the hand.  Handles spending energy, removing the card
# from the hand, resolving its effects via CardRules, and discarding it.
# Supports targeting for single-target attacks.
func play_card(idx: int, card: Dictionary, target_index: int) -> void:
	var dm: Node = get_node_or_null("/root/DeckManager")
	var gc: Node = get_node_or_null("/root/GameController")
	if dm == null:
		return
	
	# Cost defaults to 1 if unspecified
	var cost: int = int(card.get("cost", 1))
	
	# Check if we have enough energy
	var current_energy: int = 0
	if "energy" in dm:
		current_energy = int(dm.energy)
	
	if current_energy < cost:
		print("Not enough energy to play card. Need %d, have %d" % [cost, current_energy])
		return
	
	# Check if card needs a target and we have one
	var needs_target: bool = _card_needs_target(card)
	if needs_target and target_index < 0:
		# Try to get target from TargetingSystem or GameController
		var ts: Node = get_node_or_null("/root/TargetingSystem")
		if ts != null and ts.has_method("get_target"):
			var target_node = ts.call("get_target")
			if target_node != null:
				# Find the index of this target in our enemies list
				target_index = _find_enemy_index(target_node)
		elif gc != null and gc.has("selected_target_index"):
			target_index = int(gc.get("selected_target_index"))
		
		if target_index < 0:
			print("Card requires a target but none selected")
			return
	
	# Spend energy
	var ok: bool = false
	if dm.has_method("spend_energy"):
		ok = bool(dm.call("spend_energy", cost))
	else:
		# fallback: directly modify the energy property
		dm.set("energy", current_energy - cost)
		ok = true
	
	if not ok:
		return
	
	# Remove the card from the hand via DeckManager
	var played: Dictionary = card
	if dm.has_method("remove_from_hand"):
		var tmp_v: Variant = dm.call("remove_from_hand", idx)
		if tmp_v is Dictionary:
			played = tmp_v as Dictionary
	
	# Resolve the card via CardRules
	var cr: Node = get_node_or_null("/root/CardRules")
	if cr != null and cr.has_method("resolve"):
		cr.call("resolve", played, self, dm, target_index)
	else:
		# Fallback: apply simple damage/block if CardRules is missing
		_apply_card_fallback(played, target_index)
	
	# Discard the card after play
	if dm.has_method("discard_card"):
		dm.call("discard_card", played)
	
	# Clear target selection after use
	if gc != null:
		gc.set("selected_target_index", -1)

# Apply card effects without CardRules as a fallback.  Supports only
# damage and block fields and ignores targeting rules.
func _apply_card_fallback(card: Dictionary, target_index: int) -> void:
	var dmg: int = int(card.get("damage", 0))
	var blk: int = int(card.get("block", 0))
	if dmg > 0:
		if target_index >= 0 and target_index < enemies.size():
			_damage_enemy(target_index, dmg)
	if blk > 0:
		player_block += blk

# Deal damage to a single enemy.  Damage first reduces the enemy's block and
# any remainder reduces their HP.  Dead enemies will remain at 0 HP.
func _damage_enemy(ei: int, dmg: int) -> void:
	if ei < 0 or ei >= enemies.size():
		return
	var e: Dictionary = enemies[ei]
	var block_now: int = int(e.get("block", 0))
	var absorbed: int = min(dmg, block_now)
	e["block"] = max(0, block_now - absorbed)
	var leftover: int = dmg - absorbed
	if leftover > 0:
		e["hp"] = max(0, int(e.get("hp", 0)) - leftover)
	enemies[ei] = e

# Apply a status effect to a single enemy.  Statuses are stored in the
# enemy's "statuses" dictionary.  Amounts are added cumulatively.
func _apply_status_to_enemy(ei: int, status_name: String, amount: int) -> void:
	if ei < 0 or ei >= enemies.size():
		return
	var e: Dictionary = enemies[ei]
	if not e.has("statuses"):
		e["statuses"] = {}
	var st: Dictionary = e["statuses"] as Dictionary
	var cur: int = int(st.get(status_name, 0))
	st[status_name] = cur + amount
	e["statuses"] = st
	enemies[ei] = e

# Run the enemy turn.  Each enemy acts according to its intent.  Damage
# reduces player_block first; leftover damage reduces the player's HP via
# GameController.  After acting, the enemy chooses a new intent for the
# next turn using EnemyAI system.
func enemy_turn() -> void:
	var gc: Node = get_node_or_null("/root/GameController")
	var enemy_ai: Node = get_node_or_null("/root/EnemyAI")
	
	for i in range(enemies.size()):
		var e: Dictionary = enemies[i]
		
		# Skip dead enemies
		if int(e.get("hp", 0)) <= 0:
			continue
			
		# Execute the enemy's current intent
		var intent: Dictionary = {} if not (e.get("intent") is Dictionary) else e.get("intent") as Dictionary
		var t: String = String(intent.get("type", "attack"))
		var v: int = int(intent.get("value", 0))
		
		if t == "attack":
			var dmg: int = v
			var absorbed: int = min(player_block, dmg)
			player_block = max(0, player_block - absorbed)
			var leftover: int = dmg - absorbed
			if leftover > 0 and gc != null and "player_hp" in gc:
				var cur_hp: int = int(gc.player_hp)
				gc.player_hp = max(0, cur_hp - leftover)
		elif t == "defend":
			e["block"] = int(e.get("block", 0)) + v
		
		# Generate new intent for next turn using EnemyAI
		if enemy_ai != null and enemy_ai.has_method("compute_intent"):
			var new_intent: Dictionary = enemy_ai.call("compute_intent", e, turn + 1)
			e["intent"] = new_intent
		else:
			# Fallback: toggle the intent for the next turn
			var current_intent: Dictionary = {} if not (e.get("intent") is Dictionary) else e.get("intent") as Dictionary
			var current_type: String = String(current_intent.get("type", "attack"))
			if current_type == "attack":
				e["intent"] = {"type": "defend", "value": 5}
			else:
				e["intent"] = {"type": "attack", "value": 6}
		
		enemies[i] = e
	
	# Reset player block at the end of the enemy turn
	player_block = 0
	turn += 1

# Helper function to determine if a card needs a target
func _card_needs_target(card: Dictionary) -> bool:
	# Check if card has damage effects or single-target effects
	if card.has("damage") and int(card.get("damage", 0)) > 0:
		return true
	
	# Check effects array for targeting requirements
	if card.has("effects") and card["effects"] is Array:
		var effects: Array = card["effects"] as Array
		for effect in effects:
			if effect is Dictionary:
				var effect_dict: Dictionary = effect as Dictionary
				var effect_type: String = String(effect_dict.get("type", ""))
				if effect_type == "deal_damage" or effect_type == "apply_status":
					return true
	
	# Check legacy apply field for status effects
	if card.has("apply"):
		return true
	
	return false

# Add player block
func add_player_block(amount: int) -> void:
	player_block += max(0, amount)
	print("CombatSystem: Player gained %d block (total: %d)" % [amount, player_block])

# Damage player (respects block)
func damage_player(amount: int) -> void:
	var absorbed: int = min(player_block, amount)
	player_block = max(0, player_block - absorbed)
	var leftover: int = amount - absorbed
	
	if leftover > 0:
		var gc: Node = get_node_or_null("/root/GameController")
		if gc != null and gc.has("player_hp"):
			var current_hp: int = int(gc.get("player_hp"))
			gc.set("player_hp", max(0, current_hp - leftover))
			print("CombatSystem: Player took %d damage (%d absorbed by block)" % [leftover, absorbed])

# Remove enemy from combat
func remove_enemy(enemy_node: Node) -> void:
	# For now, just print - in full implementation would remove from enemies array
	print("CombatSystem: Enemy %s removed from combat" % enemy_node.name)

# Helper function to find enemy index by node reference
func _find_enemy_index(target_node: Node) -> int:
	# This is a simplified implementation - in a full game you'd have
	# proper enemy node tracking. For now, return -1 to indicate no match.
	# The UI should handle target selection by index directly.
	return -1
