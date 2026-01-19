extends Node

var rng: RandomNumberGenerator
var max_hp: int = 80
var player_hp: int = 80:
	set(value):
		player_hp = value
		_check_player_death()
		player_hp_changed.emit(player_hp, max_hp)


func heal_player(amount: int) -> void:
	var final_amount = float(amount)
	var ac = get_node_or_null("/root/AscensionController")
	if ac:
		final_amount *= ac.get_healing_mult()
		
	player_hp = min(player_hp + int(final_amount), max_hp)
	_update_hud()

func start_run(class_id: String, ascension_level: int = 0, run_seed: int = 0) -> void:
	print("GameController: Starting Run (%s, A%d)" % [class_id, ascension_level])
	
	# 0. RNG
	rng = RandomNumberGenerator.new()
	if run_seed != 0: rng.seed = run_seed
	else: rng.randomize()
	
	current_class = class_id
	current_turn = 0
	verdant_shards = 0
	
	# 1. Reset Stats
	max_hp = 80
	player_hp = max_hp
	
	player_state = {
		"gold": 99,
		"seeds": 0,
		"statuses": {},
		"artifacts": []
	}
	
	# 2. Ascension
	var ac = get_node_or_null("/root/AscensionController")
	if ac:
		ac.set_ascension_level(ascension_level)
		if ascension_level >= 6:
			player_hp = int(max_hp * 0.9)
	
	_update_hud()
	
	# 3. Deck
	var dm = get_node_or_null("/root/DeckManager")
	if dm:
		if dm.has_method("set_rng"): dm.set_rng(rng)
		dm.reset_with_starting_deck(class_id)
		
	# 4. Dungeon (Triggers Map/Room)
	var dc = get_node_or_null("/root/DungeonController")
	if dc:
		dc.start_run()
		
	# Telemetry
	var ts = get_node_or_null("/root/TelemetrySystem")
	if ts and dm:
		ts.log_run_start(run_seed, class_id, ascension_level, dm.get_deck_list(), [], [])

func damage_player(amount: int) -> void:
	if amount <= 0: return
	
	# Handle block logic if GameController tracked it, but CombatSystem usually handles block mitigation
	# before calling this. If this is raw damage:
	player_hp = max(0, player_hp - amount)
	_check_player_death()
	_update_hud()


func _update_hud() -> void:
	var ui = _get_game_ui()
	if ui and ui.has_method("update_hud"): # update_hp?
		if ui.has_method("_update_player_stats"):
			ui._update_player_stats() # Legacy name?
		# Or just call generic update
		pass # Most UIs pull from process or signal

var energy_per_turn: int = 3
var verdant_shards: int = 0

# Combat state
var player_state: Dictionary = {
	"seeds": 0
}
var combat_state: Dictionary = {}
var current_class: String = "growth"

# Status Metadata (Parallel to player_state.statuses)
var status_metadata: Dictionary = {}

func add_status(name: String, amount: int) -> void:
	if not player_state.has("statuses"): player_state["statuses"] = {}
	var sh = get_node_or_null("/root/StatusHandler")
	if sh:
		sh.apply_status(player_state.statuses, status_metadata, name, amount)
		player_status_changed.emit()
		_update_hud() # Refresh UI (Legacy)
	else:
		# Fallback
		var cur = int(player_state.statuses.get(name, 0))
		player_state.statuses[name] = max(0, cur + amount)
		player_status_changed.emit()



# Turn state tracking
var current_turn: int = 0
var is_player_turn: bool = true

# Target tracking for single-target attacks (fallback if no TargetingSystem)
# Target tracking for single-target attacks (fallback if no TargetingSystem)
var selected_target_index: int = -1

# SafetyNet State
var turn_safety_metrics: Dictionary = {
	"cards_played": 0,
	"energy_gained": 0,
	"cards_drawn": 0
}
const MAX_CARDS_PLAYED_PER_TURN = 50
const MAX_ENERGY_GAIN_PER_TURN = 20
const MAX_DRAWS_PER_TURN = 50

@onready var data: Node = get_node_or_null("/root/DataLayer")

# Telemetry (Autoload override or local ref if needed, but we use global TelemetrySystem)
# var telemetry: Node = null # Deprecated

