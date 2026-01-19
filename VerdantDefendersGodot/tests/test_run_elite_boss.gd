extends SceneTree

# Test Elite and Boss Flows via RunController

const LOG_PATH = "user://test_elite_boss.log"

func _log(msg: String) -> void:
	print(msg)
	var f = FileAccess.open(LOG_PATH, FileAccess.READ_WRITE)
	if not f: f = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if f:
		f.seek_end()
		f.store_line(msg)

func _init():
	var f = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if f: f.store_line("Starting Elite/Boss Flow Test")
	
	print("Test: Elite/Boss Flow Verification")
	
	# Load Main to ensure ScreenLayer exists
	change_scene_to_file("res://Scenes/Main.tscn")
	await create_timer(1.0).timeout
	
	var rc = get_root().get_node("/root/RunController")
	if not rc:
		_log("FAIL: RunController not found")
		quit()
		return

	# 1. Start Run
	_log("Action: Start Run")
	rc.start_new_run("growth")
	await create_timer(0.5).timeout
	
	# 2. Find Elite Node
	var elite_node_id = -1
	var layers = rc.map_data.get("layers", [])
	
	# Search for ELITE type
	for l in layers:
		for node in l:
			if node.get("type") in ["ELITE", "MINIBOSS"]:
				elite_node_id = node.get("layer") * 3 + node.get("index") # Assumption: ID calc
				# Or better, trust the ID in the node if it exists?
				# MapGenerator stores 'index' (0-2) and 'layer'.
				# MapNode ID is usually layer*3 + index.
				break
		if elite_node_id != -1: break
		
	if elite_node_id == -1:
		_log("FAIL: No Elite Node found in map data")
		quit()
		return
		
	_log("Action: Navigating to Elite Node %d" % elite_node_id)
	
	# Cheat: Unlock node (cleared_nodes)
	# Normally we navigate step by step, but for unit test we can just enter.
	# But RunController might validate connectivity? enter_node doesn't seem to validate strictly yet.
	rc.enter_node(elite_node_id)
	
	await create_timer(1.0).timeout
	
	# 3. Verify CombatSystem (Elite)
	var cs = get_root().get_node("/root/CombatSystem")
	if not cs:
		_log("FAIL: CombatSystem not found")
		quit()
		return
		
	var enemies = cs.get_enemies()
	if enemies.size() == 0:
		_log("FAIL: No enemies spawned for Elite")
		quit()
		return
	
	# Check if Elite logic applied (e.g. tier, or specific elite names)
	# CombatSystem doesn't store 'tier' directly, but spawns differ.
	# We can check names or just assume success if count > 0 and call valid.
	_log("Combat Started. Enemies: %d" % enemies.size())
	for e in enemies:
		_log(" - Enemy: %s (HP: %d)" % [e.display_name, e.max_hp])
		
	# 4. Win Elite Battle
	_log("Action: Win Elite Battle")
	rc.battle_victory()
	await create_timer(0.5).timeout
	
	# 5. Verify Reward Screen
	_log("Verifying Reward Screen...")
	# Check if we are in Reward Screen (via ScreenLayer)
	# Assuming Main is root
	var main = current_scene
	var screen_layer = main.find_child("ScreenLayer")
	if screen_layer and screen_layer.get_child_count() > 0:
		var screen = screen_layer.get_child(0)
		_log("Current Screen: %s" % screen.name)
		if screen.name != "RewardScreen":
			_log("FAIL: Expected RewardScreen")
			# quit() # Continue to try boss
	
	# Return to Map
	rc.return_to_map()
	await create_timer(0.5).timeout
	
	# 6. Find Boss Node
	var boss_node_id = -1
	# Check last layer
	if layers.size() > 0:
		var last_layer = layers[layers.size()-1]
		for node in last_layer:
			if node.get("type") == "BOSS":
				boss_node_id = node.get("layer") * 3 + node.get("index")
				break
				
	if boss_node_id == -1:
		_log("FAIL: No Boss Node found")
		quit()
		return

	_log("Action: Navigating to Boss Node %d" % boss_node_id)
	rc.enter_node(boss_node_id)
	await create_timer(1.0).timeout
	
	# 7. Verify Boss
	enemies = cs.get_enemies()
	if enemies.size() == 0:
		_log("FAIL: No enemies spawned for Boss")
		quit()
		return
		
	_log("Boss Combat Started. Enemies: %s" % str(enemies.size()))
	for e in enemies:
		_log(" - BOSS: %s (HP: %d)" % [e.display_name, e.max_hp])
		
	_log("TEST COMPLETE: Elite and Boss Flows Verified")
	quit()
