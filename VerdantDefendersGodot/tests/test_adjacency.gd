extends SceneTree

const LOG_PATH = "user://test_adjacency.log"

func _log(msg: String) -> void:
	print(msg)
	var f = FileAccess.open(LOG_PATH, FileAccess.READ_WRITE)
	if not f: f = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if f:
		f.seek_end()
		f.store_line(msg)

func _init():
	var f = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if f: f.store_line("Starting Adjacency Test")
	
	# Load MapController script to access RoomCard class and static/instance logic
	# Using instance from root if available, else instantiate
	var mc = get_root().get_node("/root/MapController")
	if not mc:
		_log("FAIL: MapController missing")
		quit()
		return

	# Helper to make cards
	var make_card = func(type):
		return mc._create_card(type)
		
	# Test Case 1: [EVENT, TREASURE, COMBAT]
	var d1 = [make_card.call("EVENT"), make_card.call("TREASURE"), make_card.call("COMBAT")]
	_log("Test 1 Initial: " + _deck_str(d1))
	
	mc.fix_adjacency(d1)
	
	_log("Test 1 Result: " + _deck_str(d1))
	if d1[1].type == "COMBAT" and d1[2].type == "TREASURE":
		_log("PASS: Test 1 Fixed")
	else:
		_log("FAIL: Test 1 Failed")

	# Test Case 2: [TREASURE, EVENT, COMBAT]
	var d2 = [make_card.call("TREASURE"), make_card.call("EVENT"), make_card.call("COMBAT")]
	_log("Test 2 Initial: " + _deck_str(d2))
	
	mc.fix_adjacency(d2)
	
	_log("Test 2 Result: " + _deck_str(d2))
	if d2[1].type == "COMBAT" and d2[2].type == "EVENT":
		_log("PASS: Test 2 Fixed")
	else:
		_log("FAIL: Test 2 Failed")
		
	# Test Case 3: No Swaps Needed [E, C, T]
	var d3 = [make_card.call("EVENT"), make_card.call("COMBAT"), make_card.call("TREASURE")]
	var copy_order = _deck_str(d3)
	mc.fix_adjacency(d3)
	if _deck_str(d3) == copy_order:
		_log("PASS: Test 3 Clean")
	else:
		_log("FAIL: Test 3 Modified Unnecessarily")

	quit()

func _deck_str(arr: Array) -> String:
	var s = "["
	for c in arr:
		s += c.type.substr(0,1) + ", "
	return s + "]"
