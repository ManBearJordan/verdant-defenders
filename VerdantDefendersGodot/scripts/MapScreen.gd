extends Control

# MapScreen.gd - PATH-GRAPH MAP VISUALIZER (Act 1 Spec)
# Connected to RunController.

# CONSTANTS (Act 1)
const LAYERS = 9
const COLUMNS = 3
const MAP_WIDTH = 860
const MAP_HEIGHT = 520
const Y_START = 480 # Bottom (r0)
const Y_END = 60    # Top (r8)
const X_POSITIONS = [-260, 0, 260]
const JITTER_X = 40
const JITTER_Y = 12

const MapNodeScene = preload("res://Scenes/UI/Map/MapNode.tscn")

# Debug
var debug_mode = false

# State
var map_data: Dictionary = {}
var current_node_id: int = -1
var completed_nodes: Array = [] # From RunController
var node_instances: Dictionary = {}

# Autoloads
var rc = null # RunController

# UI
@onready var paths_layer: Control = %PathsLayer
@onready var nodes_layer: Control = %NodesLayer
@onready var camera: Camera2D = %Camera2D
@onready var confirm_panel: PanelContainer = $HUDLayer/ConfirmPanel
@onready var confirm_label: Label = $HUDLayer/ConfirmPanel/VBox/Label
@onready var confirm_btn: Button = $HUDLayer/ConfirmPanel/VBox/HBox/ConfirmBtn
@onready var cancel_btn: Button = $HUDLayer/ConfirmPanel/VBox/HBox/CancelBtn

# Internal
var _pending_node_id: int = -1
var _pending_node_type: String = ""

func _ready() -> void:
	rc = get_node_or_null("/root/RunController")
	
	if camera:
		camera.enabled = false 
	
	confirm_panel.visible = false
	confirm_btn.pressed.connect(_on_confirm_travel)
	cancel_btn.pressed.connect(_on_cancel_travel)
	
	call_deferred("_initialize_map")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_map_toggle") or (event is InputEventKey and event.pressed and event.keycode == KEY_F3):
		_toggle_debug()

func _toggle_debug() -> void:
	debug_mode = !debug_mode
	for node in node_instances.values():
		var lbl = node.get_node_or_null("DebugLabel")
		if lbl: lbl.visible = debug_mode

func _initialize_map() -> void:
	if rc:
		map_data = rc.map_data
		current_node_id = rc.current_node_id
		completed_nodes = rc.cleared_nodes
	else:
		# Fallback/Debug generation
		var gen = load("res://scripts/MapGenerator.gd").new()
		map_data = gen.generate_map(1)
		current_node_id = -1
	
	_draw_map()

func _draw_map() -> void:
	for child in nodes_layer.get_children(): child.queue_free()
	for child in paths_layer.get_children(): child.queue_free()
	node_instances.clear()
	
	var layers = map_data.get("layers", [])
	if layers.is_empty(): return
	
	var rng = RandomNumberGenerator.new()
	rng.seed = 1337 
	
	var vp_size = get_viewport_rect().size
	var center_x = vp_size.x / 2.0
	
	var positions = {}
	
	for l in range(layers.size()):
		var t = float(l) / 8.0
		var base_y = lerp(float(Y_START), float(Y_END), t)
		
		for node_data in layers[l]:
			var c = node_data["index"]
			var id = l * COLUMNS + c
			
			var base_x = center_x + X_POSITIONS[c]
			
			# Jitter
			var node_rng = RandomNumberGenerator.new()
			node_rng.seed = id * 100 + 55
			var jx = node_rng.randf_range(-JITTER_X, JITTER_X)
			var jy = node_rng.randf_range(-JITTER_Y, JITTER_Y)
			
			var pos = Vector2(base_x + jx, base_y + jy)
			positions[id] = pos
			
			var node = MapNodeScene.instantiate()
			node.setup(id, node_data["type"], l)
			node.position = pos
			node.node_selected.connect(_on_node_selected)
			nodes_layer.add_child(node)
			node_instances[id] = node
			
			# Debug Label
			var lbl = node.get_node_or_null("DebugLabel")
			if lbl:
				lbl.text = "r%d c%d\n%s" % [l, c, node_data["type"].substr(0,4)]
				lbl.visible = false
	
	# Draw Connections
	for l in range(layers.size()):
		for node_data in layers[l]:
			var from_id = l * COLUMNS + node_data["index"]
			var from_pos = positions.get(from_id)
			if not from_pos: continue
			
			for next_col in node_data.get("next", []):
				var to_id = (l + 1) * COLUMNS + next_col
				var to_pos = positions.get(to_id)
				if not to_pos: continue
				
				_draw_connection(from_pos, to_pos, from_id + to_id)

	_update_node_states()

