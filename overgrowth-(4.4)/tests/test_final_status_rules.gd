extends "res://addons/gut/test.gd"

var CombatSystem
var GameController
var EnemyUnit = load("res://scripts/EnemyUnit.gd")
var EnemyResource = load("res://scripts/EnemyResource.gd")

func before_each():
	CombatSystem = get_node_or_null("/root/CombatSystem")
	GameController = get_node_or_null("/root/GameController")
	# Reset Combat
	CombatSystem.enemies.clear()
	CombatSystem.player_block = 0
	CombatSystem.turn = 0
	GameController.player_hp = 80

func test_fragile_damage_multiplier():
	var res = EnemyResource.new()
	res.id = "test_dummy"
	res.max_hp = 100
	var unit = EnemyUnit.new(res)
	unit.current_hp = 100
	CombatSystem.enemies.append(unit)
	
	unit.set_status("fragile", 1)
	
	# Deal 10 damage -> Should be 15
	CombatSystem.damage_enemy(0, 10)
	assert_eq(unit.current_hp, 85, "Fragile should increase damage by 50% (10 -> 15)")

func test_sap_damage_reduction():
	var res = EnemyResource.new()
	res.id = "sappy_enemy"
	res.max_hp = 100
	var unit = EnemyUnit.new(res)
	unit.intent = {"type": "attack", "value": 20}
	unit.set_status("sap", 1)
	CombatSystem.enemies.append(unit)
	
	# Execute turn
	CombatSystem.enemy_turn()
	
	# Player took damage?
	# 80 - (20 * 0.75 = 15) = 65
	assert_eq(GameController.player_hp, 65, "Sap should reduce damage by 25% (20 -> 15)")

func test_chill_stacking_and_cap():
	var res = EnemyResource.new()
	res.id = "chilled_enemy"
	res.max_hp = 100
	var unit = EnemyUnit.new(res)
	unit.intent = {"type": "attack", "value": 20}
	
	CombatSystem.enemies.append(unit)
	
	# Case 1: 1 stack = 10%
	unit.set_status("chill", 1)
	CombatSystem.enemy_turn() # Attack 20 -> 18
	assert_eq(GameController.player_hp, 62, "1 Chill should reduce by 10% (20 -> 18)") # 80 -> 62
	
	# Reset HP
	GameController.player_hp = 80
	# Case 2: 5 stacks = 40% cap (not 50%)
	unit.set_status("chill", 5)
	
	# Manually reset intent if needed (enemy_turn updates it)
	unit.intent = {"type": "attack", "value": 20} 
	
	CombatSystem.enemy_turn() # Attack 20 -> 12 (40% red)
	assert_eq(GameController.player_hp, 68, "5 Chill should cap at 40% reduction (20 -> 12)") # 80 -> 68

func test_poison_burn_persistence_and_damage():
	var res = EnemyResource.new()
	res.id = "dot_dummy"
	res.max_hp = 100
	var unit = EnemyUnit.new(res)
	unit.current_hp = 100
	CombatSystem.enemies.append(unit)
	
	unit.set_status("poison", 5)
	unit.set_status("burn", 3)
	
	# Trigger EOT Effects
	CombatSystem.process_turn_end_effects()
	
	# Poison: 5 dmg, Burn: 3*2 = 6 dmg. Total 11. HP -> 89.
	assert_eq(unit.current_hp, 89, "Poison(5)+Burn(3->6) should deal 11 damage")
	
	# Check Persistence (Should NOT decay)
	assert_eq(unit.get_status("poison"), 5, "Poison should persist (count 5)")
	assert_eq(unit.get_status("burn"), 3, "Burn should persist (count 3)")

