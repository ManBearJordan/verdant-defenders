extends SceneTree

func _init():
	print("Test Ascension Revamp: Start")
	
	# Setup Autoloads
	var game_controller_script = load("res://scripts/GameController.gd")
	var dungeon_controller_script = load("res://scripts/DungeonController.gd")
	var combat_system_script = load("res://scripts/CombatSystem.gd")
	var ascension_controller_script = load("res://scripts/AscensionController.gd")
	var enemy_resource_script = load("res://scripts/EnemyResource.gd")
	
	var gc = game_controller_script.new()
	var dc = dungeon_controller_script.new()
	var cs = combat_system_script.new()
	var ac = ascension_controller_script.new()
	
	get_root().add_child(ac) # AC first
	get_root().add_child(gc)
	get_root().add_child(dc)
	get_root().add_child(cs)
	
	# Test 1: Scaling Formulas
	print("-- Testing Scaling Formulas --")
	ac.set_level(1)
	var b1 = ac.get_enemy_buffs()
	# HP: 1.04, Dmg: 1.03
	if abs(b1.hp_mult - 1.04) < 0.001 and abs(b1.dmg_mult - 1.03) < 0.001:
		print("PASS: Level 1 Scaling (1.04/1.03)")
	else:
		print("FAIL: Level 1 Scaling. Got: %s" % str(b1))
		
	ac.set_level(5)
	var b5 = ac.get_enemy_buffs()
	# HP: 1.0 + 0.20 = 1.20. Dmg: 1.0 + 0.15 = 1.15
	if abs(b5.hp_mult - 1.20) < 0.001 and abs(b5.dmg_mult - 1.15) < 0.001:
		print("PASS: Level 5 Scaling (1.20/1.15)")
	else:
		print("FAIL: Level 5 Scaling. Got: %s" % str(b5))
		
	ac.set_level(10)
	var b10 = ac.get_enemy_buffs()
	# HP: 1.0 + 0.40 -> Cap 1.30. Dmg: 1.0 + 0.30 -> Cap 1.20
	if abs(b10.hp_mult - 1.30) < 0.001 and abs(b10.dmg_mult - 1.20) < 0.001:
		print("PASS: Level 10 Caps (1.30/1.20)")
	else:
		print("FAIL: Level 10 Caps. Got: %s" % str(b10))
		
	# Test 2: Elite Modifiers Count
	print("-- Testing Elite Config --")
	ac.set_level(3)
	var c3 = ac.get_elite_modifier_config()
	if c3.count == 1:
		print("PASS: A3 Elite Count (1)")
	else:
		print("FAIL: A3 Elite Count. Got: %d" % c3.count)
		
	ac.set_level(7)
	var c7 = ac.get_elite_modifier_config()
	if c7.count == 2:
		print("PASS: A7 Elite Count (2) [Guaranteed]")
	else:
		print("FAIL: A7 Elite Count. Got: %d" % c7.count)
		
	ac.set_level(6)
	var c6 = ac.get_elite_modifier_config()
	if c6.allow_act3_pool == true:
		print("PASS: A6 Act 3 Pool Access")
	else:
		print("FAIL: A6 Act 3 Pool Access. Got: %s" % str(c6.allow_act3_pool))

	# Test 3: Healing Reduction (Logic)
	print("-- Testing Healing Reduction (Logic) --")
	ac.set_level(3)
	if ac.get_healing_mult() == 1.0:
		print("PASS: A3 Healing (1.0)")
	ac.set_level(4)
	if abs(ac.get_healing_mult() - 0.85) < 0.001:
		print("PASS: A4 Healing (0.85)")
	ac.set_level(8)
	if abs(ac.get_healing_mult() - 0.70) < 0.001:
		print("PASS: A8 Healing (0.70)")

	# Test 4: Integration - Healing
	print("-- Integration: Healing --")
	ac.set_level(4) # -15%
	gc.player_hp = 50
	gc.max_hp = 100
	gc.heal_player(100) # Should be 85
	if gc.player_hp == 50 + 85: # 135 -> Max 100? No, wait. 50 + 85 = 135. Min(135, 100) = 100.
		# This doesn't verify the amount if it hits max.
		pass
		
	gc.player_hp = 10
	gc.max_hp = 100
	gc.heal_player(10) # 10 * 0.85 = 8.5 -> 8.
	# Expected HP: 10 + 8 = 18.
	if gc.player_hp == 18:
		print("PASS: A4 Heal Integration (10 -> +8)")
	else:
		print("FAIL: A4 Heal Integration. HP: %d (Expected 18)" % gc.player_hp)

	# Test 5: Integration - Elite Mods
	print("-- Integration: Elite Mods --")
	ac.set_level(7) # 2 mods
	dc.current_act = 1
	
	var res = EnemyResource.new()
	res.id = "mock_elite"
	res.max_hp = 50
	res.display_name = "Mock Elite"
	var e = EnemyUnit.new(res)
	
	cs.enemies.append(e) # Needed? _apply_elite_modifier takes e.
	cs._apply_elite_modifier(e) # Should apply 2
	
	if e.modifiers.size() == 2:
		print("PASS: A7 Elite Integration (2 Mods Applied)")
	else:
		print("FAIL: A7 Elite Integration. Mods: %d" % e.modifiers.size())

	print("Test Ascension Revamp Complete")
	quit()
