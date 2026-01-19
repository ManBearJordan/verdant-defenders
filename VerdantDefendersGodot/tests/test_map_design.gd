extends SceneTree

# Test: Map Design Acceptance Tests
# Verifies map structure via Main.tscn

func _init():
	print("Test: Map Design Acceptance Tests")
	
	# Load main scene
	change_scene_to_file("res://Scenes/Main.tscn")
	await create_timer(1.0).timeout
	
	var main = current_scene
	if main.name != "Main":
		print("FAIL: Could not load Main.tscn")
		quit(1)
		return
	
	# Wait for MapScreen to load
	var screen_layer = main.find_child("ScreenLayer")
	
	# Start a run to trigger map generation
	var gc = root.get_node("/root/GameController")
	if gc:
		gc.start_run("growth", 0, 42)
	
	await create_timer(1.0).timeout
	
	# Get MapScreen
	var map = null
	for child in screen_layer.get_children():
		if child.name == "MapScreen":
			map = child
			break
	
	if not map:
		print("FAIL: MapScreen not found")
		quit(1)
		return
	
	# Access map data
	var map_data = map.map_data
	var layers = map_data.get("layers", [])
	
	if layers.size() == 0:
		print("FAIL: Map has no layers")
		quit(1)
		return
	
	print("Layer count: %d" % layers.size())
	
	# Verify key structure
	var tests_passed = 0
	var tests_total = 5
	
	# Test 1: Layer 0 is START
	if layers[0].size() == 1 and layers[0][0].get("type") == "START":
		print("✓ Layer 0: START")
		tests_passed += 1
	else:
		print("✗ Layer 0 should be single START node")
	
	# Test 2: Layer 5 is GATE
	if layers.size() > 5 and layers[5].size() == 1 and layers[5][0].get("type") == "MINIBOSS_GATE":
		print("✓ Layer 5: MINIBOSS_GATE")
		tests_passed += 1
	else:
		print("✗ Layer 5 should be single MINIBOSS_GATE node")
	
	# Test 3: Layer 9 is BOSS
	if layers.size() > 9 and layers[9].size() == 1 and layers[9][0].get("type") == "BOSS":
		print("✓ Layer 9: BOSS")
		tests_passed += 1
	else:
		print("✗ Layer 9 should be single BOSS node")
	
	# Test 4: Check edge counts
	var edge_ok = true
	for l in range(min(9, layers.size())):
		var edge_count = 0
		for node in layers[l]:
			edge_count += node.get("next", []).size()
		if edge_count > 5:
			print("✗ Layer %d has %d edges (max 5)" % [l, edge_count])
			edge_ok = false
	
	if edge_ok:
		print("✓ All layers have ≤5 edges")
		tests_passed += 1
	
	# Test 5: Optional minibosses on side lanes
	var opt_on_sides = true
	for l in range(layers.size()):
		for node in layers[l]:
			if node.get("type") == "MINIBOSS_OPT" and node.get("index") == 1:
				print("✗ Optional miniboss at center (should be side)")
				opt_on_sides = false
	
	if opt_on_sides:
		print("✓ Optional minibosses on side lanes only")
		tests_passed += 1
	
	print("")
	print("RESULT: %d/%d tests passed" % [tests_passed, tests_total])
	
	if tests_passed == tests_total:
		print("TEST COMPLETE: Map Design Acceptance Tests PASSED")
		quit(0)
	else:
		print("TEST FAILED")
		quit(1)
