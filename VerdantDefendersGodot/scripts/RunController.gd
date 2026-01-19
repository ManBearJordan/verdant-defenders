extends Node

# RunController.gd - CENTRAL RUN STATE & NAVIGATION MANAGER
#
# RESPONSIBILITIES:
# 1. Manage Run State (HP, Deck, Shards, Currencies, Map Progression)
# 2. Manage Scene Navigation (Map -> Battle -> Reward -> Shop -> Event)
# 3. Persist Run Data (Save/Load - future proofing)
# 4. Enforce Game Rules (Reward logic, Elite logic, Boss logic)

signal run_started(class_id: String)
signal node_entered(node_id: int, node_type: String)
signal battle_ended(victory: bool)
signal currency_changed(type: String, amount: int)

# --- RUN STATE ---
var current_class_id: String = "growth"
var current_act: int = 1
var current_floor: int = 0
var player_hp: int = 80
var max_hp: int = 80
var shards: int = 0

# Deck State
var deck: Array = []        # Array of CardDefinition IDs (String)
var draw_pile: Array = []   # Runtime only
var discard_pile: Array = [] # Runtime only
var exhaust_pile: Array = [] # Runtime only

# Sigils
var sigils_owned: Array = [] # Array of Sigil IDs

# Map State
var map_data: Dictionary = {}
var current_node_id: int = -1
var cleared_nodes: Array = []

# Navigation
# Navigation
const SCENE_MAIN_MENU = "res://Scenes/UI/MainMenu.tscn"
const SCENE_MAP = "res://Scenes/UI/Map/MapScene.tscn"
const SCENE_BATTLE = "res://Scenes/UI/Combat/CombatScreen.tscn"
const SCENE_REWARD = "res://Scenes/UI/Combat/RewardScreen.tscn"
const SCENE_SHOP = "res://Scenes/UI/Shop/ShopScreen.tscn"
const SCENE_EVENT = "res://Scenes/UI/Event/EventScreen.tscn"
# const SCENE_START_MENU = "res://Scenes/UI/StartMenu.tscn" # If distinct

# --- PUBLIC API ---

func _ready() -> void:
	print("RunController: Initialized")

func start_new_run(class_id: String) -> void:
	print("RunController: Starting new run with class ", class_id)
	current_class_id = class_id
	current_act = 1
	current_floor = 0
	player_hp = 80 # TODO: Class specific
	max_hp = 80
	shards = 0
	deck = _get_starter_deck(class_id)
	sigils_owned = []
	cleared_nodes = []
	current_node_id = -1
	
	# Generate Map
	var MapGen = load("res://scripts/MapGenerator.gd").new()
	map_data = MapGen.generate_map(current_act)
	
	emit_signal("run_started", class_id)
	goto_map()

func enter_node(node_id: int) -> void:
	print("RunController: Entering node ", node_id)
	current_node_id = node_id
	
	# Determine node type from map data
	var node_type = _get_node_type(node_id)
	emit_signal("node_entered", node_id, node_type)
	
	call_deferred("_resolve_node_entry", node_type)

func _resolve_node_entry(node_type: String) -> void:
	match node_type:
		"FIGHT", "SKIRMISH":
			_start_battle("normal")
		"ELITE", "MINIBOSS", "MINIBOSS_GATE", "MINIBOSS_OPT":
			_start_battle("elite")
		"BOSS":
			_start_battle("boss")
		"SHOP":
			goto_shop()
		"EVENT", "SANCTUARY", "CACHE":
			goto_event() # For now, todo distinct
		"START":
			# Just unlocks connected nodes
			_node_cleared()
			goto_map()
		_:
			push_error("Unknown node type: " + node_type)
			goto_map()