func _draw_connection(p0: Vector2, p3: Vector2, seed_val: int) -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_val
	
	var p1 = p0 + Vector2(rng.randf_range(-60, 60), -rng.randf_range(40, 90))
	var p2 = p3 + Vector2(rng.randf_range(-60, 60), rng.randf_range(40, 90))
	
	var curve = Curve2D.new()
	curve.add_point(p0, Vector2.ZERO, p1 - p0)
	curve.add_point(p3, p2 - p3, Vector2.ZERO)
	
	var points = PackedVector2Array()
	var segments = 12
	var wobble_seed = rng.randf() * 100.0
	var wobble_amp = rng.randf_range(0, 10)
	
	for i in range(segments + 1):
		var t = float(i) / segments
		var u = 1 - t
		var tt = t * t
		var uu = u * u
		var uuu = uu * u
		var ttt = tt * t
		
		var p = (uuu * p0) + (3 * uu * t * p1) + (3 * u * tt * p2) + (ttt * p3)
		
		var wobble = sin(i * 0.7 + wobble_seed) * wobble_amp
		p.x += wobble
		points.append(p)
	
	var line = Line2D.new()
	line.width = 32
	line.texture = load("res://Art/map/decor/vine_path.png")
	line.texture_mode = Line2D.LINE_TEXTURE_TILE
	line.default_color = Color.WHITE
	line.points = points
	paths_layer.add_child(line)

func _update_node_states() -> void:
	# Recalculate based on current_node_id
	var layers = map_data.get("layers", [])
	var available_ids = []
	
	if current_node_id == -1:
		if not layers.is_empty():
			for n in layers[0]:
				available_ids.append(n["layer"] * COLUMNS + n["index"])
	else:
		for l in layers:
			for n in l:
				if (n["layer"] * COLUMNS + n["index"]) == current_node_id:
					for next_c in n.get("next", []):
						available_ids.append((n["layer"] + 1) * COLUMNS + next_c)
	
	for id in node_instances:
		var node = node_instances[id]
		var is_comp = id in completed_nodes
		var is_cur = (id == current_node_id)
		var is_avail = id in available_ids
		var is_lock = not is_avail and not is_comp and not is_cur
		node.set_state(is_lock, is_comp, is_cur)

func _on_node_selected(node_id: int) -> void:
	var layer = node_id / COLUMNS
	var col = node_id % COLUMNS
	var layers = map_data.get("layers", [])
	var type = "UNKNOWN"
	if layer < layers.size():
		for n in layers[layer]:
			if n["index"] == col:
				type = n["type"]
	
	_pending_node_id = node_id
	_pending_node_type = type
	confirm_label.text = "Travel to %s?" % type.capitalize()
	confirm_panel.visible = true

func _on_confirm_travel() -> void:
	confirm_panel.visible = false
	if _pending_node_id < 0: return
	
	if rc:
		rc.enter_node(_pending_node_id)
	
	_update_node_states()

func _on_cancel_travel() -> void:
	confirm_panel.visible = false
	_pending_node_id = -1
