extends SceneTree

# Test Event Logic verification

const LOG_PATH = "user://test_event.log"

func _log(msg: String) -> void:
	print(msg)
	var f = FileAccess.open(LOG_PATH, FileAccess.READ_WRITE)
	if not f: f = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if f:
		f.seek_end()
		f.store_line(msg)

func _init():
	var f = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if f: f.store_line("Starting Event Logic Test")
	
	print("Test: Event Logic")
	
	var rc = get_root().get_node("/root/RunController")
	var ec = get_root().get_node("/root/EventController")
	
	if not rc or not ec:
		_log("FAIL: Systems missing")
		quit()
		return
		
	rc.start_new_run("growth")
	await create_timer(0.5).timeout
	
	# Setup specific event manually to test logic
	var test_event = {
		"id": "test_event",
		"title": "Test Chamber",
		"text": "Choose your fate.",
		"choices": [
			{
				"text": "Gain Gold",
				"outcome": { "type": "resource", "resource": "shards", "amount": 50 }
			},
			{
				"text": "Lose HP",
				"outcome": { "cost_hp": 10, "type": "none" }
			}
		]
	}
	
	# Override current event directly
	ec._current_event = test_event
	
	# Test Choice 0: Gain 50 Shards
	rc.shards = 0
	_log("Action: Choose Shards (Index 0)")
	ec.select_choice(0)
	
	if rc.shards != 50:
		_log("FAIL: Shards not gained. Expected 50, Got %d" % rc.shards)
	else:
		_log("Choice 0 SUCCESS")
		
	# Reset and Test Choice 1: Lose 10 HP
	ec._current_event = test_event # Reload event as select_choice clears it
	rc.player_hp = 50
	_log("Action: Choose Pain (Index 1)")
	ec.select_choice(1)
	
	if rc.player_hp != 40:
		_log("FAIL: HP not reduced. Expected 40, Got %d" % rc.player_hp)
	else:
		_log("Choice 1 SUCCESS")
		
	_log("TEST COMPLETE: Event Logic Verified")
	quit()