# UI nodes - registered by GameUI.gd
var _ui := { "enemies": null, "hand": null, "background": null }

# Signals for turn management
signal turn_started(turn_number: int)
signal turn_ended(turn_number: int)
signal player_turn_started()
signal enemy_turn_started()
signal ribbon_message(text: String)

# Value Signals
signal player_hp_changed(current: int, max: int)
signal player_stat_changed(stat: String, value: int)
signal player_status_changed()


func trigger_ribbon(text: String) -> void:
	ribbon_message.emit(text)


func register_ui_nodes(enemies_hbox: HBoxContainer, hand_hbox: HBoxContainer, bg: TextureRect) -> void:
	_ui.enemies = enemies_hbox
	_ui.hand = hand_hbox
	_ui.background = bg
	_apply_background()
	_rebuild_enemy_views()
	_rebuild_hand()

func _apply_background() -> void:
	if _ui.background == null: return
	var pths := [
		"res://Art/backgrounds/growth_combat.png",
		"res://Art/backgrounds/bg_forest.png",
		"res://Art/backgrounds/backgrounds/forest.png"
	]
	for p in pths:
		if ResourceLoader.exists(p):
			_ui.background.texture = load(p)
			break
	# Never block input to the rest of the UI
	if _ui.background is Control:
		_ui.background.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _rebuild_enemy_views() -> void:
	if _ui.enemies == null: return
	# Clear existing enemies
	for child in _ui.enemies.get_children():
		child.queue_free()
	
	# This will be called by GameUI's _spawn_enemies_in_ui method
	# We just ensure the container is ready

func _rebuild_hand() -> void:
	if _ui.hand == null: return
	# Hand rebuilding is handled by GameUI's _refresh_hand method
	# We just ensure the container is ready


func _ready() -> void:
	# pick up base energy from economy config if available
	if data != null:
		var eco: Dictionary = {}
		if data.has_method("get_economy_config"):
			eco = data.get_economy_config()
		elif data.has("economy_config"):
			eco = data.economy_config
		if "base_energy" in eco:
			energy_per_turn = int(eco["base_energy"])

	# Connect Telemetry
	var ts = get_node_or_null("/root/TelemetrySystem")
	if ts:
		# check if signals and methods exist before connecting
		if ts.has_method("on_turn_end") and not is_connected("turn_ended", ts.on_turn_end):
			turn_ended.connect(ts.on_turn_end)
		# CombatSystem signals? CombatSystem is autoload, so connect there?
		var cs = get_node_or_null("/root/CombatSystem")
		if cs and ts.has_method("on_damage_dealt"):
			if not cs.is_connected("damage_dealt", ts.on_damage_dealt):
				cs.damage_dealt.connect(ts.on_damage_dealt)

# Deprecated - redirect purely for legacy calls (if any remain)
func start_new_run(class_id: String, run_seed: int = 0) -> void:
	start_run(class_id, 0, run_seed)

