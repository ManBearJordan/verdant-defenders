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
		_log("Deck Size: OK (14)")
		
	# Verify Rule 1: No Shop in first 3 cards (indices 0, 1, 2)
	# Note: MapController pops front for choices. 
	# room_deck[0], [1], [2] are the NEXT choices.
	
	var shop_error = false
	for i in range(3):
		if i < deck.size():
			if deck[i].type == "SHOP":
				_log("FAIL: Shop found at index " + str(i) + " (First Draw)")
				shop_error = true
	
	if not shop_error:
		_log("PASS: No Shops in first draw")
		
	# Verify Rule 2: No Event adjacent to Treasure
	var adjacency_error = false
	for i in range(deck.size() - 1):
		var c1 = deck[i]
		var c2 = deck[i+1]
		
		# Event <-> Treasure
		if (c1.type == "EVENT" and c2.type == "TREASURE") or \
		   (c1.type == "TREASURE" and c2.type == "EVENT"):
			_log("FAIL: Adjacency conflict at %d-%d: %s | %s" % [i, i+1, c1.type, c2.type])
			adjacency_error = true
			
	if not adjacency_error:
		_log("PASS: Adjacency Rules Respected")
		
	quit()
