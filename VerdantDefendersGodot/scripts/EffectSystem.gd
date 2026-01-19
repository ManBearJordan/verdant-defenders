extends Node

signal card_resolved(card_id: String)

# Helpers you may inject from GameController at startup if useful
var _gc: Node = null

func _ready() -> void:
	# Get reference to GameController
	# Get reference to GameController
	_gc = get_node_or_null("/root/GameController")

func _get_gc(ctx: Dictionary) -> Node:
	if ctx.has("player"): return ctx["player"]
	if ctx.has("game_controller"): return ctx["game_controller"]
	return _gc

func _val(v: Variant, card: Dictionary) -> int:
	if typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT:
		return int(v)
	if typeof(v) == TYPE_DICTIONARY:
		if v.has("value"):
			return int(v["value"])
		if v.has("stat"):
			var stats: Dictionary = card.get("stats", {})
			return int(stats.get(String(v["stat"]), v.get("default", 0)))
	return int(v)

func can_play(card: Dictionary, state: Dictionary) -> bool:
	var cost := int(card.get("cost", 0))
	var discount := int(state.get("cost_discount", 0))
	return int(state.get("energy", 0)) >= max(0, cost - discount)

func needs_target(card: Dictionary) -> bool:
	if card.get("requires_target", false): 
		return true
	
	# Check if card type requires target
	var card_type: String = card.get("type", "")
	if card_type in ["Strike", "attack"]:
		return true
	
	# Check effects for targeting requirements
	for e in card.get("effects", []):
		if e.get("type","") in ["deal_damage","apply_status"] and e.get("target","enemy") != "self":
			return true
	return false

func resolve_card(card: Dictionary, target: Node, ctx: Dictionary) -> void:
	var effects: Array = card.get("effects", [])
	
	# If no effects array, create effects from legacy card data
	if effects.is_empty():
		effects = _convert_legacy_card_to_effects(card)
	
	# Add card to context for amount resolution
	var enhanced_ctx: Dictionary = ctx.duplicate()
	enhanced_ctx["card"] = card
	
	for e in effects:
		_resolve_effect(e, target, enhanced_ctx)
	
	emit_signal("card_resolved", String(card.get("id","")))
	emit_signal("card_resolved", String(card.get("id","")))
	var gc = _get_gc(ctx)
	if gc and gc.has_method("update_hud"):
		gc.update_hud()

func _convert_legacy_card_to_effects(card: Dictionary) -> Array:
	"""Convert legacy card data to effects format"""
	var effects: Array = []
	
	# Handle damage
	var damage: int = int(card.get("damage", 0))
	if damage > 0:
		effects.append({"type": "deal_damage", "amount": damage, "target": "enemy"})
	
	# Handle block
	var block: int = int(card.get("block", 0))
	if block > 0:
		effects.append({"type": "gain_block", "amount": block, "target": "self"})
	
	# Handle special effects based on card name/type
	var card_name: String = card.get("name", "").to_lower()
	if "heal" in card_name:
		effects.append({"type": "heal", "amount": 2, "target": "self"})
	elif "draw" in card_name or card_name == "sprout heal":
		effects.append({"type": "draw_cards", "count": 1})
	elif "seed" in card_name:
		effects.append({"type": "plant_seed", "count": 1})
	
	return effects

