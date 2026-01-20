extends SceneTree

# Test Fixed Deck Layout

const LOG_PATH = "user://test_deck_layout.log"

func _log(msg: String) -> void:
	print(msg)
	var f = FileAccess.open(LOG_PATH, FileAccess.READ_WRITE)
	if not f: f = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if f:
		f.seek_end()
		f.store_line(msg)

func _init():
	var f = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if f: f.store_line("Starting Deck Layout Test")
	
	var mc = get_root().get_node("/root/MapController")
	if not mc:
		_log("FAIL: MapController missing")
		quit()
		return
		
	mc.start_run()
	await create_timer(0.1).timeout
	
	var deck = mc.room_deck
	
	# Verify Size
	if deck.size() != 14:
		_log("FAIL: Deck size is " + str(deck.size()) + ", expected 14")
	else:
		_log("Deck Size: OK")
		
	# Verify Indices
	var mapping = {
		3: "SHOP", 7: "SHOP", 11: "SHOP",
		4: "EVENT", 10: "EVENT",
		6: "TREASURE", 13: "TREASURE"
	}
	
	var errors = 0
	for i in range(14):
		var expected = "COMBAT"
		if mapping.has(i): expected = mapping[i]
		
		var actual = deck[i].type
		if actual != expected:
			_log("FAIL at index %d: Expected %s, Got %s" % [i, expected, actual])
			errors += 1
		else:
			# _log("Index %d: %s (OK)" % [i, actual])
			pass
			
	if errors == 0:
		_log("PASS: All indices match template")
	else:
		_log("FAIL: Layout mismatch")
		
	quit()
