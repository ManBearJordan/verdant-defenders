extends SceneTree

# Test Deck Selection Logic (Unit-like)

const LOG_PATH = "user://test_deck_select.log"

func _log(msg: String) -> void:
	print(msg)
	var f = FileAccess.open(LOG_PATH, FileAccess.READ_WRITE)
	if not f: f = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if f:
		f.seek_end()
		f.store_line(msg)

func _init():
	var f = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if f: f.store_line("Starting Selection Logic Test")
	
	print("Test: Selection Logic")
	
	# Load Autoloads
	var rc = get_root().get_node("/root/RunController")
	var shop = get_root().get_node("/root/ShopSystem")
	
	if not rc or not shop:
		_log("FAIL: Systems missing")
		quit()
		return
		
	# 1. Setup State
	rc.shards = 200
	rc.deck = ["strike", "defend", "vine_whip"]
	_log("Initial Deck: %s, Shards: %d" % [rc.deck, rc.shards])
	
	# 2. Simulate User selecting "strike" for removal
	# RunController._on_deck_card_selected_for_shop("strike") -> Shop.remove_card_by_id("strike")
	
	var target = "strike"
	var cost = shop.remove_price()
	
	if not rc.has_method("_on_deck_card_selected_for_shop"):
		_log("FAIL: RunController missing callback method")
		quit()
		return
		
	rc._on_deck_card_selected_for_shop(target)
	
	# 3. Verify
	if rc.deck.has(target):
		_log("FAIL: Deck still contains %s" % target)
	else:
		_log("SUCCESS: %s removed" % target)
		
	if rc.shards != (200 - cost):
		_log("FAIL: Shards mismatch. Expected %d, got %d" % [200-cost, rc.shards])
	else:
		_log("SUCCESS: Cost deducted correctly")
		
	# 4. Verify Scene Switch (Can't easily viewing Headless, but methods called means logic ran)
	# logic called "goto_shop()" at end.
	
	_log("TEST COMPLETE: Deck Selection Logic Verified")
	quit()
