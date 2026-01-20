extends SceneTree

# Test Elite/MiniBoss Flow and Rewards

const LOG_PATH = "user://test_elite_miniboss.log"

func _log(msg: String) -> void:
	print(msg)
	var f = FileAccess.open(LOG_PATH, FileAccess.READ_WRITE)
	if not f: f = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if f:
		f.seek_end()
		f.store_line(msg)

func _init():
	var f = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if f: f.store_line("Starting Elite/MiniBoss Flow Test")
	
	print("Test: Elite/MiniBoss Logic")
	
	var rc = get_root().get_node("/root/RunController")
	var mc = get_root().get_node("/root/MapController")
	var rs = get_root().get_node("/root/RewardSystem")
	
	if not rc or not mc or not rs:
		_log("FAIL: Autoloads missing")
		quit()
		return
		
	# 1. Start Run
	rc.start_new_run("growth")
	await create_timer(0.2).timeout
	
	# 2. Force Mini-Boss Room Type in RunController (mocking selection)
	# Normally MapController selects it. We can just set RC state directly to test Reward Flow.
	rc.current_room_type = "miniboss"
	_log("Set Room Type to: miniboss")
	
	# 3. Simulate Battle Victory
	_log("Action: Battle Victory")
	rc.battle_victory()
	await create_timer(0.5).timeout
	
	# 4. Verify Reward Screen Context
	var root = get_root().get_node("Main") # Assuming Main.tscn name or current scene
	# In headless, current_scene is the root of the loaded scene.
	var scene = rc.get_tree().current_scene
	var layer = scene.find_child("ScreenLayer")
	if layer and layer.get_child_count() > 0:
		var screen = layer.get_child(0)
		if screen.name == "RewardScreen":
			_log("RewardScreen Loaded")
			if screen.current_context == "miniboss":
				_log("PASS: Context is miniboss")
			else:
				_log("FAIL: Context is " + str(screen.current_context))
		else:
			_log("FAIL: Screen is " + screen.name)
	else:
		_log("FAIL: No screen in layer")
		
	# 5. Test MapController Injection Logic (Unit test logic)
	mc.current_room_index = 8
	mc.elite_defeated_in_layer = false
	mc.mini_boss_defeated_in_layer = false
	mc.active_choices = [mc._create_card("COMBAT"), mc._create_card("COMBAT"), mc._create_card("COMBAT")]
	# Force injection logic
	# We can't easily force randf() result, but we can call draw_choices logic via script re-eval?
	# Actually, effectively verifying the method exists is enough if logic is sound.
	# But let's verify logic didn't crash.
	mc.draw_choices()
	_log("MapController.draw_choices executed (Room 8)")
	var has_special = false
	for c in mc.active_choices:
		if c.type == "ELITE" or c.type == "MINI_BOSS":
			has_special = true
			_log("Found injected card: " + c.type)
			
	if has_special:
		_log("PASS: Injection logic works")
	else:
		_log("FAIL: No injection in Room 8 (Random chance? Retry allowed)")
		
	quit()
