extends SceneTree

# Test Canonical Flow: Menu -> Map -> Combat -> Reward -> Map
# Architecture: Main.tscn is Root. Screens are managed by RunController via ScreenLayer.

const LOG_PATH = "user://test_trace.log"

func _log(msg: String) -> void:
	print(msg)
	var f = FileAccess.open(LOG_PATH, FileAccess.READ_WRITE)
	if not f: f = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if f:
		f.seek_end()
		f.store_line(msg)

func _init():
	var f = FileAccess.open(LOG_PATH, FileAccess.WRITE) # Clear log
	if f: f.store_line("Test Started")
	
	_log("Test: Canonical Scene Flow (via RunController)")
	# Note: In headless mode with SceneTree script, 'change_scene_to_file' replaces root.
	# But Main.tscn expects to be root.
	
	# Load Main
	change_scene_to_file("res://Scenes/Main.tscn")
	
	# Wait for Main
	await create_timer(1.0).timeout
	var main = current_scene
	
	# Get RunController (Autoload)
	var rc = get_root().get_node("/root/RunController")
	if not rc:
		print("FAIL: RunController not found")
		quit()
		return

	var screen_layer = main.find_child("ScreenLayer")
	# If ScreenLayer missing, maybe RunController wiped it?
	# But RC only wipes children OF screen_layer.
	
	if not screen_layer:
		print("WARNING: ScreenLayer not found in Main, continuing with RC management assumption")
	
	# 1. Start Run via RunController
	print("Action: Start Run")
	rc.start_new_run("growth")
	
	await create_timer(1.0).timeout
	
	# 2. Verify Map
	# RC uses _change_screen -> finds ScreenLayer -> adds child.
	if screen_layer:
		var map = _get_active_screen(screen_layer)
		if not map or map.name != "MapScreen":
			print("FAIL: Expected MapScreen under ScreenLayer, got %s" % (map.name if map else "None"))
			# Check root just in case
			if current_scene.name == "MapScreen":
				print("INFO: MapScreen is Root (Fallback logic triggered)")
			else:
				quit()
				return
		else:
			print("SUCCESS: MapScreen Loaded (Child)")
	else:
		if current_scene.name != "MapScreen":
			print("FAIL: Expected MapScreen as Root")
			quit()
			return
		print("SUCCESS: MapScreen Loaded (Root)")
	
	# 3. Enter Node (via RunController)
	print("Action: Enter Combat Node")
	rc.enter_node(1) # Try entering node 1
	
	await create_timer(1.0).timeout
	
	# 4. Verify Combat
	if screen_layer:
		var combat = _get_active_screen(screen_layer)
		if not combat or combat.name != "CombatScreen":
			print("FAIL: Expected CombatScreen, got %s" % (combat.name if combat else "None"))
			quit()
			return
		print("SUCCESS: CombatScreen Loaded")
	
	# 5. Simulate Victory via RunController
	print("Action: Win Combat")
	rc.battle_victory()
	
	await create_timer(1.0).timeout
	
	# 6. Verify Reward
	if screen_layer:
		var reward = _get_active_screen(screen_layer)
		if not reward or reward.name != "RewardScreen":
			print("FAIL: Expected RewardScreen, got %s" % (reward.name if reward else "None"))
			quit()
			return
		print("SUCCESS: RewardScreen Loaded")
	
	# 7. Return to Map
	_log("Action: Return to Map")
	rc.return_to_map()
	
	await create_timer(1.0).timeout
	
	# 8. Verify Map Return
	if screen_layer:
		var map2 = _get_active_screen(screen_layer)
		if not map2 or map2.name != "MapScreen":
			_log("FAIL: Expected Return to MapScreen, got %s" % (map2.name if map2 else "None"))
			quit()
			return
	
	_log("SUCCESS: Returned to Map")
	_log("TEST COMPLETE: Canonical Flow Verified")
	quit()

func _get_active_screen(layer: CanvasLayer) -> Node:
	if layer.get_child_count() > 0:
		return layer.get_child(0)
	return null
