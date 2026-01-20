extends Node

# DungeonController.gd
# SCENE ORCHESTRATOR
# Replaces old linear logic with MapController signals.

signal scene_changed(scene_name: String)

# Scene Paths
const SCENE_MAP = "res://Scenes/UI/Map/MapScene.tscn"
const SCENE_COMBAT = "res://Scenes/UI/Combat/CombatScreen.tscn"
const SCENE_SHOP = "res://Scenes/UI/Shop/ShopScreen.tscn"
const SCENE_EVENT = "res://Scenes/UI/Event/EventScreen.tscn"
const SCENE_TREASURE = "res://Scenes/UI/Event/EventScreen.tscn" # Same for now, treasure ev
const SCENE_BOSS = "res://Scenes/UI/Combat/CombatScreen.tscn" # Same combat scene

@onready var map_controller = get_node("/root/MapController")
@onready var run_controller = get_node("/root/RunController")

func _ready() -> void:
	# Connect to MapController
	if map_controller:
		map_controller.room_selected.connect(_on_room_selected)
		map_controller.boss_reached.connect(_on_boss_reached)
		map_controller.run_completed.connect(_on_run_completed)
		
	# Connect to completion signals from systems (Combat, Event, Shop)
	# These need to be bridged back to MapController.next_room()
	call_deferred("_connect_systems")

func _connect_systems() -> void:
	var rc = get_node_or_null("/root/RunController")
	if rc:
		if not rc.is_connected("battle_ended", _on_battle_ended):
			rc.battle_ended.connect(_on_battle_ended)
			
	var ec = get_node_or_null("/root/EventController")
	if ec:
		ec.event_completed.connect(_on_event_completed)
		
	# Shop usually manual exit? Logic needs generic "return to map" hook.
	# RunController has `return_to_map`?

func start_run() -> void:
	# Called by Main Menu
	print("DungeonController: Orchestrating Start Run")
	if map_controller:
		map_controller.start_run()
		_load_scene(SCENE_MAP)

func _on_room_selected(card: RoomCard) -> void:
	print("DungeonController: Selected ", card.type)
	
	match card.type:
		"COMBAT", "ELITE":
			_setup_combat(card.type.to_lower())
			_load_scene(SCENE_COMBAT)
		"SHOP":
			_load_scene(SCENE_SHOP)
		"EVENT":
			_setup_event()
			_load_scene(SCENE_EVENT)
		"TREASURE":
			_setup_treasure()
			# SCENE loading handled by RunController in setup
		_:
			push_error("Unknown card type: " + card.type)
			_return_to_map()

func _on_boss_reached() -> void:
	print("DungeonController: BOSS REACHED")
	_setup_combat("boss")
	_load_scene(SCENE_BOSS)

func _on_run_completed() -> void:
	print("RUN COMPLETED!")
	# Back to main menu or victory screen
	# For now loop?
	get_tree().quit() # or Menu

func _setup_combat(type: String) -> void:
	var rc = get_node_or_null("/root/RoomController")
	if rc:
		var pack = []
		if type == "elite": pack = rc._roll_elite_pack()
		elif type == "boss": pack = rc._roll_boss_pack()
		else: pack = rc._roll_basic_pack()
		
		# We set it up, but CombatScreen calls get_enemies() from CombatSystem
		# We must ensure CombatSystem is primed.
		rc._start_combat(pack)

func _setup_event() -> void:
	var ec = get_node_or_null("/root/EventController")
	if ec: ec.start_random_event()
	
func _setup_treasure() -> void:
	if run_controller:
		# Route treasure to standard Reward Screen with "treasure" context
		# Note: We load SCENE_REWARD via goto_reward in next step usually?
		# Here we are in _setup_treasure called by _on_room_selected.
		# _on_room_selected calls _load_scene(SCENE_TREASURE).
		# We should change SCENE_TREASURE to SCENE_REWARD logic or just rely on RC.
		run_controller.goto_reward("treasure")
		# We don't need _load_scene calls in _on_room_selected if RC handles it?
		# But _on_room_selected currently does:
		# _setup_treasure() -> _load_scene(SCENE_TREASURE)
		# If RC.goto_reward does change screen, we double load?
		# Yes. I should edit _on_room_selected to use RC where possible.

# --- Completion Handlers ---

func _on_battle_ended(victory: bool) -> void:
	if victory:
		# Should go to Reward Screen first!
		# Using RunController's logic for that?
		# RC.battle_victory() -> goto_reward().
		# RewardScreen -> Continue -> Return To Map.
		pass
	else:
		# Game Over
		pass

func _on_event_completed() -> void:
	_return_to_map()

func _return_to_map() -> void:
	print("Returning to Map & Advancing")
	if run_controller and run_controller.has_method("return_to_map"):
		run_controller.return_to_map()
	else:
		# Fallback
		_load_scene(SCENE_MAP)
		if map_controller:
			map_controller.next_room()

# --- Scene Loading ---

func _load_scene(path: String) -> void:
	# Use RunController's _change_screen logic or implement here?
	# RunController has robust ScreenLayer logic. Let's use it if available.
	if run_controller and run_controller.has_method("_change_screen"):
		run_controller._change_screen(path)
	else:
		get_tree().change_scene_to_file(path)
