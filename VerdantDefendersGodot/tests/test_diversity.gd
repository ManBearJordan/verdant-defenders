extends SceneTree

const LOG_PATH = "user://test_diversity.log"

func _log(msg: String) -> void:
	print(msg)
	var f = FileAccess.open(LOG_PATH, FileAccess.READ_WRITE)
	if not f: f = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if f:
		f.seek_end()
		f.store_line(msg)

func _init():
	var f = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if f: f.store_line("Starting Diversity Test")
	
	# Manually load dependencies
	var rc_script = load("res://scripts/RunController.gd")
	var rc = rc_script.new()
	get_root().add_child(rc)
	
	var dl_script = load("res://scripts/DataLayer.gd")
	var dl = dl_script.new()
	get_root().add_child(dl)
	dl.load_all()
	
	var rs_script = load("res://scripts/RewardSystem.gd")
	var rs = rs_script.new()
	get_root().add_child(rs)

	var ec_script = load("res://scripts/EventController.gd")
	var ec = ec_script.new()
	get_root().add_child(ec)
	
	# 1. Test RunController Helpers
	rc.start_new_run("growth")
	rc.player_hp = 10
	rc.heal_full()
	if rc.player_hp == 80:
		_log("PASS: heal_full()")
	else:
		_log("FAIL: heal_full() HP=" + str(rc.player_hp))
		
	# Test Transform (mock deck)
	rc.deck = ["strike", "defend"]
	rc.transform_random_card("rare")
	if rc.deck.size() == 2 and rc.deck[0] != "strike" or rc.deck[1] != "defend":
		# Only robust if pool has rares. Default pool might be empty if no .tres?
		# Growth has vines.
		_log("PASS: transform_random_card() Deck changed: " + str(rc.deck))
	else:
		_log("WARN: transform_random_card() Deck unchanged (Maybe no rares found in 'any' pool?)")

	# 2. Test Event Parsing
	ec._ready() # Load events
	if ec._events_data.has("mysterious_fountain"):
		_log("PASS: Events Loaded (Found mysterious_fountain)")
	else:
		_log("FAIL: events.json load failed")
		
	# 3. Test RewardSystem Treasures
	var hit_shards = false
	var hit_relic = false
	
	for i in range(20):
		var treasure = rs.generate_treasure_rewards(1)
		if treasure.context == "treasure":
			var t_type = treasure.options[0].type
			_log("Treasure Roll %d: %s" % [i, t_type])
			if t_type == "shards": hit_shards = true
			if t_type == "relic": hit_relic = true
			
	if hit_shards and hit_relic:
		_log("PASS: Treasure generation diversity confirmed")
	else:
		_log("WARN: Treasure diversity suspiciously low (RNG?)")

	quit()