func start_combat() -> void:
	"""Start combat with energy=max_energy, build starting deck, draw 5"""
	print("GameController: Starting combat...")
	
	# Reset combat state
	current_turn = 0
	is_player_turn = true
	combat_state = {
		"cards_played": [],
		"cards_played_this_turn": [],
		"cards_played_last_turn": [],
		"rituals_played": 0
	}
	
	# Telemetry: Combat Start
	var ts = get_node_or_null("/root/TelemetrySystem")
	var cs = get_node_or_null("/root/CombatSystem")
	var enemy_data = []
	if cs and "enemies" in cs:
		for e in cs.enemies:
			enemy_data.append({"id": e.id, "max_hp": e.max_hp})
			
	if ts:
		ts.log_combat_start(
			"fight_%d" % Time.get_unix_time_from_system(),
			"normal", # TODO: Pass actual type
			1, # Act
			current_turn, # Floor/Turn? Need floor tracking
			enemy_data,
			{"max_hp": max_hp, "hp": player_hp, "deck_size": 15} # TODO: Real deck size
		)
	
	# Set energy to max
	var deck_manager: Node = get_node_or_null("/root/DeckManager")
	if deck_manager != null:
		print("GameController: Found DeckManager")
		deck_manager.energy = deck_manager.max_energy
		deck_manager.energy_changed.emit(deck_manager.energy)
		
		# Build starting deck if not already built
		if deck_manager.draw_pile.is_empty() and deck_manager.hand.is_empty():
			print("GameController: Building starting deck...")
			var starter_deck = deck_manager._create_minimal_starting_deck()
			deck_manager.build_starting_deck(starter_deck)
			print("GameController: Built deck with %d cards" % deck_manager.draw_pile.size())
		
		# Draw 5 cards
		print("GameController: Drawing cards...")
		deck_manager.start_turn()
		print("GameController: Hand now has %d cards" % deck_manager.hand.size())
	else:
		print("GameController: ERROR - DeckManager not found!")
	
	# UI setup (background, enemies) is handled by GameUI.gd

	# Ribbon Log
	var ribbon = load("res://scripts/CombatLogRibbon.gd").new()
	add_child(ribbon)
	# It anchors itself Bottom-Left in _ready

	# Apply start of combat relic hooks
	var dc = get_node_or_null("/root/DungeonController")
	var relic_system = get_node_or_null("/root/RelicSystem")
	if relic_system and relic_system.has_method("apply_start_combat_hooks"):
		# Pass self or specific player node wrapper. RelicSystem expects player to have add_block/add_status
		# CombatSystem manages the player entity logic wrapper usually?
		# RelicSystem.gd: apply_start_combat_hooks(player)
		# We need a player object.
		# CombatSystem.gd has a player object? Or GameController represents the player stats?
		# Looking at CombatSystem.gd earlier: it manages `player` variable.
		# However, `GameController` has `player_hp`.
		# RelicSystem tries to call `player.add_block` and `player.add_status`.
		# These methods might belong to a MockPlayer or CombatSystem's player entity.
		# I should call this hook via CombatSystem or pass a compatible object.
		# For now, I will skip injecting here until I confirm where `add_block` lives.
		pass

func start_player_turn() -> void:
	"""Start a new player turn per TURN_LOOP.md: energy := max_energy, draw 5"""
	current_turn += 1
	is_player_turn = true
	
	# Emit turn signals
	turn_started.emit(current_turn)
	player_turn_started.emit()
	
	# Telemetry: Turn Start
	var ts = get_node_or_null("/root/TelemetrySystem")
	if ts:
		ts.log_turn_start(
			"fight_active", # Need to track fight_id on GC or TS
			current_turn,
			"player",
			{"hp": player_hp, "energy": 3}, # TODO: proper snapshot
			[]
		)
	
	# Reset SafetyNet
	turn_safety_metrics = {
		"cards_played": 0,
		"energy_gained": 0,
		"cards_drawn": 0
	}
	
	# Start turn via DeckManager (sets energy to max_energy and draws 5 cards)
	var deck_manager: Node = get_node_or_null("/root/DeckManager")
	if deck_manager != null and deck_manager.has_method("start_turn"):
		deck_manager.call("start_turn")
	
	# Process start of turn effects (after energy reset, so Chill can reduce energy)
	var combat_system: Node = get_node_or_null("/root/CombatSystem")
	if combat_system and combat_system.has_method("process_start_turn_effects"):
		combat_system.process_start_turn_effects()
	
	# Apply sigil hooks for start of turn
	_apply_start_turn_sigil_hooks()
	
	# Apply relic hooks for start of turn
	var rs = get_node_or_null("/root/RelicSystem")
	if rs and rs.has_method("apply_start_turn_hooks"):
		rs.apply_start_turn_hooks()
		
	# Chronoshard Compensation
	# "Gain +1 Energy if you played exactly 5 cards last turn"
	if combat_system and combat_system.has_method("is_enemy_present"):
		if combat_system.is_enemy_present("Chronoshard"):
			if combat_state.get("cards_played_last_turn", []).size() == 5:
				print("Chronoshard: Mastery Compensation (+1 Energy)")
				if deck_manager: deck_manager.gain_energy(1)

