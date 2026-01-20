extends SceneTree

const LOG_PATH = "user://test_starter_deck.log"

func _log(msg: String) -> void:
	print(msg)
	var f = FileAccess.open(LOG_PATH, FileAccess.READ_WRITE)
	if not f: f = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if f:
		f.seek_end()
		f.store_line(msg)

func _init():
	var f = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if f: f.store_line("Starting Starter Deck Test")

	var rc = get_root().get_node("/root/RunController")
	
	if not rc:
		_log("FAIL: RunController missing")
		quit()
		return

	# Test Growth Deck
	_log("Testing Growth Deck...")
	rc.start_new_run("Growth") # Note capitalization matching JSON key "Growth" or handling case?
	# DataLayer uses starting_decks_config which is Dictionary loaded from JSON.
	# DataLayer.get_starting_deck(class_id) uses `starting_decks_config.get(class_id, [])`.
	# JSON keys are "Growth", "Decay".
	# RunController usually passes lowercase?
	# Let's check `MainMenu` or assume Title Case.
	# RunController.current_class_id defaults to "growth".
	# DataLayer lookup might be case sensitive.
	# Let's test "Growth" as per JSON.
	
	await create_timer(0.1).timeout
	var deck = rc.deck
	_log("Deck Size: " + str(deck.size()))
	_log("Cards: " + str(deck))
	
	# Verify content: 5 thorn_lash, 4 seed_shield, 1 sprout_heal = 10 cards
	if deck.size() == 10:
		if deck.count("thorn_lash") == 5:
			_log("PASS: Growth Deck Loaded Correctly")
		else:
			_log("FAIL: Incorrect card counts")
	else:
		# If size is 4, it fell back to default [strike, strike, defend, defend]
		_log("FAIL: Deck size mismatch. Expected 10, got " + str(deck.size()))
		
	quit()