func _resolve_effect(e: Dictionary, target: Node, ctx: Dictionary) -> void:
	# Get the card from context for amount resolution
	var card: Dictionary = ctx.get("card", {})
	
	match String(e.get("type","")).strip_edges():
		"deal_damage":
			var amt := _val(e.get("amount",0), card)
			var who: String = e.get("target","enemy")
			if who == "all_enemies":
				var enemies_container: Node = ctx.get("enemies")
				if enemies_container:
					for en in enemies_container.get_children():
						_damage(en, amt, ctx)
			elif who == "self":
				_damage(ctx.get("player"), amt, ctx)
			else:
				if target: 
					_damage(target, amt, ctx)
		"aoe_damage":
			var enemies_container: Node = ctx.get("enemies")
			if enemies_container:
				for en in enemies_container.get_children():
					_damage(en, _val(e.get("amount",0), card), ctx)
		"gain_block":
			_add_block(_pick_target(e.get("target","self"), target, ctx), _val(e.get("amount",0), card), ctx)
		"draw_cards":
			var gc = _get_gc(ctx)
			if gc and gc.has_method("draw_cards"):
				gc.draw_cards(int(e.get("count",1)))
			else:
				var dm := get_node_or_null("/root/DeckManager")
				if dm and dm.has_method("draw_cards"):
					dm.draw_cards(int(e.get("count",1)))
		"heal":
			_heal(_pick_target(e.get("target","self"), target, ctx), _val(e.get("amount",0), card), ctx)
		"apply_status":
			_apply_status(_pick_target(e.get("target","enemy"), target, ctx), e.get("status",""), _val(e.get("amount",1), card), ctx)
		"plant_seed":
			var count: int = int(e.get("count", e.get("amount", 1)))
			var gc = _get_gc(ctx)
			if gc and gc.has_method("add_seeds"):
				gc.add_seeds(count)
		"consume_seeds":
			var count: int = int(e.get("count", 0))
			var up_to: int = int(e.get("up_to", 0))
			var actual_consumed: int = 0
			var gc = _get_gc(ctx)
			
			if gc and gc.get("player_state") != null:
				var current_seeds: int = int(gc.player_state.get("seeds", 0))
				if up_to > 0:
					actual_consumed = min(current_seeds, up_to)
				else:
					actual_consumed = min(current_seeds, count)
				gc.player_state.seeds = max(0, current_seeds - actual_consumed)
				if gc.has_method("update_seeds_ui"):
					gc.update_seeds_ui()
				
				# Relic Hook: Thorny Bark (spend_seed_damage)
				if actual_consumed > 0:
					var rs = get_node_or_null("/root/RelicSystem")
					if rs and rs.has_method("on_seed_spent"):
						rs.on_seed_spent(actual_consumed)
			
			# Store consumed amount in context for other effects to use
			ctx["consumed_seeds"] = actual_consumed
		"consume_status":
			var status_name: String = e.get("status", "")
			var up_to: int = int(e.get("up_to", 1))
			var per_stack_effects: Array = e.get("per_stack", [])
			var target_node: Node = _pick_target(e.get("target", "enemy"), target, ctx)
			
			if target_node and status_name != "":
				var current_stacks: int = _get_status(target_node, status_name)
				var consumed_stacks: int = min(current_stacks, up_to)
				
				# Remove the consumed stacks
				if consumed_stacks > 0:
					_apply_status(target_node, status_name, -consumed_stacks, ctx)
					
					# Execute per_stack effects for each consumed stack
					for i in range(consumed_stacks):
						for sub_effect in per_stack_effects:
							_resolve_effect(sub_effect, target, ctx)
		"energy_gain":
			var dm := get_node_or_null("/root/DeckManager")
			if dm and dm.has_method("gain_energy"):
				dm.gain_energy(int(e.get("amount",0)))
		"repeat":
			for i in range(int(e.get("times",1))):
				for sub in e.get("effects", []):
					_resolve_effect(sub, target, ctx)
		"if":
			if _eval_cond(e.get("condition", {}), target, ctx):
				for sub in e.get("then", []): 
					_resolve_effect(sub, target, ctx)
			else:
				for sub in e.get("else", []): 
					_resolve_effect(sub, target, ctx)
		_: 
			print("EffectSystem: Unknown effect type: '%s' (raw: %s)" % [e.get("type",""), e])

