extends SceneTree

const LOG_PATH = "user://test_journey.log"

func _log(msg: String) -> void:
	print(msg)
	var f = FileAccess.open(LOG_PATH, FileAccess.READ_WRITE)
	if not f: f = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if f:
		f.seek_end()
		f.store_line(msg)

func _init():
	var f = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if f: f.store_line("Starting Journey Map Test")
	
	# Load Dependencies
	var mc_script = load("res://scripts/MapController.gd")
	var mc = mc_script.new()
	get_root().add_child(mc)
	
	# Test 1: Deck Composition & Rules
	mc.start_run()
	var deck = mc.room_deck
	
	# Verify Size (14)
	if deck.size() != 14:
		_log("FAIL: Deck size " + str(deck.size()))
	else:
		_log("PASS: Deck size 14")
		
	# 1b. Verify No Event-Treasure Adjacency (Post-Build)
	var adj_fail = false
	for i in range(deck.size()-1):
		var t1 = deck[i].type
		var t2 = deck[i+1].type
		if (t1 == "EVENT" and t2 == "TREASURE") or (t1 == "TREASURE" and t2 == "EVENT"):
			adj_fail = true
			_log("FAIL: Adjacency Event-Treasure at %d" % i)
			
	if not adj_fail:
		_log("PASS: No Event-Treasure Adjacency")
		
	# Test 2: Flow & Boss
	var current_idx = 0
	var elite_seen = false
	
	# Loop until Room 15 (Index 14)
	while current_idx < 14:
		# Check choices count
		if mc.active_choices.size() != 3:
			_log("FAIL: Invalid choice count at room " + str(current_idx))
			
		# Check Elite Injection (Rooms 7-11)
		# We can't force randf, but we can check if it HAPPENS.
		# Since chance is 20%, proper test needs seed or many runs.
		# Here we just log if observed.
		for c in mc.active_choices:
			if c.type == "ELITE" or c.type == "MINI_BOSS":
				if current_idx >= 7 and current_idx <= 11:
					elite_seen = true
					_log("INFO: Elite seen at Room %d" % (current_idx+1))
				else:
					_log("FAIL: Elite seen OUTSIDE range at Room %d" % (current_idx+1))

		# Pick one
		var picked = mc.active_choices[0]
		mc.select_card(picked)
		mc.next_room()
		current_idx = mc.current_room_index
		
	# Now at Room 15
	if mc.active_choices.size() == 1 and mc.active_choices[0].type == "BOSS":
		_log("PASS: Room 15 is Boss")
	else:
		_log("FAIL: Room 15 invalid state")
		
	# Test 3: Boss -> Next Layer
	_log("Action: Defeating Boss...")
	# Simulate boss selection
	mc.select_card(mc.active_choices[0])
	# Simulate return_to_map Calling next_room()
	mc.next_room() # Should allow transition
	
	if mc.current_layer_index == 1:
		_log("PASS: Layer Advanced to 1 (Decay)")
		if mc.current_room_index == 0:
			_log("PASS: Room Index Reset to 0")
		else:
			_log("FAIL: Room Index not reset")
	else:
		_log("FAIL: Layer did not advance. Current: " + str(mc.current_layer_index))

	_log("TEST COMPLETE")
	quit()