func battle_victory() -> void:
	print("RunController: Battle Victory")
	emit_signal("battle_ended", true)
	_node_cleared()
	
	# Determine context for rewards
	var node_type = _get_node_type(current_node_id)
	var reward_context = "normal"
	if node_type in ["ELITE", "MINIBOSS", "MINIBOSS_GATE", "MINIBOSS_OPT"]:
		reward_context = "elite"
	elif node_type == "BOSS":
		reward_context = "boss"
		
	goto_reward(reward_context)

func battle_defeat() -> void:
	print("RunController: Battle Defeat")
	emit_signal("battle_ended", false)
	# Todo: Show run summary / death screen
	get_tree().change_scene_to_file(SCENE_MAIN_MENU)

func goto_map() -> void:
	print("Navigating to MAP")
	_change_screen(SCENE_MAP)

func goto_shop() -> void:
	print("Navigating to SHOP")
	_change_screen(SCENE_SHOP)

func goto_event() -> void:
	print("Navigating to EVENT")
	_change_screen(SCENE_EVENT)

func goto_reward(context: String = "normal") -> void:
	print("Navigating to REWARD (Context: ", context, ")")
	_change_screen(SCENE_REWARD)

func return_to_map() -> void:
	goto_map()

func _change_screen(scene_path: String) -> void:
	var root = get_tree().current_scene
	var screen_layer = root.find_child("ScreenLayer") if root else null
	
	if screen_layer:
		print("RunController: Switching screen in ScreenLayer")
		# Remove existing children
		for child in screen_layer.get_children():
			child.queue_free()
		
		# Instantiate new screen
		var scene = load(scene_path)
		var instance = scene.instantiate()
		screen_layer.add_child(instance)
	else:
		print("RunController: Changing root scene to ", scene_path)
		get_tree().change_scene_to_file(scene_path)

# --- STATE MODIFIERS ---

func add_card(card_id: String) -> void:
	deck.append(card_id)
	print("Added card: ", card_id)

func remove_card(card_id: String) -> void:
	deck.erase(card_id) # Removes first occurrence
	print("Removed card: ", card_id)

func add_sigil(sigil_id: String) -> void:
	if not sigil_id in sigils_owned:
		sigils_owned.append(sigil_id)
		print("Added sigil: ", sigil_id)

func modify_shards(amount: int) -> void:
	shards += amount
	emit_signal("currency_changed", "shards", shards)

func modify_hp(amount: int) -> void:
	player_hp = clamp(player_hp + amount, 0, max_hp)
	if player_hp <= 0:
		battle_defeat()

# --- HELPERS ---

func _get_starter_deck(class_id: String) -> Array:
	# Temporary hardcoded starter decks
	if class_id == "growth":
		return ["vine_whip", "vine_whip", "vine_whip", "spore_shield", "spore_shield", "photosynthesis", "wild_growth"]
	return ["strike", "strike", "defend", "defend"] # Default

func _get_node_type(node_id: int) -> String:
	# Look up in map_data
	var layer_idx = node_id / 3 # Assuming 3 columns, careful with this if layout changes
	# Better to search map_data structure
	var layers = map_data.get("layers", [])
	for l in layers:
		for node in l:
			var id = node["layer"] * 3 + node["index"] # Assuming Generator uses fixed indices 0,1,2
			if id == node_id:
				return node["type"]
	return "UNKNOWN"

func _start_battle(type: String) -> void:
	print("Navigating to BATTLE (Type: ", type, ")")
	
	# Setup Encounter via RoomController
	var rc = get_node_or_null("/root/RoomController")
	if rc:
		var pack = []
		match type:
			"normal": pack = rc._roll_basic_pack()
			"elite": pack = rc._roll_elite_pack()
			"boss": pack = rc._roll_boss_pack()
			_: pack = rc._roll_basic_pack()
			
		print("RunController: Generated pack size: ", pack.size())
		rc._start_combat(pack)
	else:
		push_error("RunController: RoomController not found!")

	# Switch Scene
	_change_screen(SCENE_BATTLE)

func _node_cleared() -> void:
	if not current_node_id in cleared_nodes:
		cleared_nodes.append(current_node_id)
