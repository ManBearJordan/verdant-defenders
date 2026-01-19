extends "res://addons/gut/test.gd"

var MapGenerator = preload("res://scripts/MapGenerator.gd")
var map_generator: Node

func before_each():
	map_generator = MapGenerator.new()
	# add_child is usually needed for nodes to function if they use get_node, 
	# but MapGenerator is pure logic mostly. However, adding it is safer.
	add_child(map_generator)

func after_each():
	if is_instance_valid(map_generator):
		map_generator.queue_free()

func test_generate_map_structure():
	var map = map_generator.generate_map()
	
	assert_true(map.has("layers"), "Map should have layers")
	var layers = map["layers"]
	assert_eq(layers.size(), 15, "Should have 15 layers")
	
	# Verify layer 0 (Start)
	var start_layer = layers[0]
	assert_gt(start_layer.size(), 0, "Layer 0 should have nodes")
	for n in start_layer:
		assert_eq(n["type"], "fight", "Layer 0 should be fight")
		assert_eq(n["layer"], 0, "Node layer should match")
		assert_gt(n["next"].size(), 0, "Start nodes should connect to next layer")

	# Verify layer 14 (Boss)
	var boss_layer = layers[14]
	assert_eq(boss_layer.size(), 1, "Boss layer should be 1 node")
	assert_eq(boss_layer[0]["type"], "boss", "Last layer should be boss")

func test_map_connectivity_sample():
	# Perform a random walk check
	var map = map_generator.generate_map()
	var layers = map["layers"]
	
	var current_idx = 0 # Start at first node of layer 0
	for l in range(14): # Walk up to boss
		var node = layers[l][current_idx]
		var next_indices = node["next"]
		if next_indices.is_empty():
			fail_test("Dead end at layer %d index %d" % [l, current_idx])
			return
		
		# Pick first valid path
		current_idx = next_indices[0]
	
	# Valid walk if we reached here
	pass_test("Found path to boss")
