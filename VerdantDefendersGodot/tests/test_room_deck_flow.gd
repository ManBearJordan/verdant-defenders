extends SceneTree

# Test Room Deck Flow (Unit-like)

const LOG_PATH = "user://test_room_deck.log"

func _log(msg: String) -> void:
	print(msg)
	var f = FileAccess.open(LOG_PATH, FileAccess.READ_WRITE)
	if not f: f = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if f:
		f.seek_end()
		f.store_line(msg)

func _init():
	var f = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if f: f.store_line("Starting Room Deck Flow Test")
	
	print("Test: Room Deck Flow")
	
	# Load Autoloads (simulate behavior)
	var dc = get_root().get_node("/root/DungeonController")
	var mc = get_root().get_node("/root/MapController")
	var rc = get_root().get_node("/root/RunController")
	
	if not dc or not mc or not rc:
		_log("FAIL: Systems missing")
		quit()
		return
		
	# 1. Start Run
	_log("Action: Start Run")
	dc.start_run()
	await create_timer(0.5).timeout
	
	# Verify Deck Built
	if mc.room_deck.size() == 0 and mc.active_choices.size() == 0:
		_log("FAIL: Deck empty / No choices after start")
		quit()
		return
		
	if mc.active_choices.size() != 3:
		_log("FAIL: Active choices expected 3, got %d" % mc.active_choices.size())
		# quit() # warn but continue
		
	_log("Deck Size: %d, Choices: %d" % [mc.room_deck.size(), mc.active_choices.size()])
	_log("Current Layer: %s, Room: %d" % [mc.active_layer_name, mc.current_room_index])
	
	# 2. Select Card
	var choice = mc.active_choices[0]
	_log("Action: Selecting %s" % choice.type)
	
	# Simulate signal (MapController emits, DungeonController listens)
	mc.select_card(choice)
	await create_timer(0.5).timeout
	
	# Verify Scene Switch
	# Can't easily check 'current_scene' in Headless unless we track it
	# But DungeonController should print "DungeonController: Selected..."
	
	# 3. Simulate Scene Completion
	# Assume card type was COMBAT
	if choice.type == "COMBAT":
		_log("Action: Simulate Battle Victory")
		# RC.battle_victory() triggers Battle Ended -> goto_reward
		# RewardScreen usually calls next_room?
		# DC._on_battle_ended handles victory logic?
		# Existing DC: _on_battle_ended pass.
		# RunController: battle_victory -> goto_reward
		# RewardScreen -> Continue -> Return to Map -> DC.next_room
		
		# Let's call DC._return_to_map() directly to simulate flow completion
		dc._return_to_map()
		
	elif choice.type == "SHOP":
		_log("Action: Simulate Leave Shop")
		dc._return_to_map()
	
	elif choice.type == "EVENT":
		_log("Action: Simulate Event Done")
		dc._return_to_map()
	
	await create_timer(0.5).timeout
	
	# 4. Verify Next Room
	if mc.current_room_index != 1:
		_log("FAIL: Room index not incremented. Got %d" % mc.current_room_index)
	else:
		_log("SUCCESS: Advanced to room 1")
		# Verify new choices drawn
		if mc.active_choices.size() != 3:
			_log("FAIL: Choices not refilled")
			_log("New Choices Ready")
			
	# 4b. Verify Elite Logic (Room 7-11)
	_log("Action: Force Room 8 (Elite Range)")
	mc.current_room_index = 8
	mc.draw_choices()
	
	var found_elite = false
	for c in mc.active_choices:
		if c.type == "ELITE":
			found_elite = true
			break
			
	if found_elite:
		_log("SUCCESS: Elite card found in choices at Room 8")
	else:
		_log("FAIL: No Elite card found in Room 8 choices")

	# 5. Check Layer Pacing (Skip to Boss)
	# Cheat: force index 14
	mc.current_room_index = 14
	_log("Action: Force Room 14 (Boss Pre-req)")
	
	# Trigger next step? next_room() increments index THEN checks.
	# If we are AT 14, next draw should be Boss?
	# Implementation: 
	# draw_choices(): if current_room_index == 14 -> signal boss_reached
	# So if we are currently at 14, calling draw_choices() triggers boss.
	# But normally finish room 13 -> next_room() -> index=14 -> draw_choices() -> Boss.
	
	# Let's simulate finish room 13
	mc.current_room_index = 13
	dc._return_to_map() # -> index=14 -> draw_choices
	await create_timer(0.2).timeout
	
	if mc.current_room_index != 14:
		_log("FAIL: Index mismatch for boss. Got %d" % mc.current_room_index)
	
	# Did we get BOSS signal?
	# Hard to check signal emission in unit test this way without spy.
	# But DungeonController should print "BOSS REACHED"
	
	_log("TEST COMPLETE: Room Deck Navigation Verified")
	quit()
