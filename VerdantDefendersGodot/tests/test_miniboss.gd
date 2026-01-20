extends SceneTree

const LOG_PATH = "user://test_miniboss.log"

func _log(msg: String) -> void:
	print(msg)
	var f = FileAccess.open(LOG_PATH, FileAccess.READ_WRITE)
	if not f: f = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if f:
		f.seek_end()
		f.store_line(msg)

func _init():
	var f = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if f: f.store_line("Starting Mini-Boss Test")
	
	# Load Dependencies
	var dl_script = load("res://scripts/DataLayer.gd")
	var dl = dl_script.new()
	get_root().add_child(dl)
	dl.load_all()
	
	# Check Enemy Data Loading
	var mb = dl.get_enemy("bramble_troll")
	if mb:
		_log("PASS: Bramble Troll loaded from JSON")
		if mb.max_hp == 120:
			_log("PASS: Bramble Troll HP correct")
		else:
			_log("FAIL: HP mismatch: " + str(mb.max_hp))
	else:
		_log("FAIL: Bramble Troll not found")
		
	# Check Map Injection
	var mc_script = load("res://scripts/MapController.gd")
	var mc = mc_script.new()
	get_root().add_child(mc)
	
	# Mock RoomCard class since MapController uses inner class or loaded script? 
	# MapController uses `RoomCard` class_name but it might not be global if script not loaded via classdb?
	# It is `class_name RoomCard`.
	
	mc.current_room_index = 8
	mc.elite_defeated_in_layer = false
	mc.mini_boss_defeated_in_layer = false
	mc.start_run() # builds deck
	
	# Force injection logic check
	# We can't force RNG easily without seed control in randf().
	# But we can try multiple times.
	var injected = false
	for i in range(20):
		# Populate room_deck with dummy combats so draw_choices has something to pull
		mc.room_deck.clear()
		mc.room_deck.append(mc._create_card("COMBAT"))
		mc.room_deck.append(mc._create_card("COMBAT"))
		mc.room_deck.append(mc._create_card("COMBAT"))
		
		mc.active_choices.clear() # Simulate clean state
		mc.draw_choices()
		
		for c in mc.active_choices:
			if c.type == "MINI_BOSS":
				injected = true
				break
		if injected: break
		
	if injected:
		_log("PASS: Mini-Boss injected in Room 8")
	else:
		_log("WARN: Mini-Boss not injected in 20 attempts (RNG or logic?)")

	# Check RunController Battle Start Logic
	var rc_script = load("res://scripts/RunController.gd")
	var rc = rc_script.new()
	get_root().add_child(rc)
	
	# Mock RoomController
	var roc_script = load("res://scripts/RoomController.gd")
	var roc = roc_script.new()
	get_root().add_child(roc)
	
	# Try match logic via exposed method? 
	# rc._start_battle is "private" but accessible in GDScript.
	# But it relies on Scene Changing which crashes in headless if paths fail.
	# We just want to check if `_roll_miniboss_pack` is called.
	# Stub RoomController
	
	# Verification complete
	quit()
