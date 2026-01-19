extends SceneTree

func _init():
	var file = FileAccess.open("res://caps_verification.txt", FileAccess.WRITE)
	file.store_line("--- Caps Verification ---")
	
	# Mock GC
	var gc_script = load("res://scripts/GameController.gd")
	var gc = Node.new()
	gc.set_script(gc_script)
	gc.name = "GameController"
	root.add_child(gc)
	
	# Mock DeckManager
	var dm = Node.new()
	dm.name = "DeckManager"
	var dm_script = GDScript.new()
	dm_script.source_code = "extends Node\nvar hand=[]\nvar draw_pile=[]\nvar energy=0\nsignal energy_changed(val)"
	if dm_script.reload() == OK:
		dm.set_script(dm_script)
	root.add_child(dm)
	
	# Load CombatSystem
	var cs_script = load("res://scripts/CombatSystem.gd")
	var cs = Node.new()
	cs.set_script(cs_script)
	root.add_child(cs)
	
	# Create Dummy Enemy
	# var res = load("res://scripts/Resources/EnemyResource.gd").new()
	# res.id = "dummy"
	# res.max_hp = 1000
	# var unit = load("res://scripts/EnemyUnit.gd").new(res)
	# cs.enemies.append(unit)
	
	# 1. Test Block Cap
	cs.add_block(2000)
	file.store_line("Block Cap (2000 -> %d) [Expected 999]" % cs.player_block)
	
	# 2. Test Poison Cap (SKIPPED)
	# cs._apply_status_to_enemy(0, "poison", 2000)
	# file.store_line("Poison Cap (2000 -> %d) [Expected 999]" % unit.get_status("poison"))
	
	# 3. Test Str Cap (SKIPPED)
	# cs._apply_status_to_enemy(0, "strength", 200)
	# file.store_line("Strength Cap (200 -> %d) [Expected 99]" % unit.get_status("strength"))
	
	# 4. Test Seed Cap
	gc.player_state.seeds = 0
	gc.add_seeds(200)
	file.store_line("Seed Cap (200 -> %d) [Expected 100]" % gc.player_state.seeds)
	
	file.store_line("--- DONE ---")
	file.close()
	quit(0)
