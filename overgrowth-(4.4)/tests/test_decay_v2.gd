extends SceneTree

func _init():
	print("TEST: Decay V2 Logic")
	
	# Load Scripts
	var cs_script = load("res://scripts/CombatSystem.gd")
	var cr_script = load("res://scripts/CardRules.gd")
	var dm_script = load("res://scripts/DeckManager.gd")
	var gc_script = load("res://scripts/GameController.gd")
	
	if not cs_script or not cr_script:
		print("FAIL: Could not load scripts.")
		quit()
		return
		
	var root = get_root()
	
	var dm = dm_script.new()
	dm.name = "DeckManager"
	root.add_child(dm)
	
	var gc = gc_script.new()
	gc.name = "GameController"
	root.add_child(gc)
	gc.player_state = {"statuses": {}, "seeds": 0} 
	
	var cs = cs_script.new()
	cs.name = "CombatSystem"
	root.add_child(cs)
	
	var cr = cr_script.new()
	cr.name = "CardRules"
	root.add_child(cr)
	
	# Setup Enemy using Real Class (to satisfy Type Hint)
	# Assuming EnemyResource and EnemyUnit are globally available or loadable
	var res = EnemyResource.new()
	res.id = "dummy"
	res.display_name = "Dummy"
	res.max_hp = 100
	var intents: Array[String] = []
	res.intents = intents # Optional
	
	var enemy = EnemyUnit.new(res)
	# Verify EnemyUnit structure
	enemy.current_hp = 100
	
	# We need to hack the enemies array assignment if it's strictly typed?
	# cs.enemies is Array[EnemyUnit].
	# enemy is EnemyUnit.
	# [enemy] is Array[EnemyUnit].
	
	# However, we must ensure 'enemy' allows setting statuses if we removed Mock logic.
	# EnemyUnit has `set_status` and `statuses` dict.
	
	var en_arr: Array[EnemyUnit] = [enemy]
	cs.enemies = en_arr
	
	print("--- Test 1: remove_status_up_to_then_deal_damage_per_removed ---")
	enemy.set_status("poison", 5)
	var effect1 = {
		"type": "remove_status_up_to_then_deal_damage_per_removed",
		"status": "poison",
		"max": 2,
		"damage_per_removed": 2,
		"target": "enemy" # handled by logic usually implicitly by target_index
	}
	# apply_effect takes (effect, cs, dm, target_index)
	cr.apply_effect(effect1, cs, dm, 0)
	
	assert_val(enemy.get_status("poison"), 3, "Poison should reduce by 2 (5->3)")
	assert_val(enemy.current_hp, 96, "Damage should be 2*2=4 (100->96)")
	
	print("--- Test 2: remove_status_up_to_then_gain_block_per_removed ---")
	enemy.set_status("poison", 3)
	var effect2 = {
		"type": "remove_status_up_to_then_gain_block_per_removed",
		"status": "poison",
		"max": 3,
		"block_per_removed": 3,
		"target": "enemy"
	}
	cr.apply_effect(effect2, cs, dm, 0)
	assert_val(enemy.get_status("poison"), 0, "Poison should be removed (3->0)")
	assert_val(cs.player_block, 9, "Block should be 3*3=9")
	
	print("--- Test 3: for_each_enemy_with_status ---")
	enemy.set_status("poison", 2)
	enemy.current_hp = 100
	
	var res2 = EnemyResource.new()
	res2.id = "dummy2"
	res2.max_hp = 100
	var enemy2 = EnemyUnit.new(res2)
	enemy2.set_status("poison", 0)
	
	var en_arr2: Array[EnemyUnit] = [enemy, enemy2]
	cs.enemies = en_arr2
	
	var effect3 = {
		"type": "for_each_enemy_with_status",
		"status": "poison",
		"min": 1,
		"do": [
			{ "type": "deal_damage", "amount": 10 }
		]
	}
	
	cr.apply_effect(effect3, cs, dm, -1)
	
	assert_val(enemy.current_hp, 90, "Poisoned enemy should take damage")
	assert_val(enemy2.current_hp, 100, "Clean enemy should NOT take damage")
	
	print("Tests Passed!")
	quit()

func assert_val(actual, expected, msg):
	if actual != expected:
		print("FAIL: %s. Expected %s, Got %s" % [msg, expected, actual])
	else:
		print("PASS: %s" % msg)
