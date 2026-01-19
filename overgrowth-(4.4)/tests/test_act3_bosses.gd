extends SceneTree

func _init():
	print("Starting Act 3 Boss Test...")
	var root = get_root()
	
	# Autoloads
	var dc = root.get_node_or_null("DungeonController")
	if not dc:
		dc = load("res://scripts/DungeonController.gd").new()
		dc.name = "DungeonController"
		root.add_child(dc)
	
	var cs = root.get_node_or_null("CombatSystem")
	if not cs:
		cs = load("res://scripts/CombatSystem.gd").new()
		cs.name = "CombatSystem"
		root.add_child(cs)
		
	var gc = root.get_node_or_null("GameController")
	if not gc:
		gc = load("res://scripts/GameController.gd").new()
		gc.name = "GameController"
		root.add_child(gc)
		
	# Setup Mock GameState
	gc.player_state = {"seeds": 0, "statuses": {}}
	
	# -------------------------------------------------------------------------
	# 1. World Reclaimer (Seed Harvest)
	# -------------------------------------------------------------------------
	print("Testing World Reclaimer...")
	var boss1 = EnemyResource.new()
	boss1.id = "world_reclaimer"
	boss1.display_name = "World Reclaimer"
	boss1.max_hp = 300
	cs.begin_encounter([boss1])
	
	var e1 = cs.enemies[0]
	e1.current_hp = 200 # Injured
	gc.player_state.seeds = 7 # Trigger Amount
	
	# Trigger Logic (Start Turn Check -> mimics end of player turn)
	cs._check_boss_mechanics_start_turn(e1)
	
	if gc.player_state.seeds != 5:
		print("FAIL: Seeds not consumed. Got %d" % gc.player_state.seeds)
		quit(1)
		return
		
	if e1.current_hp != 235: # 200 + 35
		print("FAIL: Boss not healed. Got %d" % e1.current_hp)
		quit(1)
		return
		
	if e1.get_status("strength") != 2:
		print("FAIL: No Strength gain. Got %d" % e1.get_status("strength"))
		quit(1)
		return

	# -------------------------------------------------------------------------
	# 2. Eternal Arbiter (Equilibrium)
	# -------------------------------------------------------------------------
	print("Testing Eternal Arbiter...")
	var boss2 = EnemyResource.new()
	boss2.id = "eternal_arbiter"
	boss2.display_name = "Eternal Arbiter"
	boss2.max_hp = 300
	cs.begin_encounter([boss2])
	
	var e2 = cs.enemies[0]
	e2.set_status("poison", 50) # High poison
	
	# Trigger Poison Tick (process_turn_end_effects)
	cs.process_turn_end_effects()
	
	# HP should drop by exactly 24 (Cap), not 50.
	# 300 - 24 = 276
	if e2.current_hp != 276:
		print("FAIL: Equilibrium Cap failed. HP %d (Expected 276)" % e2.current_hp)
		quit(1)
		return
		
	# -------------------------------------------------------------------------
	# 3. Chronoshard (Logic Check - Echo Tax)
	# -------------------------------------------------------------------------
	print("Testing Chronoshard...")
	var boss3 = EnemyResource.new()
	boss3.id = "chronoshard"
	boss3.display_name = "Chronoshard"
	cs.begin_encounter([boss3])
	
	# Mock GameController state for Echo Tax
	gc.combat_state.cards_played_this_turn = [
		{"name": "Strike"},
		{"name": "Strike"}
	]
	var card = {"name": "Strike", "cost": 0, "id": "strike"}
	
	var cost = gc._calculate_card_cost(card)
	if cost != 1:
		print("FAIL: Echo Tax failed to apply. Cost %d (Expected 1)" % cost)
		quit(1)
		return

	print("PASS: Act 3 Mechanics Verified")
	quit(0)
