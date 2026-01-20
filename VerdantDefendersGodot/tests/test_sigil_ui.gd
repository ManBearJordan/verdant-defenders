extends SceneTree

const LOG_PATH = "user://test_sigil_ui.log"

func _log(msg: String) -> void:
	print(msg)
	var f = FileAccess.open(LOG_PATH, FileAccess.READ_WRITE)
	if not f: f = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if f:
		f.seek_end()
		f.store_line(msg)

func _init():
	var f = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if f: f.store_line("Starting Sigil UI Test")
	
	# Manually load dependencies
	var rc_script = load("res://scripts/RunController.gd")
	var rc = rc_script.new()
	get_root().add_child(rc)
	
	var ss_script = load("res://scripts/SigilSystem.gd")
	var ss = ss_script.new()
	get_root().add_child(ss)
	
	var dl_script = load("res://scripts/DataLayer.gd")
	var dl = dl_script.new()
	get_root().add_child(dl)
	dl.load_all()
	
	# Mock UI
	var player_hud_scene = load("res://Scenes/PlayerHUD.tscn")
	var hud = player_hud_scene.instantiate()
	get_root().add_child(hud)
	
	# Wait for ready?
	
	# Test Add Sigil
	rc.add_sigil("ember_shard") # Provided in JSON
	
	# Check SS
	var active = ss.get_active_sigils()
	if active.size() > 0 and active[0].id == "ember_shard":
		_log("PASS: SigilSystem received sigil")
		
		# Check UI - SigilBar is inside HUD/VBox/SigilContainer
		# Path: HUD/Margin/VBox/SigilContainer (See PlayerHUD.tscn)
		var bar = hud.find_child("SigilContainer")
		if bar:
			# Slots are private _slots, but we can check children of slots
			# Wait, slots are added as children of Bar.
			# But SigilBar adds slots in _ready.
			# Since we instantiated it, _ready runs.
			
			# We need to wait a frame for signal propagation? 
			# In headless script, signals are immediate usually.
			
			var slot0 = bar.get_child(1) # Child 0 is Title. Slots follow.
			# Title is added first.
			if slot0:
				if slot0.get_child_count() > 0:
					var icon = slot0.get_child(0)
					if icon.name == "Icon":
						_log("PASS: SigilIcon instantiated in SigilBar")
						if icon.description != "":
							_log("PASS: Sigil tooltip populated")
						else:
							_log("WARN: Sigil tooltip empty")
					else:
						_log("FAIL: Slot child is not Icon? " + icon.name)
				else:
					_log("FAIL: Slot 0 empty")
			else:
				_log("FAIL: Slot 0 not found")
		else:
			_log("FAIL: SigilContainer not found in HUD")
			
	else:
		_log("FAIL: SigilSystem did not receive sigil")

	quit()
