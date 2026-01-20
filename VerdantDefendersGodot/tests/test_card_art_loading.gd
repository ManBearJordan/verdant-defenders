extends SceneTree

const LOG_PATH = "user://test_card_art.log"

func _log(msg: String) -> void:
	print(msg)
	var f = FileAccess.open(LOG_PATH, FileAccess.READ_WRITE)
	if not f: f = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if f:
		f.seek_end()
		f.store_line(msg)

func _init():
	var f = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if f: f.store_line("Starting Card Art Test")
	
	var dl_script = load("res://scripts/DataLayer.gd")
	var dl = dl_script.new()
	# DataLayer uses _ready to load_all. Since we are not adding to tree, we must call it manually.
	dl.load_all()
	
	if not dl:
		_log("FAIL: DataLayer missing")
		quit()
		return

	# Load Vine Whip
	var card_id = "g_vine_whip"
	var card_res = dl.get_card(card_id)
	
	if not card_res:
		_log("FAIL: Could not load " + card_id)
		quit()
		return
		
	_log("Loaded " + card_id)
	
	# Verify art_path property exists and is set
	if "art_path" in card_res:
		_log("PASS: art_path property exists")
		_log("art_path value: " + str(card_res.art_path))
		
		# Verify loading logic matches DeckViewScreen
		if card_res.art_path != "":
			if ResourceLoader.exists(card_res.art_path):
				var tex = load(card_res.art_path)
				if tex:
					_log("PASS: Texture loaded successfully")
					_log("Texture Size: " + str(tex.get_size()))
				else:
					_log("FAIL: load() returned null")
			else:
				_log("FAIL: ResourceLoader says path does not exist")
		else:
			_log("FAIL: art_path is empty (update failed?)")
			
	else:
		_log("FAIL: art_path property missing on resource script")
		
	# Verify Cache
	# Note: cache is populated in _register_card which happens on ready/load.
	# We might need to ensure DataLayer re-registered if we updated script?
	# But script update requires restart usually.
	# However, godot command line run presumably reloads scripts.
	
	if "card_art_cache" in dl:
		_log("PASS: card_art_cache exists in DataLayer")
		if dl.card_art_cache.has(card_id):
			_log("PASS: Cache has entry for " + card_id)
			_log("Cache Value: " + str(dl.card_art_cache[card_id]))
		else:
			_log("WARN: Cache missing entry (maybe registration happened before cache logic added?)")
	else:
		_log("FAIL: card_art_cache missing in DataLayer")

	quit()