func _apply_start_turn_sigil_hooks() -> void:
	"""Apply sigil hooks at start of player turn"""
	var sigil_system: Node = get_node_or_null("/root/SigilSystem")
	if sigil_system == null:
		return
	
	# Apply start_turn_energy_bonus hook
	var energy_bonus = sigil_system.apply_hook("start_turn_energy_bonus", {})
	if energy_bonus != null and energy_bonus is int and energy_bonus > 0:
		var deck_manager: Node = get_node_or_null("/root/DeckManager")
		if deck_manager != null and deck_manager.has_method("gain_energy"):
			deck_manager.call("gain_energy", energy_bonus)

func play_card(idx: int, target_index: int = -1) -> bool:
	var deck_manager: Node = get_node_or_null("/root/DeckManager")
	if deck_manager == null:
		print("GameController: Missing DeckManager")
		return false
	
	# Get the card
	var hand = deck_manager.get_hand()
	if idx < 0 or idx >= hand.size():
		print("GameController: Invalid card index %d" % idx)
		return false
	
	var card: Dictionary = hand[idx]
	var cost: int = int(card.get("cost", 0))
	var discounted: int = _calculate_card_cost(card)

	if deck_manager.energy < discounted:
		print("Not enough energy (%d < %d)" % [deck_manager.energy, discounted])
		return false

	# SafetyNet Check
	if turn_safety_metrics.cards_played >= MAX_CARDS_PLAYED_PER_TURN:
		print("SafetyNet: Turn Play Cap Reached (%d)" % MAX_CARDS_PLAYED_PER_TURN)
		return false

	# Chronoshard Temporal Lock
	var cs = get_node_or_null("/root/CombatSystem")
	if cs and cs.has_method("is_enemy_present") and cs.is_enemy_present("Chronoshard"):
		if turn_safety_metrics.cards_played >= 5:
			print("Chronoshard: Temporal Lock! Cannot play >5 cards.")
			# UI Feedback? "LOCK Badge" logic handled by UI poller
			trigger_ribbon("Temporal Lock: limit reached (5)")
			return false

	var card_type = card.get("type", "").to_lower()
	var needs_target: bool = (card_type == "attack" or card_type == "strike") or card.get("requires_target", false)
	
	# If logic requires target but none provided, try global fallback (legacy)
	if needs_target and target_index == -1:
		print("GameController: Card requires target")
		var targeting_system: Node = get_node_or_null("/root/TargetingSystem")
		var target_node: Node = targeting_system.current_target if targeting_system else null
		if target_node:
			# We'd need to convert Node back to Index here, which is messy.
			# Rely on UI passing index correctly.
			pass
		
		# If still no target, fail
		if target_index == -1:
			print("Select a target first")
			return false

	# Spend energy
	if not deck_manager.spend_energy(discounted):
		print("GameController: Failed to spend energy")
		return false
	
	# Remove card from hand (but don't discard yet - hold it in limbo)
	var played_card = deck_manager.remove_from_hand(idx)
	if played_card.is_empty():
		print("GameController: Failed to play card")
		return false
		
	# Track History
	var cname = card.get("name", "Unknown")
	var ctype = card.get("type", "Skill")
	combat_state.cards_played.append(cname)
	
	if not combat_state.has("cards_played_this_turn"):
		combat_state["cards_played_this_turn"] = []
	combat_state.cards_played_this_turn.append({"name": cname, "type": ctype})
	
	# SafetyNet Increment
	turn_safety_metrics["cards_played"] += 1
	
	if ctype == "Ritual":
		combat_state.rituals_played += 1
		
	# Notify CombatSystem
	var _combat_sys_local = get_node_or_null("/root/CombatSystem")
	if _combat_sys_local and _combat_sys_local.has_method("on_player_card_played"):
		_combat_sys_local.on_player_card_played({"name": cname, "type": ctype, "cost": card.get("cost", 0)}, turn_safety_metrics["cards_played"])

	# Get effects from DataLayer first, fallback to embedded effects
	var card_name: String = card.get("name", "")
	var data_layer: Node = get_node_or_null("/root/DataLayer")
	var effects: Array = []
	if data_layer and data_layer.has_method("get_effects_for_card"):
		effects = data_layer.get_effects_for_card(card_name)
	if effects.is_empty():
		var embedded_effects = card.get("effects", [])
		if embedded_effects is Array:
			effects = embedded_effects as Array

	var card_rules: Node = get_node_or_null("/root/CardRules")
	if card_rules and card_rules.has_method("apply_effects"):
		# Context for CombatSystem hooks (e.g. Reactive Hide)
		var combat_sys = get_node_or_null("/root/CombatSystem")
		if combat_sys: combat_sys._current_card_context = card
		
		# Resolve target node ... (legacy comment snipped)
		
		var targeting_system: Node = get_node_or_null("/root/TargetingSystem")
		var target_node_ref: Node = targeting_system.current_target if targeting_system else null
		
		card_rules.apply_effects(target_node_ref, effects, {"source": self, "card": card, "target_index": target_index})
		
		if combat_sys: combat_sys._current_card_context = null

	# Discard the card AFTER effects resolve to prevent immediate reshuffle-draw loops
	if deck_manager.has_method("discard_card"):
		deck_manager.discard_card(played_card)
		
	# Notify RelicSystem
	var rs = get_node_or_null("/root/RelicSystem")
	if rs and rs.has_method("on_card_played"):
		rs.on_card_played(card)
		
	# Notify CombatSystem (Elite Hooks / Boss Mechanics)
	var cs_notify = get_node_or_null("/root/CombatSystem") # Re-fetch or reuse
	if cs_notify and cs_notify.has_method("on_player_card_played"):
		var count = combat_state.get("cards_played_this_turn", []).size()
		cs_notify.on_player_card_played(card, count)
		
	# Telemetry: Card Play
	var ts_node = get_node_or_null("/root/TelemetrySystem")
	if ts_node:
		var target_str = "none"
		if target_index >= 0: target_str = "enemy:%d" % target_index # Abstract ID
		
		# TODO: We need real delta from CardRules. Currently we don't return it.
		# For now, we log what we know.
		ts_node.log_card_play(
			"fight_active",
			current_turn,
			card.get("id", "unknown"),
			card.get("upgraded", false), # Assuming logic_meta has this
			discounted,
			target_str,
			{"base_damage": card.get("damage", 0), "base_block": card.get("block", 0)} # Delta stub
		)

	_update_energy_ui()
	return true

