extends ScrollContainer

# MapScreen - Visualizes the Map

signal node_selected(layer: int, index: int, type: String)

var map_data: Dictionary = {}
var current_layer: int = 0
var current_index: int = -1 # -1 means start of run

var _container: Control # The inner control holding nodes/lines
const X_SPACING = 100
const Y_SPACING = 100
const NODE_SIZE = 40

func _ready() -> void:
	name = "MapScreen"
	_container = Control.new()
	_container.name = "MapContainer"
	add_child(_container)
	# Set min size large enough
	_container.custom_minimum_size = Vector2(800, 2000)

func setup(map: Dictionary, curr_layer: int, curr_idx: int) -> void:
	map_data = map
	current_layer = curr_layer
	current_index = curr_idx
	
	_draw_map()

func _draw_map() -> void:
	# Clear existing
	for c in _container.get_children():
		c.queue_free()
	
	# Create a helper for lines
	var lines_layer = Control.new()
	lines_layer.name = "Lines"
	_container.add_child(lines_layer)
	# Add a custom draw script or use Line2D
	# Using Line2D is easier for positioning
	
	var layers: Array = map_data.get("layers", [])
	if layers.is_empty(): return
	
	var valid_next_indices = []
	if current_index != -1 and current_layer < layers.size():
		# Get valid next moves
		# But wait, we store 'next' in the node.
		# Find current node
		var prev_l = layers[current_layer]
		if current_index < prev_l.size():
			valid_next_indices = prev_l[current_index]["next"]
	elif current_index == -1:
		# Start of run: all layer 0 nodes are valid
		for i in range(layers[0].size()):
			valid_next_indices.append(i)
	
	# Render Nodes
	var layer_count = layers.size()
	var screen_width = get_viewport_rect().size.x if is_inside_tree() else 1280.0
	var center_x = screen_width / 2.0
	
	# Pre-calculate positions
	var node_positions = {} # Key: "layer_index", Val: Vector2
	
	for l_idx in range(layer_count):
		var layer_nodes = layers[l_idx]
		var count = layer_nodes.size()
		var y = (layer_count - 1 - l_idx) * Y_SPACING + 100 # Invert Y so layer 0 is bottom? Or top?
		# Usually Layer 0 is bottom (Start). Boss is Top.
		# Let's do Layer 0 at Bottom (High Y).
		
		# Total width of this layer
		var total_w = (count - 1) * X_SPACING
		var start_x = center_x - (total_w / 2.0)
		
		for n in layer_nodes:
			var idx = n["index"]
			var x = start_x + (idx * X_SPACING)
			var pos = Vector2(x, y)
			node_positions["%d_%d" % [l_idx, idx]] = pos
			
			# Create Button
			var btn = Button.new()
			btn.text = _get_icon(n["type"])
			btn.tooltip_text = "Floor %d: %s" % [l_idx + 1, n["type"].capitalize()]
			btn.position = pos - Vector2(NODE_SIZE/2, NODE_SIZE/2)
			btn.custom_minimum_size = Vector2(NODE_SIZE, NODE_SIZE)
			
			# Button State
			var reachable = false
			if l_idx == current_layer:
				if idx == current_index:
					btn.modulate = Color.GREEN # Current
				else:
					btn.modulate = Color.GRAY # Same layer, inactive
					btn.disabled = true
			elif l_idx > current_layer:
				# Prospective
				if l_idx == current_layer + 1:
					if idx in valid_next_indices:
						btn.modulate = Color(1, 1, 1) # Reachable
						reachable = true
						# Pulse animation?
					else:
						btn.modulate = Color(1, 1, 1, 0.5) # Unreachable next
						btn.disabled = true
				else:
					btn.modulate = Color(1, 1, 1, 0.3) # Future
					btn.disabled = true
			else:
				# Past
				btn.modulate = Color(0.5, 0.5, 0.5, 0.5)
				btn.disabled = true
			
			if reachable:
				btn.pressed.connect(_on_node_pressed.bind(l_idx, idx, n["type"]))
			
			_container.add_child(btn)
			
			# Draw Lines to Parents
			# Actually draw lines to Next
			for next_idx in n["next"]:
				var next_key = "%d_%d" % [l_idx + 1, next_idx]
				# We can only draw if we computed next layer positions... 
				# But we iterate ordered. Next layer positions not computed yet.
				# Better to compute all positions first.
				pass

	# Draw connections (Pass 2)
	for l_idx in range(layer_count - 1):
		var layer_nodes = layers[l_idx]
		for n in layer_nodes:
			var start_pos = node_positions["%d_%d" % [l_idx, n["index"]]]
			for next_idx in n["next"]:
				var end_pos = node_positions.get("%d_%d" % [l_idx + 1, next_idx])
				if end_pos:
					var line = Line2D.new()
					line.width = 2
					line.default_color = Color(1, 1, 1, 0.3)
					line.points = [start_pos, end_pos]
					lines_layer.add_child(line)

func _get_icon(type: String) -> String:
	match type:
		"fight": return "⚔"
		"elite": return "💀"
		"boss": return "👹"
		"shop": return "💰"
		"rest": return "🔥"
		"event": return "?"
	return "O"

func _on_node_pressed(l: int, i: int, t: String) -> void:
	node_selected.emit(l, i, t)
