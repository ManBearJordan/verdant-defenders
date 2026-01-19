extends SceneTree

func _init():
	print("--- Starting Stabilization Verification ---")
	
	# 1. Setup Environment
	var root = get_root()
	
	# Add Singletons manually since we are not running Main.tscn
	var dl_script = load("res://scripts/DataLayer.gd")
	var dl = dl_script.new()
	dl.name = "DataLayer"
	root.add_child(dl)
	
	var mp_script = load("res://scripts/MetaPersistence.gd")
	var mp = mp_script.new()
	mp.name = "MetaPersistence"
	root.add_child(mp)
	
	var rp_script = load("res://scripts/RunPersistence.gd")
	var rp = rp_script.new()
	rp.name = "RunPersistence"
	root.add_child(rp)
	
	var dc_script = load("res://scripts/DungeonController.gd")
	var dc = dc_script.new()
	dc.name = "DungeonController"
	root.add_child(dc)
	
	var gc_script = load("res://scripts/GameController.gd")
	var gc = gc_script.new()
	gc.name = "GameController"
	root.add_child(gc)
	
	# Mock UI for GC to find
	var ui_stub = Control.new()
	ui_stub.name = "GameUI"
	ui_stub.add_to_group("game_ui")
	root.add_child(ui_stub)
	
	# 2. Test Act Logic
	print("\n[Test 1] Act Progression")
	dc.start_run()
	if dc.current_act != 1:
		print("FAIL: Initial Act is %d (Expected 1)" % dc.current_act)
		quit(1)
		return
		
	print("Advancing Act...")
	dc.advance_to_next_act()
	if dc.current_act != 2:
		print("FAIL: Act did not advance. Current: %d" % dc.current_act)
		quit(1)
		return
	print("PASS: Act Advanced to 2. Pool: %s" % dc.get_current_pool())
	
	# 3. Test XP Gain (MetaPersistence)
	print("\n[Test 2] Meta Progression")
	var initial_xp = mp.current_xp
	print("Initial XP: %d" % initial_xp)
	
	mp.add_xp(50)
	if mp.current_xp != initial_xp + 50:
		print("FAIL: XP did not update. Expected %d, Got %d" % [initial_xp + 50, mp.current_xp])
		quit(1)
		return
	print("PASS: XP Gained.")
	
	# 4. Test Persistence (Save/Load)
	print("\n[Test 3] Run Persistence")
	gc.player_hp = 50
	gc.max_hp = 100
	gc.current_class = "TEST_CLASS"
	
	print("Saving Game...")
	rp.save_game()
	
	# Verify File
	if FileAccess.file_exists("user://savegame.json"):
		var f = FileAccess.open("user://savegame.json", FileAccess.READ)
		print("Save Content: %s" % f.get_as_text())
	else:
		print("FAIL: Save file not created!")
		quit(1)
		return
	
	# Modify state to verify load restores it
	gc.player_hp = 10
	
	print("Loading Game...")
	var success = rp.load_game()
	if not success:
		print("FAIL: Load returned false")
		quit(1)
		return
		
	if gc.player_hp != 50:
		print("FAIL: HP not restored. Expected 50, Got %d" % gc.player_hp)
		# Debug why
		print("GC Path: %s" % gc.get_path())
		var rp_gc = rp.get_node_or_null("/root/GameController")
		print("Persistence sees GC: %s" % str(rp_gc))
		quit(1)
		return
		
	print("PASS: Save/Load successful.")
	
	print("\n--- ALL TESTS PASSED ---")
	quit(0)
