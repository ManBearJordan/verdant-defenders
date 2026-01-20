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
	_reset_metrics()
	
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
const SCENE_GAMEOVER = "res://Scenes/UI/GameOver/GameOver.tscn"

# ...

func battle_defeat() -> void:
	print("RunController: Battle Defeat")
	emit_signal("battle_ended", false)
	# Todo: Show run summary / death screen
	_change_screen(SCENE_GAMEOVER)

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
			# Event-handling modes that return to map after completion
			if mode in ["remove", "sell", "sacrifice_sigil"]:
				if screen.has_signal("card_selected"):
					screen.card_selected.connect(_on_deck_card_selected_for_event.bind(mode))

func return_to_map_view() -> void:
	# Just go back to map, DO NOT Advance room
	goto_map()

func _on_deck_card_selected_for_event(card_id: String, mode: String) -> void:
	print("RunController: Event Card Selection: %s (Mode: %s)" % [card_id, mode])
	
	if mode == "remove":
		remove_card(card_id)
		return_to_map()
	elif mode == "sell":
		remove_card(card_id)
		modify_shards(50)
		return_to_map()
	elif mode == "sacrifice_sigil":
		remove_card(card_id)
		# Grant Sigil
		var rs = get_node_or_null("/root/RewardSystem")
		if rs:
			rs.add_sigil_fragment(3) # Force sigil
		return_to_map()

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

# --- METRICS ---
var run_metrics: Dictionary = {
	"rooms_cleared": 0,
	"elites_defeated": 0,
	"shards_earned": 0,
	"shards_spent": 0,
	"cards_added": 0,
	"cards_removed": 0,
	"damage_taken": 0
}

func _reset_metrics() -> void:
	run_metrics = {
		"rooms_cleared": 0,
		"elites_defeated": 0,
		"shards_earned": 0,
		"shards_spent": 0,
		"cards_added": 0,
		"cards_removed": 0,
		"damage_taken": 0
	}

# --- STATE MODIFIERS ---

func add_card(card_id: String) -> void:
	deck.append(card_id)
	run_metrics.cards_added += 1
	print("Added card: ", card_id)

func remove_card(card_id: String) -> void:
	deck.erase(card_id) # Removes first occurrence
	run_metrics.cards_removed += 1
	print("Removed card: ", card_id)

func upgrade_card(card_id: String) -> void:
	# ... (existing upgrade logic)
	# Metric update could go here too but maybe not strictly "added/removed"
	print("RunController: Upgrading card ", card_id)
	
	# ... (rest of upgrade logic)

func add_sigil(sigil_id: String) -> void:
	# ... (existing)
	if not sigil_id in sigils_owned:
		sigils_owned.append(sigil_id)
		print("Added sigil: ", sigil_id)

func modify_shards(amount: int) -> void:
	shards += amount
	if amount > 0:
		run_metrics.shards_earned += amount
	else:
		run_metrics.shards_spent += abs(amount)
		
	emit_signal("currency_changed", "shards", shards)

func modify_hp(amount: int) -> void:
	player_hp = clamp(player_hp + amount, 0, max_hp)
	if amount < 0:
		run_metrics.damage_taken += abs(amount)
		
	if player_hp <= 0:
		battle_defeat()

# ...

func battle_victory() -> void:
	print("RunController: Battle Victory")
	run_metrics.rooms_cleared += 1
	if current_room_type == "elite":
		run_metrics.elites_defeated += 1
		
	emit_signal("battle_ended", true)
	
	# Determine context for rewards based on stored type
	# ... (rest of function)
	var idx = deck.find(card_id)
	if idx == -1:
		push_error("RunController: Cannot upgrade, card not found in deck: " + card_id)
		return
		
	# 2. Get Data to find upgrade_id
	var dl = get_node_or_null("/root/DataLayer")
	if not dl:
		push_error("RunController: DataLayer missing during upgrade")
		return
		
	var card_res = dl.get_card(card_id)
	if not card_res:
		push_error("RunController: Card resource not found for: " + card_id)
		return
		
	if card_res.upgrade_id == "":
		print("RunController: Card has no upgrade defined: " + card_id)
		return
		
	# 3. Swap
	var new_id = card_res.upgrade_id
	deck[idx] = new_id
	print("RunController: Upgraded %s -> %s" % [card_id, new_id])
	
	# Optional: Notify UI or just let DeckView refresh

signal sigil_added(sigil_data: Dictionary)

func add_sigil(sigil_id: String) -> void:
	if not sigil_id in sigils_owned:
		sigils_owned.append(sigil_id)
		print("Added sigil: ", sigil_id)
		
		# Sync to SigilSystem (Logic)
		var ss = get_node_or_null("/root/SigilSystem")
		var dl = get_node_or_null("/root/DataLayer")
		if ss and dl:
			var sigil_data = dl.get_sigil(sigil_id)
			if sigil_data:
				ss.add_sigil(sigil_data)
				emit_signal("sigil_added", sigil_data)
			else:
				push_warning("RunController: Sigil data not found for " + sigil_id)
		
func modify_shards(amount: int) -> void:
	shards += amount
	emit_signal("currency_changed", "shards", shards)

func heal_full() -> void:
	modify_hp(max_hp) # clamp handles it

func start_combat_event(enemy_type: String) -> void:
	_start_battle(enemy_type)

func transform_random_card(target_rarity: String) -> void:
	if deck.is_empty(): return
	var idx = randi() % deck.size()
	var old_id = deck[idx]
	
	# Get random rare
	var dl = get_node_or_null("/root/DataLayer")
	if dl:
		var pool = dl.get_cards_by_criteria("any", target_rarity)
		if not pool.is_empty():
			var new_card = pool.pick_random()
			deck[idx] = new_card.id
			print("RunController: Transformed %s -> %s" % [old_id, new_card.id])

func upgrade_random_card() -> void:
	# Find upgradable cards
	var upgradable_indices = []
	var dl = get_node_or_null("/root/DataLayer")
	if not dl: return
	
	for i in range(deck.size()):
		var id = deck[i]
		var c = dl.get_card(id)
		if c and c.upgrade_id != "":
			upgradable_indices.append(i)
			
	if not upgradable_indices.is_empty():
		var idx = upgradable_indices.pick_random()
		upgrade_card(deck[idx])

func modify_hp(amount: int) -> void:
	player_hp = clamp(player_hp + amount, 0, max_hp)
	if player_hp <= 0:
		battle_defeat()

# --- HELPERS ---

func _get_starter_deck(class_id: String) -> Array:
	var dl = get_node_or_null("/root/DataLayer")
	if dl and dl.has_method("get_starting_deck"):
		var resources = dl.get_starting_deck(class_id)
		# Convert Resources to IDs
		var ids = []
		for res in resources:
			ids.append(res.id)
			
		if not ids.is_empty():
			return ids
			
	# Fallback if DataLayer fails or deck is empty
	print("RunController: Falling back to default deck for ", class_id)
	return ["strike", "strike", "defend", "defend"]

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
			"miniboss", "mini_boss": pack = rc._roll_miniboss_pack()
			"boss": pack = rc._roll_boss_pack()
			_: pack = rc._roll_basic_pack()
			
		print("RunController: Generated pack size: ", pack.size())
		rc._start_combat(pack)
	else:
		push_error("RunController: RoomController not found!")

	# Switch Scene
	_change_screen(SCENE_BATTLE)
