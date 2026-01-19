extends SceneTree

func _init():
	var file = FileAccess.open("res://boss_verification.txt", FileAccess.WRITE)
	file.store_line("--- Boss Mechanics Verification ---")
	
	# Mock GC
	var gc_script = GDScript.new()
	gc_script.source_code = "extends Node\nvar player_state = {'seeds': 0, 'statuses': {}}"
	if gc_script.reload() != OK:
		file.store_line("FAIL: Mock GC Script Error")
		quit(1)
		return
	var gc = Node.new()
	gc.set_script(gc_script)
	gc.name = "GameController"
	root.add_child(gc)
	
	# Load CombatSystem
	var cs_script = load("res://scripts/CombatSystem.gd")
	var cs = Node.new()
	cs.set_script(cs_script)
	root.add_child(cs)
	
	# 1. Withering Sentinel (Growth)
	file.store_line("[Withering Sentinel]")
	var growth_res = load("res://scripts/Resources/EnemyResource.gd").new()
	growth_res.id = "boss_growth"
	growth_res.display_name = "Withering Sentinel"
	growth_res.max_hp = 100
	# Removed invalid assignment to current_hp on resource
	growth_res.archetype_counter = "growth"
	
	var growth_unit = load("res://scripts/EnemyUnit.gd").new(growth_res)
	cs.enemies.append(growth_unit)
	
	# Test Base Damage (0 seeds)
	gc.player_state.seeds = 0
	cs.damage_enemy(0, 10)
	var dmg_taken = 100 - growth_unit.current_hp
	file.store_line("  0 Seeds -> dmg taken: %d (Expected 10)" % dmg_taken)
	
	# Test Seed Scaling (5 seeds)
	growth_unit.current_hp = 100
	gc.player_state.seeds = 5
	cs.damage_enemy(0, 10)
	dmg_taken = 100 - growth_unit.current_hp
	file.store_line("  5 Seeds -> dmg taken: %d (Expected 15)" % dmg_taken)
	
	# 2. Purifier Construct (Decay)
	file.store_line("[Purifier Construct]")
	var decay_res = load("res://scripts/Resources/EnemyResource.gd").new()
	decay_res.id = "boss_decay"
	decay_res.archetype_counter = "decay"
	decay_res.max_hp = 100
	
	var decay_unit = load("res://scripts/EnemyUnit.gd").new(decay_res)
	cs.enemies = [decay_unit] # Replace list
	
	# Apply Poison
	decay_unit.set_status("poison", 10)
	file.store_line("  Start Poison: %d" % decay_unit.get_status("poison"))
	
	# Simulate turns
	cs.turn = 0 # Turn 1 (next)
	cs.enemy_turn() # Turn becomes 1. (1+1)%4 != 0
	file.store_line("  Turn 1 Poison: %d" % decay_unit.get_status("poison"))
	
	cs.turn = 2 # Set to 2 -> next is 3
	cs.enemy_turn() # Turn becomes 3.
	
	cs.turn = 3 # Set to 3 -> next is 4 (Cleanse)
	cs.enemy_turn() 
	file.store_line("  Turn 4 Poison: %d (Expected 0)" % decay_unit.get_status("poison"))
	
	# 3. Bulwark Colossus (Elemental)
	file.store_line("[Bulwark Colossus]")
	var elem_res = load("res://scripts/Resources/EnemyResource.gd").new()
	elem_res.id = "boss_elem"
	elem_res.archetype_counter = "elemental"
	elem_res.max_hp = 100
	elem_res.defense = 0
	
	var elem_unit = load("res://scripts/EnemyUnit.gd").new(elem_res)
	elem_unit.block = 0
	cs.enemies = [elem_unit]
	
	# Hit 1
	cs.damage_enemy(0, 1)
	file.store_line("  Hit 1 Block: %d" % elem_unit.block)
	
	# Hit 2
	cs.damage_enemy(0, 1)
	file.store_line("  Hit 2 Block: %d" % elem_unit.block)
	
	# Hit 3
	cs.damage_enemy(0, 1)
	file.store_line("  Hit 3 Block: %d" % elem_unit.block)
	
	# Hit 4 (Refresh!)
	cs.damage_enemy(0, 1)
	file.store_line("  Hit 4 Block: %d (Expected 20)" % elem_unit.block)
	
	file.store_line("--- DONE ---")
	file.close()
	quit(0)
