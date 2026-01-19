extends Node

# MapGenerator - Generates procedural dungeon maps (Slay the Spire style)

const LAYERS = 15
const MIN_WIDTH = 3
const MAX_WIDTH = 5

# Node types
const TYPE_FIGHT = "fight"
const TYPE_ELITE = "elite"
const TYPE_BOSS = "boss"
const TYPE_REST = "rest" # Grove
const TYPE_SHOP = "shop"
const TYPE_EVENT = "event"
const TYPE_TREASURE = "treasure"

# Elite Spawn Frequency Configuration (TASK 6)
const ELITE_TARGET_PCT = {
	1: 0.10,  # Act 1: 10%
	2: 0.15,  # Act 2: 15%
	3: 0.22   # Act 3: 22%
}
const ACT1_PROTECTED_COMBATS = 2  # No elites in first 2 combat nodes of Act 1
const ELITE_COOLDOWN = 1           # No adjacent elites (1 non-elite between)

# Weights by layer range. 
# Key is slice of layers [start, end_inclusive], Value is dictionary of types/weights
const WEIGHTS = {
	"start": {TYPE_FIGHT: 100},
	"early": {TYPE_FIGHT: 50, TYPE_EVENT: 40, TYPE_SHOP: 10},
	"mid":   {TYPE_FIGHT: 40, TYPE_EVENT: 30, TYPE_ELITE: 20, TYPE_SHOP: 5, TYPE_TREASURE: 5},
	"late":  {TYPE_FIGHT: 30, TYPE_EVENT: 20, TYPE_ELITE: 30, TYPE_SHOP: 10, TYPE_REST: 5, TYPE_TREASURE: 5},
	"end":   {TYPE_REST: 100},
	"boss":  {TYPE_BOSS: 100}
}


func generate_map(act: int = 1) -> Dictionary:
	# Returns a dictionary with "nodes" (flat list or layered) and "paths"
	
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	var map: Array = []
	
	# Generate Grid of Nodes
	for layer_idx in range(LAYERS):
		var layer_nodes: Array = []
		var width = rng.randi_range(MIN_WIDTH, MAX_WIDTH)
		
		# Override width for specific layers
		if layer_idx == 0: width = 3 # Start points
		if layer_idx == LAYERS - 1: width = 1 # Boss
		
		for w in range(width):
			var node = {
				"layer": layer_idx,
				"index": w,
				"type": _get_random_type(layer_idx, rng, act),
				"next": [], 
				"parents": [] 
			}
			layer_nodes.append(node)
		
		map.append(layer_nodes)
	
	# Generate Paths
	for i in range(LAYERS - 1):
		var current_layer = map[i]
		var next_layer = map[i + 1]
		var current_width = current_layer.size()
		var next_width = next_layer.size()
		
		for node in current_layer:
			_connect_to_next(node, next_layer, current_width, next_width, rng)
			
		for next_node in next_layer:
			if next_node["parents"].is_empty():
				_connect_from_prev(next_node, current_layer, next_width, current_width, rng)
	
	# Post-Process: Prevent Back-to-Back Elites
	# Rule: If Node A is Elite, connected Node B cannot be Elite.
	for layer_idx in range(LAYERS - 1):
		var layer = map[layer_idx]
		for node in layer:
			if node["type"] == "elite":
				for next_idx in node["next"]:
					var child = map[layer_idx+1][next_idx]
					if child["type"] == "elite":
						# Reroll child to Fight or Event
						child["type"] = "fight" if rng.randf() > 0.5 else "event"
						
	return {"layers": map}

func _connect_to_next(node: Dictionary, next_layer: Array, current_layer_width: int, next_layer_width: int, rng: RandomNumberGenerator) -> void:
	var my_idx = node["index"]
	
	# Relative position (0.0 to 1.0)
	var my_pos = float(my_idx) / float(max(1, current_layer_width - 1))
	
	var candidates = []
	for n_node in next_layer:
		var n_idx = n_node["index"]
		var n_pos = float(n_idx) / float(max(1, next_layer_width - 1))
		
		if abs(n_pos - my_pos) < 0.4: # Distance threshold
			candidates.append(n_node)
	
	if candidates.is_empty():
		candidates = next_layer.duplicate() # Copy!
	else:
		candidates = candidates.duplicate()
	
	# Connect to 1 or 2
	var count = 1
	if rng.randf() < 0.4: count = 2
	
	for i in range(count):
		if candidates.is_empty(): break
		var pick = candidates[rng.randi() % candidates.size()]
		# Avoid duplicate connection
		if not pick["index"] in node["next"]:
			node["next"].append(pick["index"])
			pick["parents"].append(my_idx)
			candidates.erase(pick)

func _connect_from_prev(node: Dictionary, prev_layer: Array, current_layer_width: int, prev_layer_width: int, rng: RandomNumberGenerator) -> void:
	var my_idx = node["index"]
	var my_pos = float(my_idx) / float(max(1, current_layer_width - 1))
	
	var candidates = []
	for p_node in prev_layer:
		var p_idx = p_node["index"]
		var p_pos = float(p_idx) / float(max(1, prev_layer_width - 1))
		if abs(p_pos - my_pos) < 0.4:
			candidates.append(p_node)
	
	if candidates.is_empty():
		candidates = prev_layer.duplicate()
	else:
		candidates = candidates.duplicate()
	
	if candidates.is_empty():
		return

	var parent = candidates[rng.randi() % candidates.size()]
	if not node["index"] in parent["next"]:
		parent["next"].append(node["index"])
		node["parents"].append(parent["index"])


func _get_random_type(layer_idx: int, rng: RandomNumberGenerator, act: int) -> String:
	# Define key based on layer range
	var key = "mid"
	if layer_idx == 0: key = "start"
	elif layer_idx < 4: key = "early" # Layers 1,2,3 - No Elites in Act 1 protected zone?
	elif layer_idx >= LAYERS - 1: key = "boss"
	elif layer_idx > 11: key = "end" # near boss
	elif layer_idx > 8: key = "late"
	
	# Base Weights
	var weights_map = WEIGHTS.duplicate(true)
	var table: Dictionary = weights_map.get(key, weights_map["mid"])
	
	# Elite Frequency Tuning per Act (uses ELITE_TARGET_PCT constants)
	# Weight is scaled to approximate target percentage
	
	if table.has(TYPE_ELITE):
		var target_pct = ELITE_TARGET_PCT.get(act, 0.22)
		# Convert target % to weight (roughly: weight 10 out of ~100 = 10%)
		var elite_w = int(target_pct * 100)
		
		# Act 1 Protection: No elites in first 2 combat layers
		if act == 1 and layer_idx < ACT1_PROTECTED_COMBATS:
			elite_w = 0
			
		table[TYPE_ELITE] = elite_w
	
	var total_weight = 0
	for w in table.values():
		total_weight += w
	
	var roll = rng.randi() % total_weight
	var current = 0
	for type in table.keys():
		current += table[type]
		if roll < current:
			return type
	
	return "fight" # Fallback
