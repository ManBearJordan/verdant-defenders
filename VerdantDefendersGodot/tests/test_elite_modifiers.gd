extends SceneTree

func _init():
	print("Test Elite Modifiers: Start")
	
	# Setup Autoloads
	var game_controller_script = load("res://scripts/GameController.gd")
	var dungeon_controller_script = load("res://scripts/DungeonController.gd")
	var combat_system_script = load("res://scripts/CombatSystem.gd")
	var deck_manager_script = load("res://scripts/DeckManager.gd")
	
	var gc = game_controller_script.new()
	var dc = dungeon_controller_script.new()
	var cs = combat_system_script.new()
	var dm = deck_manager_script.new()
	
	get_root().add_child(gc)
	get_root().add_child(dc)
	get_root().add_child(cs)
	get_root().add_child(dm)
	
	# Mock Data
	dc.current_act = 2
	
	# Test 1: Hardened (Act 1)
	var e_res = EnemyResource.new()
	e_res.id = "test_hardened"
	e_res.max_hp = 50
	e_res.display_name = "Test Dummy"
	
	var enemy = EnemyUnit.new(e_res)
	enemy.modifiers.append({"id": "hardened", "name": "Hardened"})
	cs.enemies.append(enemy)
	
	print("Checking Hardened (First Hit -30%)...")
	cs.damage_enemy(0, 10) # 10 -> 7
	if abs(enemy.current_hp - 43) <= 1: # 50 - 7 = 43
		print("PASS: Hardened First Hit (10->7)")
	else:
		print("FAIL: Hardened First Hit. HP: %d (Expected 43)" % enemy.current_hp)
		
	cs.damage_enemy(0, 10) # 10 -> 10 (Second hit normal)
	if abs(enemy.current_hp - 33) <= 1: # 43 - 10 = 33
		print("PASS: Hardened Second Hit (10->10)")
	else:
		print("FAIL: Hardened Second Hit. HP: %d" % enemy.current_hp)

	# Test 2: Seed Scourge (Act 2)
	enemy.modifiers.clear()
	enemy.modifiers.append({"id": "seed_scourge"})
	gc.player_state.seeds = 5
	print("Checking Seed Scourge (Seeds >= 4 -> -1)...")
	cs._check_elite_hooks("eot", enemy)
	if gc.player_state.seeds == 4:
		print("PASS: Seed Scourge removed 1 seed.")
	else:
		print("FAIL: Seed Scourge. Seeds: %d" % gc.player_state.seeds)

	# Test 3: Harvest Leech (Act 3)
	dc.current_act = 3
	enemy.modifiers.clear()
	enemy.modifiers.append({"id": "harvest_leech"})
	enemy.block = 0
	print("Checking Harvest Leech (Gain seeds -> Block)...")
	
	# Trigger via GameController
	gc.add_seeds(1)
	if enemy.block == 3:
		print("PASS: Harvest Leech (+3 Block)")
	else:
		print("FAIL: Harvest Leech. Block: %d" % enemy.block)

	print("Test Elite Modifiers Complete")
	quit()
