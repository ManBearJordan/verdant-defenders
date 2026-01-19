extends SceneTree

func _init():
	print("Debug Map Check Starting...")
	
	# Load RunController
	var rc_script = load("res://scripts/RunController.gd")
	# rc is autoload, so get from root if running scene
	# But in SceneTree script, we need to access via root
	var root = get_root()
	var rc = root.get_node_or_null("/root/RunController")
	
	if not rc:
		print("RunController not found in Root!")
		# Try to instantiate? AutoLoads are handled by engine config.
		# If running via script, AutoLoads might be loaded depending on flags.
		# But 'godot --script' doesn't auto-load project.godot autoloads unless MainLoop is SceneTree?
		# Actually for simple scripts, Autoloads are NOT loaded automatically unless we run a Main Scene.
		# Test scripts usually fail to find Autoloads unless they manually load them or run a Scene.
		
		# But `test_flow_complete.gd` worked because it used `change_scene_to_file("Main.tscn")`?
		# No, it accessed `get_root().get_node("RunController")`?
		
		# Let's try to verify if RC has data.
		# If I can't access live game state, I can't debug "Why is the map gone" for the user *live*.
		# But the user is reporting a runtime issue.
		
		print("Simulating Run Start...")
		rc = rc_script.new()
		rc.start_new_run("growth")
		
		var data = rc.map_data
		if data.is_empty():
			print("FAIL: Map Data empty after start_new_run")
		else:
			print("SUCCESS: Map Data generated with %d layers" % data.get("layers", []).size())
			
			# Check node integrity
			var layers = data["layers"]
			var n_count = 0
			for l in layers: n_count += l.size()
			print("Total Nodes: %d" % n_count)
	
	quit()