func _remove_card_from_hand(card: Dictionary) -> void:
	var deck_manager: Node = get_node_or_null("/root/DeckManager")
	if deck_manager and deck_manager.has_method("remove_from_hand"):
		deck_manager.remove_from_hand(card)

func _update_energy_ui() -> void:
	var game_ui = _get_game_ui()
	if game_ui and game_ui.has_method("_refresh_header"):
		game_ui._refresh_header()

func _calculate_card_cost(card: Dictionary) -> int:
	var base = int(card.get("cost", 0))
	var final = _apply_card_cost_discount(base, card)
	
	# Chronoshard Echo Tax
	var cs = get_node_or_null("/root/CombatSystem")
	if cs and cs.has_method("is_enemy_present") and cs.is_enemy_present("Chronoshard"):
		# Count previous plays of this card ID
		var id = card.get("id", "unknown")
		var count = 0
		if combat_state.has("cards_played_this_turn"):
			for c in combat_state.cards_played_this_turn:
				# Check name or ID? "cards_played_this_turn" stores {name, type} in play_card...
				# stored as: {"name": cname, "type": ctype}
				# Actually we should store ID for accuracy.
				# Assuming name == id for now or fetching logic.
				if c.get("name") == card.get("name"): # Approximation
					count += 1
					
		if count >= 2: # This will be 3rd play
			final += 1
			final = max(final, 1) # Minimum 1
			
	return final

func _apply_card_cost_discount(base_cost: int, card: Dictionary) -> int:
	"""Apply sigil card cost discount"""
	var sigil_system: Node = get_node_or_null("/root/SigilSystem")
	if sigil_system == null:
		return base_cost
	
	var discount = sigil_system.apply_hook("card_cost_discount", {"card": card})
	if discount != null and discount is int and discount > 0:
		return max(0, base_cost - discount)
	
	return base_cost

