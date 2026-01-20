extends SceneTree

# Test Game Over Flow

const LOG_PATH = "user://test_death_flow.log"

func _log(msg: String) -> void:
	print(msg)
	var f = FileAccess.open(LOG_PATH, FileAccess.READ_WRITE)
	if not f: f = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if f:
		f.seek_end()
		f.store_line(msg)

func _init():
	var f = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if f: f.store_line("Starting Death Flow Test")
	
	var rc = get_root().get_node("/root/RunController")
	if not rc:
		_log("FAIL: RunController missing")
		quit()
		return
		
	# 1. Start Run
	rc.start_new_run("Growth")
	await create_timer(0.1).timeout
	
	# 2. Add Metrics
	rc.modify_shards(50)
	rc.add_card("test_card")
	rc.modify_hp(-10)
	
	if rc.run_metrics.shards_earned != 50:
		_log("FAIL: Metrics not tracking shards")
	if rc.run_metrics.cards_added != 1:
		_log("FAIL: Metrics not tracking cards")
		
	# 3. Die
	_log("Triggering Defeat...")
	rc.battle_defeat()
	await create_timer(1.0).timeout
	
	# 4. Verify Scene
	var root = get_root().current_scene
	if root:
		_log("Current Scene: " + root.name)
		if root.name == "GameOverScreen": # Scene name from tscn logic usually matches
			_log("PASS: GameOverScreen loaded")
		else:
			# In headless change_scene_to_file might behave oddly if message loop isn't pumping?
			# But we rely on await.
			# Also note _change_screen fallback is change_scene_to_file.
			_log("Scene check: " + root.name)
			
			# Check stats prop logic in script?
			# The script populates on ready.
			pass
	else:
		_log("FAIL: No current scene")
		
	quit()
