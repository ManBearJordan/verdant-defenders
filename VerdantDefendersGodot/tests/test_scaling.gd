extends SceneTree

func _init():
	print("Starting Scaling Test...")
	var root = get_root()
	
	# Fetch Autoloads (They should exist in standard run, but maybe not in bare script unless project settings load them)
	# If running --script, Autoloads might load if they are enabled in ProjectSettings.
	
	var dc = root.get_node_or_null("DungeonController")
	if not dc:
		# If not autoloaded, creating one is fine.
		dc = load("res://scripts/DungeonController.gd").new()
		dc.name = "DungeonController"
		root.add_child(dc)
	
	var cs = root.get_node_or_null("CombatSystem")
	if not cs:
		cs = load("res://scripts/CombatSystem.gd").new()
		cs.name = "CombatSystem"
		root.add_child(cs)
		
	print("Using DC: ", dc)
	print("Using CS: ", cs)
	
	# Create a Dummy Enemy Resource
	var res = EnemyResource.new()
	res.id = "test_dummy"
	res.max_hp = 100
	res.intents = ["Attack 10"]
	
	# -------------------------------------------------------------------------
	# Test Act 1 (Baseline)
	# -------------------------------------------------------------------------
	print("Testing Act 1...")
	dc.current_act = 1
	dc.current_layer = 0
	cs.begin_encounter([res])
	
	var e1 = cs.enemies[0]
	if e1.max_hp != 100:
		print("FAIL: Act 1 HP should be 100, got %d" % e1.max_hp)
		quit(1)
		return
		
	e1.update_intent(0)
	if e1.intent.value != 10:
		print("FAIL: Act 1 Dmg should be 10, got %d" % e1.intent.value)
		quit(1)
		return

	# -------------------------------------------------------------------------
	# Test Act 2 (1.35x)
	# -------------------------------------------------------------------------
	print("Testing Act 2...")
	dc.current_act = 2
	dc.current_layer = 0
	cs.begin_encounter([res])
	
	var e2 = cs.enemies[0]
	if e2.max_hp != 135:
		print("FAIL: Act 2 HP should be 135, got %d" % e2.max_hp)
		quit(1)
		return
		
	e2.update_intent(0)
	if e2.intent.value != 14: # 13.5 -> 14
		print("FAIL: Act 2 Dmg should be 14, got %d" % e2.intent.value)
		quit(1)
		return

	# -------------------------------------------------------------------------
	# Test Act 3 Depth 10 (1.70 * 1.2 = 2.04)
	# -------------------------------------------------------------------------
	print("Testing Act 3 Depth 10...")
	dc.current_act = 3
	dc.current_layer = 10
	cs.begin_encounter([res])
	
	var e3 = cs.enemies[0]
	if e3.max_hp != 204:
		print("FAIL: Act 3 Deep HP should be 204, got %d" % e3.max_hp)
		quit(1)
		return
	
	e3.update_intent(0)
	if e3.intent.value != 20: # 20.4 -> 20
		print("FAIL: Act 3 Deep Dmg should be 20, got %d" % e3.intent.value)
		quit(1)
		return

	print("PASS: Scaling Logic Verified")
	quit(0)