func end_turn() -> void:
	"""End turn: discard hand, run enemy intents (attack/defend), then start next turn"""
	if not is_player_turn:
		print("Not player turn")
		return
		
	# Relic Hook
	var rs = get_node_or_null("/root/RelicSystem")
	if rs and rs.has_method("on_turn_end"):
		rs.on_turn_end()
		
	is_player_turn = false
	turn_ended.emit(current_turn)
	
	# Get deck_manager early for telemetry use
	var deck_manager: Node = get_node_or_null("/root/DeckManager")
	
	# Telemetry: Turn End
	var ts_te = get_node_or_null("/root/TelemetrySystem")
	# Need player snapshot (block, hand size end, etc)
	# Hand Size is tricky as discard happens *after* this log usually if we want "end state" or "before discard"
	# The spec says "turn_end" log. Discard happens next lines.
	if ts_te:
		ts_te.log("turn_end", {
			"fight_id": "fight_active",
			"turn": current_turn,
			"side": "player",
			"energy_end": deck_manager.energy if deck_manager else 0,
			"cards_played": combat_state.get("cards_played_this_turn", []).size()
		})
	
	# Discard hand
	if deck_manager != null and deck_manager.has_method("end_turn_discard"):
		deck_manager.call("end_turn_discard")
	
	# Run enemy intents
	_run_enemy_phase()
	
	# Start next player turn
	call_deferred("start_player_turn")

func discard_hand_only() -> void:
	"""Discard hand without starting next turn - for testing"""
	var deck_manager: Node = get_node_or_null("/root/DeckManager")
	if deck_manager != null and deck_manager.has_method("end_turn_discard"):
		deck_manager.call("end_turn_discard")

func _run_enemy_phase() -> void:
	"""Run enemy phase - each enemy executes its intent"""
	var combat_system: Node = get_node_or_null("/root/CombatSystem")
	if combat_system == null:
		print("GameController: No CombatSystem found")
		return
	
	# Use CombatSystem's enemy_turn method which handles dictionary enemies properly
	if combat_system.has_method("enemy_turn"):
		combat_system.call("enemy_turn")

func end_player_turn() -> void:
	"""End the player turn per TURN_LOOP.md: discard hand, enemy phase, next player turn"""
	# Track History
	combat_state.cards_played_last_turn = combat_state.get("cards_played_this_turn", []).duplicate()
	combat_state.cards_played_this_turn = []
	
	end_turn()

func start_enemy_turn() -> void:
	"""Execute enemy phase (stub) and then start next player turn"""
	enemy_turn_started.emit()
	
	# Enemy phase stub - just execute basic enemy turn
	var combat_system: Node = get_node_or_null("/root/CombatSystem")
	if combat_system != null and combat_system.has_method("enemy_turn"):
		combat_system.call("enemy_turn")
	
	# After enemy turn, start next player turn
	call_deferred("start_player_turn")

func add_seeds(amount: int) -> void:
	player_state.seeds += amount
	# Rule 8: Seed Cap
	player_state.seeds = min(player_state.seeds, 100)
	update_seeds_ui()
	
	if amount > 0:
		var cs = get_node_or_null("/root/CombatSystem")
		if cs and cs.has_method("on_player_seeds_gained"):
			cs.on_player_seeds_gained(amount)

func update_seeds_ui() -> void:
	"""Update the seeds UI display"""
	var game_ui = _get_game_ui()
	if game_ui and game_ui.has_method("set_seeds"):
		game_ui.set_seeds(player_state.seeds)

func get_rng() -> RandomNumberGenerator:
	return rng

func get_current_turn() -> int:
	return current_turn

func is_current_player_turn() -> bool:
	return is_player_turn

func _get_game_ui() -> Control:
	var ui: Control = get_tree().get_first_node_in_group("game_ui") as Control
	if ui: return ui
	return get_tree().root.find_child("GameUI", true, false) as Control

func set_combat_background(pool: String = "growth") -> void:
	var ui := _get_game_ui()
	if not ui: return
	var bg := ui.get_node_or_null("Background")
	if not bg: return
	var map := {
		"growth": "res://Art/backgrounds/growth_combat.png",
		"decay": "res://Art/backgrounds/decay_combat.png",
		"elemental": "res://Art/backgrounds/elemental_combat.png",
		"growth_boss": "res://Art/backgrounds/growth_boss_combat.png",
		"decay_boss": "res://Art/backgrounds/decay_boss_combat.png",
		"elemental_boss": "res://Art/backgrounds/elemental_boss_combat.png"
	}
	var path: String = map.get(pool, map["growth"])
	if ResourceLoader.exists(path):
		(bg as TextureRect).texture = load(path)

