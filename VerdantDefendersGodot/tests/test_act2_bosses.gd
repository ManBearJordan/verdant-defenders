extends SceneTree

func _init():
	var file = FileAccess.open("res://act2_boss_verification.txt", FileAccess.WRITE)
	file.store_line("--- Act 2 Boss Verification ---")
	
	# Mock GC
	var gc_script = load("res://scripts/GameController.gd")
	var gc = Node.new()
	gc.set_script(gc_script)
	gc.name = "GameController"
	root.add_child(gc)
	gc.player_hp = 100
	
	# Mock DeckManager needed for play_card
	var dm = Node.new()
	dm.name = "DeckManager"
	var dm_script = GDScript.new()
	dm_script.source_code = "extends Node\nvar hand=[]\nvar draw_pile=[]\nvar energy=10\nsignal energy_changed(val)\nfunc spend_energy(x): return true\nfunc remove_from_hand(x): return {}\nfunc discard_card(x): pass"
	if dm_script.reload() == OK:
		dm.set_script(dm_script)
	root.add_child(dm)
	
	# Load CombatSystem
	var cs_script = load("res://scripts/CombatSystem.gd")
	var cs = Node.new()
	cs.set_script(cs_script)
	root.add_child(cs)
	
	# Test 1: Gravebloom (Block -> Strength)
	file.store_line("[Gravebloom]")
	var gb_res = load("res://scripts/Resources/EnemyResource.gd").new()
	gb_res.id = "gravebloom"
	gb_res.display_name = "Gravebloom Behemoth"
	gb_res.max_hp = 100
	var gb = load("res://scripts/EnemyUnit.gd").new(gb_res)
	cs.enemies.clear()
	cs.enemies.append(gb)
	
	cs.player_block = 15 # Should trigger +1 Strength
	cs._check_boss_mechanics_start_turn(gb)
	file.store_line("  Block 15 -> Strength: %d (Expected 1)" % gb.get_status("strength"))
	
	cs.player_block = 25 # Should trigger +2 Strength
	gb.set_status("strength", 0) # Reset
	cs._check_boss_mechanics_start_turn(gb)
	file.store_line("  Block 25 -> Strength: %d (Expected 2)" % gb.get_status("strength"))
	
	# Test 2: Carrion (Poison Reflect)
	file.store_line("[Carrion Feeder]")
	var cf_res = load("res://scripts/Resources/EnemyResource.gd").new()
	cf_res.id = "carrion"
	cf_res.display_name = "Carrion Feeder"
	cf_res.max_hp = 100
	var cf = load("res://scripts/EnemyUnit.gd").new(cf_res)
	cs.enemies.clear()
	cs.enemies.append(cf)
	
	cf.set_status("poison", 10)
	var start_hp = gc.player_hp
	cs.process_turn_end_effects() # Should reflect 2 dmg
	var dmg_taken = start_hp - gc.player_hp
	file.store_line("  Reflect Dmg: %d (Expected 2)" % dmg_taken)
	
	# Test 3: Stormwarden (Static)
	file.store_line("[Stormwarden]")
	var sw_res = load("res://scripts/Resources/EnemyResource.gd").new()
	sw_res.id = "stormwarden"
	sw_res.display_name = "Stormwarden"
	sw_res.max_hp = 100
	var sw = load("res://scripts/EnemyUnit.gd").new(sw_res)
	cs.enemies.clear()
	cs.enemies.append(sw)
	
	var strike = load("res://scripts/Resources/CardResource.gd").new()
	strike.type = "Strike"
	strike.cost = 0
	
	var ritual = load("res://scripts/Resources/CardResource.gd").new()
	ritual.type = "Ritual"
	ritual.cost = 0
	
	# Play Strike (+1 Static)
	cs.play_card(0, strike, 0)
	file.store_line("  Static after Strike: %d (Expected 1)" % sw.get_status("static"))
	
	# Play Ritual (+2 Static -> 3)
	cs.play_card(0, ritual, 0)
	file.store_line("  Static after Ritual: %d (Expected 3)" % sw.get_status("static"))
	
	# Play Ritual (+2 Static -> 5 -> Discharge!)
	start_hp = gc.player_hp
	cs.play_card(0, ritual, 0)
	file.store_line("  Static after Discharge: %d (Expected 0)" % sw.get_status("static"))
	dmg_taken = start_hp - gc.player_hp
	file.store_line("  Discharge Dmg: %d (Expected 10)" % dmg_taken)
	
	file.store_line("--- DONE ---")
	file.close()
	quit(0)