func _eval_cond(c: Dictionary, target: Node, ctx: Dictionary) -> bool:
	var left := str(c.get("left",""))
	var op := str(c.get("op",">="))
	var right := int(c.get("right",0))
	var val := 0
	
	if left == "player.seeds": 
		var gc = _get_gc(ctx)
		if gc and gc.get("player_state") != null:
			val = int(gc.player_state.get("seeds", 0))
	elif left == "target.status.seeded": 
		val = int(_get_status(target, "seeded"))
	elif left.begins_with("player.status."):
		var status_name = left.substr("player.status.".length())
		var player: Node = ctx.get("player")
		val = int(_get_status(player, status_name))
	
	match op:
		">=": return val >= right
		">":  return val > right
		"==": return val == right
		"<=": return val <= right
		"<":  return val < right
		_: return false

func _pick_target(tag: String, target: Node, ctx: Dictionary) -> Node:
	if tag == "self": return ctx.get("player")
	if tag == "enemy": return target
	return ctx.get("player")

func _damage(node: Node, amt: int, _ctx: Dictionary) -> void:
	if node == null: return
	
	var actual_damage: int = 0
	if node.has_method("take_damage"):
		# Use the node's own take_damage method if available
		node.take_damage(amt)
		actual_damage = amt  # Simplified for now
	else:
		# Fallback: manual damage calculation
		var block: int = int(node.get("block")) if "block" in node else 0
		var pierce: int = max(0, amt - block)
		if "block" in node:
			node.set("block", max(0, block - amt))
		if "hp" in node:
			var current_hp: int = int(node.get("hp"))
			node.set("hp", max(0, current_hp - pierce))
		actual_damage = pierce
	
	var gc = _get_gc(_ctx) # Context might not be fully populated in all paths, but we try
	if gc and gc.has_method("show_damage_popup"):
		gc.show_damage_popup(node, actual_damage, amt - actual_damage)
	
	# Check for death
	if node.has("hp"):
		var current_hp: int = int(node.hp) if node.has("hp") else 0
		if current_hp == 0 and gc and gc.has_method("on_enemy_killed"):
			gc.on_enemy_killed(node)

func _add_block(node: Node, amt: int, _ctx: Dictionary) -> void:
	if node == null: return
	
	if node.has_method("add_block"):
		node.add_block(amt)
	elif "block" in node:
		var current_block: int = int(node.get("block"))
		node.set("block", current_block + amt)
	
	if _gc and _gc.has_method("show_block_popup"):
		_gc.show_block_popup(node, amt)

func _heal(node: Node, amt: int, _ctx: Dictionary) -> void:
	if node == null: return
	
	if node.has_method("heal"):
		node.heal(amt)
	elif "hp" in node and "max_hp" in node:
		var current_hp: int = int(node.get("hp"))
		var max_hp: int = int(node.get("max_hp"))
		node.set("hp", min(max_hp, current_hp + amt))
	
	var gc = _get_gc(_ctx)
	if gc and gc.has_method("show_heal_popup"):
		gc.show_heal_popup(node, amt)

func _apply_status(node: Node, status_name: String, amt: int, _ctx: Dictionary) -> void:
	if node == null or status_name == "": return
	
	if node.has_method("apply_status"):
		node.apply_status(status_name, amt)
	else:
		# Fallback: manual status application
		if not node.has("statuses"):
			node.statuses = {}
		var statuses: Dictionary = node.statuses if node.has("statuses") else {}
		if statuses is Dictionary:
			var current_amount: int = int(statuses.get(status_name, 0))
			statuses[status_name] = current_amount + amt
			node.statuses = statuses

func _get_status(node: Node, status_name: String) -> int:
	if node == null: return 0
	
	if node.has_method("get_status"):
		return int(node.get_status(status_name))
	elif node.has("statuses"):
		var statuses: Dictionary = node.statuses if node.has("statuses") else {}
		if statuses is Dictionary:
			return int(statuses.get(status_name, 0))
	
	return 0
