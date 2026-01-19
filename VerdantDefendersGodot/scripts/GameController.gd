extends Node

var rng: RandomNumberGenerator
var max_hp: int = 80
var player_hp: int = 80
var energy_per_turn: int = 3
var verdant_shards: int = 0

# Turn state tracking
var current_turn: int = 0
var is_player_turn: bool = true

# Target tracking for single-target attacks (fallback if no TargetingSystem)
var selected_target_index: int = -1

@onready var data: Node = get_node_or_null("/root/DataLayer")

# Signals for turn management
signal turn_started(turn_number: int)
signal turn_ended(turn_number: int)
signal player_turn_started()
signal enemy_turn_started()

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

func start_new_run(class_id: String, seed: int = 0) -> void:
	# Initialize the RNG for this run.  Use a deterministic seed if provided
	# (non‑zero), otherwise randomize.  The RNG is stored so that other
	# systems (e.g. shops, rewards) can access the same generator.
	rng = RandomNumberGenerator.new()
	if seed != 0:
		rng.seed = seed
	else:
		rng.randomize()

	# Reset player stats for the new run
	player_hp = max_hp
	verdant_shards = 0
	current_turn = 0
	is_player_turn = true

	# Configure the deck manager: assign RNG, reset deck, and start the first turn
	var deck_manager: Node = get_node_or_null("/root/DeckManager")
	if deck_manager != null:
		# Set the RNG on the DeckManager if it exposes the method
		if deck_manager.has_method("set_rng"):
			deck_manager.call("set_rng", rng)
		# Reset the deck using the selected class
		if deck_manager.has_method("reset_with_starting_deck"):
			deck_manager.call("reset_with_starting_deck", class_id)
		# Begin the first turn
		start_player_turn()

func start_combat() -> void:
	"""Start combat with energy=max_energy, build starting deck, draw 5, set background"""
	# Reset combat state
	current_turn = 0
	is_player_turn = true
	
	# Set energy to max
	var deck_manager: Node = get_node_or_null("/root/DeckManager")
	if deck_manager != null:
		deck_manager.energy = deck_manager.max_energy
		deck_manager.energy_changed.emit(deck_manager.energy)
		
		# Build starting deck if not already built
		if deck_manager.draw_pile.is_empty() and deck_manager.hand.is_empty():
			var starter_deck = deck_manager._create_minimal_starting_deck()
			deck_manager.build_starting_deck(starter_deck)
		
		# Draw 5 cards
		deck_manager.start_turn()
	
	# Set background via ArtRegistry
	var art_registry: Node = get_node_or_null("/root/ArtRegistry")
	if art_registry != null:
		var background_texture = art_registry.get_texture("growth_combat")
		if background_texture != null:
			# Find GameUI and set background
			var game_ui = get_tree().get_first_node_in_group("game_ui")
			if game_ui == null:
				# Try to find it by scene
				game_ui = get_tree().current_scene.find_child("GameUI", true, false)
			if game_ui != null:
				var background = game_ui.find_child("Background", true, false)
				if background != null and background is TextureRect:
					(background as TextureRect).texture = background_texture
					print("GameController: Set background texture")

func start_player_turn() -> void:
	"""Start a new player turn per TURN_LOOP.md: energy := max_energy, draw 5"""
	current_turn += 1
	is_player_turn = true
	
	# Emit turn signals
	turn_started.emit(current_turn)
	player_turn_started.emit()
	
	# Start turn via DeckManager (sets energy to max_energy and draws 5 cards)
	var deck_manager: Node = get_node_or_null("/root/DeckManager")
	if deck_manager != null and deck_manager.has_method("start_turn"):
		deck_manager.call("start_turn")
	
	# Apply sigil hooks for start of turn
	_apply_start_turn_sigil_hooks()

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

func play_card(idx: int) -> void:
	"""Play card at index - require TargetingSystem.current_target for attacks; spend energy; call CardRules.apply_effects"""
	var deck_manager: Node = get_node_or_null("/root/DeckManager")
	var card_rules: Node = get_node_or_null("/root/CardRules")
	var targeting_system: Node = get_node_or_null("/root/TargetingSystem")
	
	if deck_manager == null or card_rules == null:
		print("GameController: Missing DeckManager or CardRules")
		return
	
	# Get the card
	var hand = deck_manager.get_hand()
	if idx < 0 or idx >= hand.size():
		print("GameController: Invalid card index %d" % idx)
		return
	
	var card: Dictionary = hand[idx]
	var base_cost: int = int(card.get("cost", 0))
	
	# Apply sigil cost discount
	var final_cost = _apply_card_cost_discount(base_cost, card)
	
	# Check if we have enough energy
	if deck_manager.energy < final_cost:
		print("GameController: Not enough energy (%d < %d)" % [deck_manager.energy, final_cost])
		return
	
	# Check if card requires a target per task requirements
	var needs_target: bool = card.get("type","") == "attack" or card.get("requires_target", false)
	var target: Node = targeting_system.current_target if targeting_system else null
	
	if needs_target and target == null:
		print("GameController: Card requires a target but none selected")
		return
	
	# Spend energy (use final cost after discount)
	if not deck_manager.spend_energy(final_cost):
		print("GameController: Failed to spend energy")
		return
	
	# Remove card from hand
	var played_card = deck_manager.play_card(idx)
	if played_card.is_empty():
		print("GameController: Failed to play card")
		return
	
	# Apply card effects using the new apply_effects method
	var effects: Array = []
	if played_card.has("effects") and played_card["effects"] is Array:
		effects = played_card["effects"]
	
	var ctx: Dictionary = {"source": self}
	card_rules.apply_effects(target, effects, ctx)
	
	print("GameController: Played card %s (cost %d)" % [played_card.get("name", "Unknown"), final_cost])

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
		return  # Already in enemy turn
		
	is_player_turn = false
	turn_ended.emit(current_turn)
	
	# Discard hand
	var deck_manager: Node = get_node_or_null("/root/DeckManager")
	if deck_manager != null and deck_manager.has_method("end_turn_discard"):
		deck_manager.call("end_turn_discard")
	
	# Run enemy intents
	_run_enemy_phase()
	
	# Start next player turn
	call_deferred("start_player_turn")

func _run_enemy_phase() -> void:
	"""Run enemy phase - each enemy executes its intent"""
	var combat_system: Node = get_node_or_null("/root/CombatSystem")
	if combat_system == null:
		print("GameController: No CombatSystem found")
		return
	
	# Get enemies from combat system
	var enemies: Array = []
	if combat_system.has("enemies"):
		enemies = combat_system.get("enemies")
	
	# Execute each enemy's intent
	for enemy in enemies:
		if enemy != null and is_instance_valid(enemy) and enemy.has_method("execute_intent"):
			enemy.call("execute_intent")

func end_player_turn() -> void:
	"""End the player turn per TURN_LOOP.md: discard hand, enemy phase, next player turn"""
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
	verdant_shards += amount

func get_rng() -> RandomNumberGenerator:
	return rng

func get_current_turn() -> int:
	return current_turn

func is_current_player_turn() -> bool:
	return is_player_turn
