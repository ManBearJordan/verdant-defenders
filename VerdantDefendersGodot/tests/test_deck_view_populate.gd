extends SceneTree

# Test Deck View Population and Upgrade

const LOG_PATH = "user://test_deck_view_populate.log"

func _log(msg: String) -> void:
	print(msg)
	var f = FileAccess.open(LOG_PATH, FileAccess.READ_WRITE)
	if not f: f = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if f:
		f.seek_end()
		f.store_line(msg)

func _init():
	var f = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if f: f.store_line("Starting Deck View Test")
	
	var rc = get_root().get_node("/root/RunController")
	var dl = get_root().get_node("/root/DataLayer")
	
	if not rc or not dl:
		_log("FAIL: Autoloads missing")
		quit()
		return
		
	# 1. Start Run
	rc.start_new_run("Growth")
	await create_timer(0.2).timeout
	
	# Verify Deck IDs
	if rc.deck.size() == 0:
		_log("FAIL: Deck empty")
	else:
		_log("Deck Size: " + str(rc.deck.size()))
		for id in rc.deck:
			var res = dl.get_card(id)
			if res:
				# _log("Card Loaded: " + id)
				pass
			else:
				_log("FAIL: DataLayer return null for " + id)
				
	# 2. Simulate DeckView
	var view_scn = load("res://Scenes/UI/Deck/DeckViewScreen.tscn")
	var view_inst = view_scn.instantiate()
	get_root().add_child(view_inst)
	view_inst.setup("view")
	await create_timer(0.1).timeout # wait for deferred populate
	
	# Verify Children
	if not view_inst.grid:
		_log("FAIL: Grid missing")
	else:
		var count = view_inst.grid.get_child_count()
		# There should be children equal to deck size
		if count == rc.deck.size():
			_log("PASS: Grid count matches deck")
		else:
			_log("FAIL: Grid count %d != Deck %d" % [count, rc.deck.size()])
			
	# 3. Test Upgrade Logic
	# card_id "thorn_lash" should exist.
	# It likely has no upgrade_id set yet.
	_log("Attempting Upgrade: thorn_lash")
	rc.upgrade_card("thorn_lash")
	# We expect log output "Card has no upgrade defined" in console, but here we just check we didn't crash.
	_log("Upgrade call complete (Check console/log for result)")
	
	quit()
