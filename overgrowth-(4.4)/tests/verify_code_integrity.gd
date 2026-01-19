extends SceneTree

func _init():
	print("Running Integrity Checks...")
	var errors = 0
	
	# Check GameController
	var gc_script = load("res://scripts/GameController.gd")
	if gc_script:
		var instance = gc_script.new()
		for method in ["save_run", "load_run", "delete_save", "heal_player", "damage_player"]:
			if not instance.has_method(method):
				print("ERROR: GameController.gd missing method: " + method)
				errors += 1
		instance.free()
	else:
		print("ERROR: Could not load GameController.gd")
		errors += 1

	# Check CombatSystem
	var cs_script = load("res://scripts/CombatSystem.gd")
	if cs_script:
		var instance = cs_script.new()
		for method in ["process_start_turn_effects", "get_living_enemies", "damage_enemy"]:
			if not instance.has_method(method):
				print("ERROR: CombatSystem.gd missing method: " + method)
				errors += 1
		instance.free()
	else:
		print("ERROR: Could not load CombatSystem.gd")
		errors += 1

	# Check DeckManager
	var dm_script = load("res://scripts/DeckManager.gd")
	if dm_script:
		var instance = dm_script.new()
		for method in ["build_starting_deck_from_data", "draw_cards", "play_card"]:
			if not instance.has_method(method):
				print("ERROR: DeckManager.gd missing method: " + method)
				errors += 1
		instance.free()
	else:
		print("ERROR: Could not load DeckManager.gd")
		errors += 1

	# Check GameUI
	var gui_script = load("res://scripts/GameUI.gd")
	if gui_script:
		var instance = gui_script.new()
		for method in ["_on_damage_dealt", "spawn_damage_number"]:
			if not instance.has_method(method):
				print("ERROR: GameUI.gd missing method: " + method)
				errors += 1
		instance.free()
	else:
		print("ERROR: Could not load GameUI.gd")
		errors += 1

	if errors == 0:
		print("Integrity Check PASSED")
		quit(0)
	else:
		print("Integrity Check FAILED with %d errors" % errors)
		quit(1)
