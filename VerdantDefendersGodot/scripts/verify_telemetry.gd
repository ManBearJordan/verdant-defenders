extends SceneTree

func _init():
	print("Running Telemetry Verification...")
	
	# Access TelemetrySystem (Autoload)
	var ts = get_root().get_node_or_null("TelemetrySystem")
	if not ts:
		print("ERROR: TelemetrySystem Autoload NOT found.")
		quit()
		return
		
	print("TelemetrySystem Found.")
	
	# Simulate Run
	ts.start_new_run("growth", 1)
	
	# Simulate Combat Log
	ts.log_combat_entry({
		"fight_id": "sim_fight_01",
		"enemy": "Simulator Bot",
		"turns": 5,
		"hp_loss": 10
	})
	
	# Simulate Card Log
	ts.log_card_usage({
		"card_id": "g_vine_whip",
		"cost": 1,
		"turn": 1
	})
	
	# Finalize
	ts.finalize_run("victory")
	
	var out_path = "res://telemetry_verification.txt"
	var f = FileAccess.open(out_path, FileAccess.WRITE)
	
	var dir = DirAccess.open("user://run_logs")
	if dir:
		dir.list_dir_begin()
		var file = dir.get_next()
		var found_summary = false
		var found_combat = false
		var found_card = false
		
		while file != "":
			if file.begins_with("run_summary_"): found_summary = true
			if file == "combat_log.jsonl": found_combat = true
			if file == "card_usage.jsonl": found_card = true
			file = dir.get_next()
			
		if f:
			f.store_string("Telemetry Verification Results\n")
			if found_summary: f.store_string("PASS: Run Summary created.\n")
			else: f.store_string("FAIL: Run Summary missing.\n")
			
			if found_combat: f.store_string("PASS: Combat Log created.\n")
			else: f.store_string("FAIL: Combat Log missing.\n")
			
			if found_card: f.store_string("PASS: Card Usage Log created.\n")
			else: f.store_string("FAIL: Card Usage Log missing.\n")
			f.close()
			print("Saved verification to " + out_path)
	else:
		if f:
			f.store_string("FAIL: Could not open user://run_logs\n")
			f.close()
		print("FAIL: Could not open user://run_logs")
		
	quit()
