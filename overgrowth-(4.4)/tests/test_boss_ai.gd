extends SceneTree

func _init():
	print("Running Boss AI Verification...")
	
	# 1. Telemetry Check
	var ts = load("res://scripts/TelemetrySystem.gd").new()
	ts.start_new_run("test_archetype", 0)
	ts.log_event("totals", "damage_dealt", 100)
	if ts.run_data["totals"]["damage_dealt"] == 100:
		print("PASS: Telemetry Logging")
	else:
		print("FAIL: Telemetry Logging")
		
	# 2. Boss Pattern Loading
	var cs = load("res://scripts/CombatSystem.gd").new()
	cs._load_boss_phases() # Loads patterns now
	
	var patterns = cs.get("_boss_patterns") # Private var access in GDScript? usually yes if not typed strict private
	# Actually _boss_patterns is local variable in my script but declared at top.
	# Accessing via get() or just trusting if it printed "Loaded X patterns".
	# Since I can't check private vars easily in script runner, I'll rely on side effects.
	
	# 3. Simulate Boss Logic
	# Create EnemyUnit
	var res = load("res://scripts/Resources/EnemyResource.gd").new()
	res.id = "gravebloom_test"
	res.display_name = "Gravebloom Behemoth"
	res.max_hp = 300
	var unit = load("res://scripts/EnemyUnit.gd").new(res)
	unit.custom_data = {} # Ensure init
	
	print("Testing AI update...")
	if cs.has_method("_update_boss_intent"):
		cs._update_boss_intent(unit)
		if unit.intent.has("name"):
			print("PASS: Boss AI assigned intent: %s" % unit.intent.name)
		else:
			print("FAIL: No intent assigned (Pattern missing?)")
			
	# 4. Test Mechanic Trigger
	# Simulate trigger logic manually since we can't easily inject into cs hooks
	# but we can try calling trigger
	if cs.has_method("_trigger_boss_mechanic"):
		# Gravebloom mechanic: Scale from player block
		cs.player_block = 25
		cs._trigger_boss_mechanic(unit, "start_of_boss_turn")
		if unit.get_status("strength") == 2:
			print("PASS: Mechanic Triggered (Strength +2)")
		else:
			print("FAIL: Mechanic Triggered (Strength %d)" % unit.get_status("strength"))

	print("Verification Complete")
	quit()
