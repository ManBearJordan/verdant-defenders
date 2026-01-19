extends Node

signal room_entered(room_card: Dictionary)
signal floor_cleared
signal choices_ready(choices: Array) # (Legacy? MapScreen handles selection now)
signal map_updated(map_data: Dictionary, current_layer: int, current_index: int)

@onready var data = get_node("/root/DataLayer")

# Map Logic
var map_generator_script = preload("res://scripts/MapGenerator.gd")
var _map_generator: Node = null
var current_map: Dictionary = {}
var current_layer: int = 0
var current_node_index: int = -1 # -1 = Start

func is_boss_room() -> bool:
	if current_map.is_empty(): return false
	var layers = current_map.get("layers", [])
	if current_layer >= layers.size(): return false
	# Check explicit type or if last layer
	if current_layer == layers.size() - 1: return true
	# Or check current node data
	var node = layers[current_layer][current_node_index]
	return node.get("type") == "boss"


# Act Logic
var current_act: int = 1
const MAX_ACTS: int = 3
const ACT_POOL_MAP = {
	1: "growth",
	2: "decay",
	3: "elemental"
}

func _ready() -> void:
	_map_generator = map_generator_script.new()
	add_child(_map_generator)

func start_run() -> void:
	current_act = 1
	_start_act()

func _start_act() -> void:
	current_layer = 0
	current_node_index = -1
	_generate_new_map()
	show_map()

func _generate_new_map() -> void:
	if _map_generator:
		current_map = _map_generator.generate_map(current_act)
		print("DungeonController: Generated map with %d layers" % current_map.get("layers", []).size())
	else:
		print("DungeonController: MapGenerator not found")

func show_map() -> void:
	emit_signal("map_updated", current_map, current_layer, current_node_index)

func next_room() -> void:
	# Called when room is finished (combat win, event done)
	# For now, just show map again so player can pick next node
	print("DungeonController: Room finished, showing map")
	show_map()

func choose_node(layer_idx: int, node_idx: int) -> void:
	# Validate move
	if layer_idx != current_layer and layer_idx != 0: # 0 is allowed from start
		if layer_idx != current_layer + 1:
			print("Invalid move: Layer skip")
			return
	
	# Check connectivity if not layer 0
	if current_node_index != -1:
		var layers = current_map.get("layers", [])
		if current_layer < layers.size():
			var curr_node = layers[current_layer][current_node_index]
			if not node_idx in curr_node.get("next", []):
				print("Invalid move: Not connected")
				return
	
	# Update state
	var layers = current_map.get("layers", [])
	if layer_idx >= layers.size(): return
	
	var node_data = layers[layer_idx][node_idx]
	current_layer = layer_idx
	current_node_index = node_idx
	
	_enter_room(node_data)

func _enter_room(room: Dictionary) -> void:
	print("DungeonController: Entering room ", room)
	
	# Auto-Save
	var gc = get_node_or_null("/root/GameController")
	if gc and gc.has_method("save_run"):
		gc.save_run()
	
	var type = room.get("type", "fight")
	
	if type == "fight" or type == "elite":
		var rc = get_node_or_null("/root/RoomController")
		if rc:
			# Disconnect any old signal to avoid double calls? 
			# RoomController usually calls 'end_combat' on GC or RS
			# We need to know when combat ends.
			# 'RoomController' signals 'combat_finished'? 
			# Actually RoomController calls RewardSystem, which then... ?
			# We rely on 'next_room' being called by whatever finishes the room.
			# In 'ShopUI', it calls 'next_room'. 
			# In 'RoomController', 'victory' -> 'RewardSystem' -> 'GameUI'??
			# We need to ensure flow returns to DungeonController.next_room()
			
			# HACK: For now, we assume RewardSystem or UI will call next_room() via 'Proceed' button.
			
			var is_elite = (type == "elite")
			var pack = rc._roll_elite_pack() if is_elite else rc._roll_basic_pack()
			rc._start_combat(pack)
	
	elif type == "shop":
		# GameUI handles opening shop when it sees room type, or we explicitly signal
		# We'll emit 'room_entered' and let GameUI manage the view switching.
		pass
			
	elif type == "boss":
		var rc = get_node_or_null("/root/RoomController")
		if rc:
			var pack = rc._roll_boss_pack()
			rc._start_combat(pack)
	
	elif type == "event":
		var ec = get_node_or_null("/root/EventController")
		if ec:
			if not ec.is_connected("event_completed", next_room):
				ec.event_completed.connect(next_room)
			ec.start_random_event()
	
	elif type == "rest":
		# Grove logic
		var gu = get_node_or_null("/root/GameUI") # Assuming GroveUI is integrated there?
		# Actually GameUI handles Grove logic if we signal 'room_entered' with type 'rest'.
		# GameUI._on_room_entered calls _open_grove_ui().
		pass

	elif type == "treasure":
		# Treat as a special event
		var ec = get_node_or_null("/root/EventController")
		if ec:
			if not ec.is_connected("event_completed", next_room):
				ec.event_completed.connect(next_room)
			# Find or create a generic treasure event
			ec.start_event("treasure_chest")
            
	emit_signal("room_entered", room)

func is_final_act() -> bool:
	return current_act >= MAX_ACTS

func advance_to_next_act() -> void:
	if current_act < MAX_ACTS:
		current_act += 1
		print("DungeonController: Advancing to Act %d (%s)" % [current_act, get_current_pool()])
		
		# Heal player slightly?
		var gc = get_node_or_null("/root/GameController")
		if gc and gc.has_method("heal_player"):
			gc.heal_player(int(gc.max_hp * 0.3)) # 30% heal
			
		_start_act()
	else:
		print("DungeonController: Already at final act.")

func get_current_pool() -> String:
	return ACT_POOL_MAP.get(current_act, "growth")