func on_enemy_killed(index: int) -> void:
	print("GameController: Enemy Killed at index %d" % index)
	
	# 1. Remove from UI
	var game_ui = _get_game_ui()
	if game_ui and game_ui.enemies_box:
		if index < game_ui.enemies_box.get_child_count():
			var node = game_ui.enemies_box.get_child(index)
			node.queue_free()
			# remove_child is better if we want safe deferred deletion, 
			# but queue_free works if we iterate safely.
	
	# 2. Remove from CombatSystem
	var cs = get_node_or_null("/root/CombatSystem")
	if cs and "enemies" in cs:
		if index < cs.enemies.size():
			cs.enemies.remove_at(index)
	
	# 3. Check Victory
	# Since we just removed one, check if empty
	if cs and cs.enemies.size() == 0:
		print("GameController: VICTORY!")
		# Call victory sequence
		call_deferred("_handle_victory")

	# Telemetry: Combat End Win
	var ts = get_node_or_null("/root/TelemetrySystem")
	if ts:
		ts.log_combat_end("fight_active", 1, 1, "win", {"turns": current_turn})

func _handle_victory() -> void:
	print("GameController: Handling Victory...")
	
	# Check if this was a Final Boss / Victory Condition
	var is_final_victory = false
	var is_boss = false
	var dc = get_node_or_null("/root/DungeonController")
	if dc:
		if dc.has_method("is_boss_room"): is_boss = dc.is_boss_room()
		if dc.has_method("is_final_act"): is_final_victory = is_boss and dc.is_final_act()
	
	if is_final_victory:
		print("GameController: FINAL VICTORY!")
		
		# Meta Progress
		var mp = get_node_or_null("/root/MetaPersistence")
		if mp: mp.add_xp(100)
		
		var ts = get_node_or_null("/root/TelemetrySystem")
		if ts: ts.finalize_run("victory")
		
		delete_save() # Run complete
		var ui = _get_game_ui()
		if ui and ui.has_method("show_victory"):
			ui.show_victory()
		else:
			print("GameController: No Victory UI found!")
			
	elif is_boss:
		# Act Complete, NOT final
		print("GameController: ACT COMPLETE!")
		save_run()
		
		if dc and dc.has_method("advance_to_next_act"):
			dc.advance_to_next_act()
			
	else:
		# Regular combat win
		save_run()
		
		# Create generic victory UI or signal RoomController
		var rc = get_node_or_null("/root/RoomController")
		if rc and rc.has_method("_on_combat_finished"):
			rc._on_combat_finished(true, false) # TODO: Pass correct is_mini_boss flag
	
	# Relic Hook
	var rs = get_node_or_null("/root/RelicSystem")
	if rs and rs.has_method("on_combat_victory"):
		rs.on_combat_victory()

func _check_player_death() -> void:
	if player_hp <= 0:
		print("GameController: PLAYER DIED")
		
		# Meta Progress - consolation XP
		var mp = get_node_or_null("/root/MetaPersistence")
		if mp: mp.add_xp(20)
		
		var ts = get_node_or_null("/root/TelemetrySystem")
		if ts: 
			ts.log_combat_end("fight_active", 1, 1, "loss", {"turns": current_turn})
			ts.log_run_end(1, 1, "loss", 0, 0, 0, 0, 0, {"cause": "death"})
		
		delete_save() # Permadeath
		# Show Game Over screen
		var ui = _get_game_ui()
		if ui and ui.has_method("show_game_over"):
			ui.show_game_over()
		else:
			# Fallback restart
			print("Game Over... Restarting run.")
			start_new_run(current_class)

func save_run() -> void:
	var rp = get_node_or_null("/root/RunPersistence")
	if rp:
		rp.save_run()

func load_run() -> bool:
	var rp = get_node_or_null("/root/RunPersistence")
	if rp:
		return rp.load_run()
	return false

func delete_save() -> void:
	var rp = get_node_or_null("/root/RunPersistence")
	if rp:
		rp.delete_save()
