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
var current_room_type: String = "normal" # Context for rewards

# Deck State
var deck: Array = []        # Array of CardDefinition IDs (String)
var draw_pile: Array = []   # Runtime only
var discard_pile: Array = [] # Runtime only
var exhaust_pile: Array = [] # Runtime only

# Sigils
var sigils_owned: Array = [] # Array of Sigil IDs

# Navigation
const SCENE_MAIN_MENU = "res://Scenes/UI/MainMenu.tscn"
const SCENE_MAP = "res://Scenes/UI/Map/MapScene.tscn"
const SCENE_BATTLE = "res://Scenes/UI/Combat/CombatScreen.tscn"
const SCENE_REWARD = "res://Scenes/UI/Combat/RewardScreen.tscn"
const SCENE_SHOP = "res://Scenes/UI/Shop/ShopScreen.tscn"
const SCENE_EVENT = "res://Scenes/UI/Event/EventScreen.tscn"
const SCENE_DECK = "res://Scenes/UI/Deck/DeckViewScreen.tscn"

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
	current_room_type = "normal"
	
	emit_signal("run_started", class_id)
	
	# Start Map System
	var mc = get_node_or_null("/root/MapController")
	if mc:
		mc.start_run()
		goto_map()
	else:
		push_error("RunController: MapController not found!")

func battle_victory() -> void:
	print("RunController: Battle Victory")
	emit_signal("battle_ended", true)
	
	# Determine context for rewards based on stored type
	var reward_context = "normal"
	var type_lower = current_room_type.to_lower()
	if type_lower in ["elite", "miniboss", "mini_boss", "boss"]:
		reward_context = type_lower
		if reward_context == "mini_boss": reward_context = "miniboss"
		
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
	current_room_type = "shop" # Context
	_change_screen(SCENE_SHOP)

func goto_event() -> void:
	print("Navigating to EVENT")
	current_room_type = "event"
	_change_screen(SCENE_EVENT)

func goto_reward(context: String = "normal") -> void:
	print("Navigating to REWARD (Context: ", context, ")")
	_change_screen(SCENE_REWARD)
	
	var root = get_tree().current_scene
	var screen_layer = root.find_child("ScreenLayer")
	if screen_layer and screen_layer.get_child_count() > 0:
		var screen = screen_layer.get_child(0)
		if screen.has_method("setup"):
			screen.setup(context)

func goto_deck_view(mode: String = "view", return_context: String = "map") -> void:
	print("Navigating to DECK VIEW (Mode: ", mode, ")")
	_change_screen(SCENE_DECK)
	
	# Pass params to screen
	var root = get_tree().current_scene
	var screen = root.find_child("ScreenLayer").get_child(0)
	if screen and screen.has_method("setup"):
		screen.setup(mode)
		
		# Connect signals for flow
		if return_context == "shop":
			if screen.has_signal("card_selected"):
				screen.card_selected.connect(_on_deck_card_selected_for_shop)
			if screen.has_signal("cancelled"):
				screen.cancelled.connect(goto_shop)
		elif return_context == "map":
			if screen.has_signal("cancelled"):
				screen.cancelled.connect(return_to_map_view)

func return_to_map_view() -> void:
	# Just go back to map, DO NOT Advance room
	goto_map()

func _on_deck_card_selected_for_shop(card_id: String) -> void:
	print("RunController: Card selected for removal: ", card_id)
	
	var shop = get_node_or_null("/root/ShopSystem")
	if shop:
		if shop.remove_card_by_id(card_id):
			print("RunController: Card removed successfully")
			goto_shop()
		else:
			print("RunController: Failed to remove card")
			goto_shop() # Return anyway

func return_to_map() -> void:
	# Called after clearing a room (Reward continue, Shop leave, Event done)
	var mc = get_node_or_null("/root/MapController")
	if mc:
		mc.next_room()
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
		# print("RunController: Changing root scene to ", scene_path)
		# NOTE: Root scene change destroys Autoloads if not handled carefully? 
		# No, Autoloads persist. But Main.tscn is the host.
		# If we change root, we lose ScreenLayer structure.
		# We should ensure we only change root if essential. 
		# If not in Main structure, maybe warn?
		get_tree().change_scene_to_file(scene_path)

# --- STATE MODIFIERS ---

func add_card(card_id: String) -> void:
	deck.append(card_id)
	print("Added card: ", card_id)

func remove_card(card_id: String) -> void:
	deck.erase(card_id) # Removes first occurrence
	print("Removed card: ", card_id)

func upgrade_card(card_id: String) -> void:
	# Placeholder for upgrade logic
	print("RunController: Placeholder Upgrade for ", card_id)
	# Logic would be: find index, replace ID with upgraded ID (if we have ID naming convention like "card_plus")
	# For now, just print.

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

func _start_battle(type: String) -> void:
	print("Navigating to BATTLE (Type: ", type, ")")
	current_room_type = type # Store context
	
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
