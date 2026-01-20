extends SceneTree

# Test Event Expansion and Treasure

const LOG_PATH = "user://test_event_expansion.log"

func _log(msg: String) -> void:
	print(msg)
	var f = FileAccess.open(LOG_PATH, FileAccess.READ_WRITE)
	if not f: f = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if f:
		f.seek_end()
		f.store_line(msg)

func _init():
	var f = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if f: f.store_line("Starting Event Expansion Test")
	
	var rc = get_root().get_node("/root/RunController")
	var ec = get_root().get_node("/root/EventController")
	var rs = get_root().get_node("/root/RewardSystem")
	
	if not rc or not ec or not rs:
		_log("FAIL: Autoloads missing")
		quit()
		return
		
	# 1. Start Run
	rc.start_new_run("Growth")
	await create_timer(0.1).timeout
	
	# 2. Test Treasure Generation (Direct)
	_log("Testing Treasure Generation...")
	var treasures = rs.generate_treasure_rewards(1)
	if treasures.context == "treasure" and treasures.options.size() == 3:
		_log("PASS: Treasure rewards generated correctly")
	else:
		_log("FAIL: Treasure rewards invalid: " + str(treasures))
		
	# 3. Test Event Loading (Mocking new events)
	# We want to see if we can load one of the new events, e.g. "ancient_forge"
	if ec._events_data.has("ancient_forge"):
		_log("PASS: 'ancient_forge' loaded from json")
	else:
		_log("FAIL: 'ancient_forge' missing")
		
	# 4. Test Event Outcome Trigger (Upgrade)
	_log("Testing Event Upgrade Logic...")
	# Simulate applying upgrade outcome
	# We can't easily mock user input in EventController without UI, 
	# but we can call _apply_outcome directly if we access it (it's private, but via script we can try)
	# Or just call select_choice if we mock _current_event
	
	ec._current_event = {
		"id": "test_event",
		"choices": [
			{
				"text": "Upgrade",
				"outcome": {"type": "upgrade_card"}
			}
		]
	}
	
	ec.select_choice(0)
	await create_timer(0.5).timeout
	
	# Check if we are now in DeckViewScreen
	var root = get_root().current_scene
	# Wait, DeckViewScreen is added to ScreenLayer in RunController logic
	var screen_layer = root.find_child("ScreenLayer")
	if screen_layer and screen_layer.get_child_count() > 0:
		var screen = screen_layer.get_child(0)
		if screen.name == "DeckViewScreen":
			_log("PASS: Upgrade event transitioned to DeckViewScreen")
		else:
			_log("FAIL: Expected DeckViewScreen, got " + screen.name)
	else:
		# If we are headless, maybe SceneTree changes apply differently compared to node structure?
		# But RunController uses direct instantiation.
		_log("FAIL: ScreenLayer empty or missing")

	# 5. Test Treasure Routing
	_log("Testing Treasure Routing...")
	# Reset to Map first (DeckView cancellation logic implies this)
	rc.return_to_map_view()
	await create_timer(0.1).timeout
	
	# Trigger "TREASURE" room logic via DungeonController (or mimic it)
	# DungeonController: _setup_treasure() -> run_controller.goto_reward("treasure")
	rc.goto_reward("treasure")
	await create_timer(0.1).timeout
	
	var sl2 = root.find_child("ScreenLayer")
	if sl2 and sl2.get_child_count() > 0:
		var scr = sl2.get_child(0)
		if scr.name == "RewardScreen": # Setup logic should set context
			if scr.current_context == "treasure":
				_log("PASS: RewardScreen loaded with treasure context")
			else:
				_log("FAIL: RewardScreen context " + str(scr.current_context))
		else:
			_log("FAIL: Expected RewardScreen")
			
	quit()
