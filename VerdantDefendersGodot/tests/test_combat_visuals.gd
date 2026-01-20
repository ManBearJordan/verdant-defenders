extends SceneTree

const LOG_PATH = "user://test_combat_visuals.log"

class MockResource:
	var texture_path = "res://icon.svg"
	var intents = []
	var id = "mock_enemy"
	var display_name = "Mock Enemy"

class MockUnit:
	signal intent_updated()
	signal hp_changed(c, m)
	signal status_changed()
	
	var display_name = "Test Unit"
	var id = "test_unit"
	var current_hp = 100
	var max_hp = 100
	var intent = {}
	var statuses = {}
	var resource = null 
	
	func is_dead(): return false

func _log(msg: String) -> void:
	print(msg)
	var f = FileAccess.open(LOG_PATH, FileAccess.READ_WRITE)
	if not f: f = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if f:
		f.seek_end()
		f.store_line(msg)

func _init():
	var f = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if f: f.store_line("Starting Combat Visuals Test")

	var rc = get_root().get_node("/root/RunController")
	var ss = get_root().get_node("/root/SigilSystem")
	
	if not rc or not ss:
		_log("FAIL: Autoloads missing")
		quit()
		return

	# 1. Test Sigil Sync
	_log("Testing Sigil Sync...")
	rc.start_new_run("growth")
	await create_timer(0.1).timeout
	
	rc.add_sigil("ember_shard") 
	
	if ss.has_sigil("ember_shard"):
		_log("PASS: SigilSystem received ember_shard")
	else:
		_log("FAIL: SigilSystem missing ember_shard")
		
	# 2. Test Sigil UI
	var hud_scene = load("res://Scenes/PlayerHUD.tscn")
	var hud = hud_scene.instantiate()
	get_root().add_child(hud)
	await create_timer(0.2).timeout
	
	var sigil_container = hud.find_child("SigilContainer")
	if sigil_container:
		if sigil_container.has_method("_refresh_all"):
			sigil_container._refresh_all()
			
		var slots = sigil_container._slots
		var found_icon = false
		for s in slots:
			if s.get_node_or_null("Icon"):
				found_icon = true
				var icon = s.get_node("Icon")
				if "Ember Shard" in icon.tooltip_text:
					_log("PASS: Found Sigil Icon with correct tooltip")
				else:
					_log("FAIL: Tooltip mismatch: " + icon.tooltip_text)
				break
		if not found_icon:
			_log("FAIL: No icons found in SigilBar")
	else:
		_log("FAIL: SigilContainer not found in HUD")
		
	# 3. Test Intent Tooltip
	_log("Testing Intent Tooltip...")
	var ev_scene = load("res://Scenes/EnemyView.tscn")
	var ev = ev_scene.instantiate()
	get_root().add_child(ev)
	
	var e_unit = MockUnit.new()
	e_unit.resource = MockResource.new()
	e_unit.intent = {"type": "attack", "value": 15}
	
	ev.setup(e_unit)
	await create_timer(0.1).timeout
	
	var icon = ev.get_node("%IntentIcon")
	if icon:
		var txt = icon.tooltip_text
		if "Attack for 15 damage" in txt:
			_log("PASS: Action tooltip verified: " + txt)
		else:
			_log("FAIL: Tooltip text incorrect: " + str(txt))
	else:
		_log("FAIL: Intent Icon missing")
		
	quit()
