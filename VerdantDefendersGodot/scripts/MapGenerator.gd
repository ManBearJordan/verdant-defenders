extends Node

# MapGenerator.gd - PATH-GRAPH GENERATOR (Act 1 Spec)
# Replaces "lanes" with a deterministic graph template.
#
# RULES:
# - 9 Layers (r0..r8)
# - r0=Start(3), r8=Boss(1)
# - Elites: r3(Right), r5(Mid), r7(Mid+Right)
# - Shop: r4(Left)
# - Deterministic connections for merges/splits

const LAYERS = 9
const COL_LEFT = 0
const COL_MID = 1
const COL_RIGHT = 2

# Row definitions
const ROW_START = 0
const ROW_BOSS = 8

func generate_map(_act: int = 1) -> Dictionary:
	var rng = RandomNumberGenerator.new()
	rng.seed = Time.get_unix_time_from_system()
	
	var layers_arr = []
	for l in range(LAYERS):
		var layer_nodes = []
		
		# How many nodes in this row?
		# r0=3, r8=1, others=3
		var cols = [COL_LEFT, COL_MID, COL_RIGHT]
		if l == ROW_BOSS:
			cols = [COL_MID]
			
		for c in cols:
			var node_data = {
				"layer": l,
				"index": c,
				"type": "SKIRMISH", # Default
				"next": [],
				"parents": []
			}
			
			# TYPE ASSIGNMENT RULES
			if l == ROW_START:
				node_data["type"] = "START"
			elif l == ROW_BOSS:
				node_data["type"] = "BOSS"
			elif l == 3: # r3 MUST contain 1 Elite (Right)
				if c == COL_RIGHT: node_data["type"] = "MINIBOSS" # "Right node is Elite"
			elif l == 4: # r4 MUST contain 1 Shop (Left)
				if c == COL_LEFT: node_data["type"] = "SHOP"
			elif l == 5: # r5 MUST contain 1 Elite (Mid)
				if c == COL_MID: node_data["type"] = "MINIBOSS"
			elif l == 7: # r7 MUST contain 1 Elite (Mid) AND 1 Elite (Right)
				if c == COL_MID or c == COL_RIGHT: node_data["type"] = "MINIBOSS"
			else:
				# r1, r2, r6: Fight/Event mix
				# Simple mix: 70% Skirmish, 30% Event
				if rng.randf() < 0.3:
					node_data["type"] = "EVENT"
				else:
					node_data["type"] = "SKIRMISH"
			
			layer_nodes.append(node_data)
		
		# Sort by index to ensure A, B, C order (Left, Mid, Right)
		layer_nodes.sort_custom(func(a, b): return a["index"] < b["index"])
		layers_arr.append(layer_nodes)

	# APPLY DETERMINISTIC CONNECTIONS
	# A=0 (Left), B=1 (Mid), C=2 (Right)
	# Using the specific graph template from spec
	
	# Helper to find node by index in a layer
	var get_node = func(layer_idx, col_idx):
		for n in layers_arr[layer_idx]:
			if n["index"] == col_idx:
				return n
		return null
	
	var add_edge = func(l_from, c_from, c_to):
		var n_from = get_node.call(l_from, c_from)
		var n_to = get_node.call(l_from + 1, c_to)
		if n_from and n_to:
			if not n_from["next"].has(c_to):
				n_from["next"].append(c_to)
	
	# r0 -> r1 (Direct)
	add_edge.call(0, COL_LEFT, COL_LEFT)   # A0->A1
	add_edge.call(0, COL_MID, COL_MID)     # B0->B1
	add_edge.call(0, COL_RIGHT, COL_RIGHT) # C0->C1
	
	# r1 -> r2 (First Choice)
	add_edge.call(1, COL_LEFT, COL_LEFT)   # A1->A2
	add_edge.call(1, COL_LEFT, COL_MID)    # A1->B2
	add_edge.call(1, COL_MID, COL_MID)     # B1->B2
	add_edge.call(1, COL_RIGHT, COL_RIGHT) # C1->C2
	add_edge.call(1, COL_RIGHT, COL_MID)   # C1->B2
	
	# r2 -> r3 (First Merge)
	add_edge.call(2, COL_LEFT, COL_LEFT)   # A2->A3
	add_edge.call(2, COL_MID, COL_MID)     # B2->B3
	add_edge.call(2, COL_MID, COL_LEFT)    # B2->A3 !!! Spec says B2->B3 and B2->A3
	add_edge.call(2, COL_RIGHT, COL_RIGHT) # C2->C3
	
	# r3 -> r4 (Split Again)
	add_edge.call(3, COL_LEFT, COL_LEFT)   # A3->A4
	add_edge.call(3, COL_LEFT, COL_MID)    # A3->B4
	add_edge.call(3, COL_MID, COL_MID)     # B3->B4
	add_edge.call(3, COL_RIGHT, COL_RIGHT) # C3->C4
	add_edge.call(3, COL_RIGHT, COL_MID)   # C3->B4
	
	# r4 -> r5 (Direct-ish)
	add_edge.call(4, COL_LEFT, COL_LEFT)   # A4->A5
	add_edge.call(4, COL_MID, COL_MID)     # B4->B5
	add_edge.call(4, COL_MID, COL_RIGHT)   # B4->C5 !!! Spec says B4->B5 and B4->C5
	add_edge.call(4, COL_RIGHT, COL_RIGHT) # C4->C5
	
	# r5 -> r6 (Merge)
	add_edge.call(5, COL_LEFT, COL_MID)    # A5->B6
	add_edge.call(5, COL_MID, COL_MID)     # B5->B6
	add_edge.call(5, COL_RIGHT, COL_MID)   # C5->B6 !!! Spec says C5->B6
	add_edge.call(5, COL_RIGHT, COL_RIGHT) # C5->C6
	
	# r6 -> r7 (Final Split)
	# Spec: "B6->A7 and B6->B7 and B6->C7" (Tri-split!)
	# Spec: "C6->C7"
	add_edge.call(6, COL_MID, COL_LEFT)    # B6->A7
	add_edge.call(6, COL_MID, COL_MID)     # B6->B7
	add_edge.call(6, COL_MID, COL_RIGHT)   # B6->C7
	add_edge.call(6, COL_RIGHT, COL_RIGHT) # C6->C7
	
	# r7 -> r8 (To Boss)
	# All r7 nodes -> Boss (which is COL_MID only)
	if layers_arr[7].size() >= 1: add_edge.call(7, COL_LEFT, COL_MID)
	if layers_arr[7].size() >= 2: add_edge.call(7, COL_MID, COL_MID)
	if layers_arr[7].size() >= 3: add_edge.call(7, COL_RIGHT, COL_MID)
	
	# Clean up any potential missing next/parents links (parents populated implicitly?)
	# Typically MapScreen handles drawing, but we should clear duplicates if any
	
	return {"layers": layers_arr}
