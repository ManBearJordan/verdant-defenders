extends SceneTree

func _init():
	print("Verifying Code Integrity...")
	var errors = 0
	
	var checks = {
		"res://scripts/GameController.gd": ["save_run", "load_run", "delete_save", "start_run", "end_turn", "heal_player"],
		"res://scripts/CombatSystem.gd": ["damage_enemy", "damage_player", "begin_encounter", "add_block", "play_card", "on_player_card_played"],
		"res://scripts/DungeonController.gd": ["next_room", "start_run", "get_current_pool"],
		"res://scripts/DeckManager.gd": ["draw_cards", "spend_energy", "reset"],
		"res://scripts/StatusHandler.gd": ["process_start_of_turn", "process_end_of_turn", "get_incoming_damage_mult", "get_outgoing_damage_mult"],
		"res://scripts/RewardSystem.gd": ["generate_elite_rewards", "offer_mixed_rewards"],
		"res://scripts/Tools/ResourceGenerator.gd": ["migrate_enemies", "migrate_cards"],
		"res://scripts/test_simple.gd": ["test_method"]
	}

	var log_file = FileAccess.open("res://integrity_check_result.txt", FileAccess.WRITE)
	log_file.store_line("Verifying Code Integrity...")
	
	for path in checks:
		var script = load(path)
		if not script:
			var msg = "ERROR: Could not load script: " + path
			print(msg)
			log_file.store_line(msg)
			errors += 1
			continue
			
		var methods_list = []
		
		# Static Analysis: get_script_method_list() works on Script resource
		var ml = script.get_script_method_list()
		for m in ml:
			methods_list.append(m.name)
			
		# Optional: Try to instantiate to catch syntax errors / cyclic dependencies?
		# if not script.can_instantiate():
		# 	var msg = "WARNING: Code issue preventing instantiation of %s" % path
		# 	print(msg)
		# 	log_file.store_line(msg)

		for method in checks[path]:
			if not method in methods_list:
				var msg = "CRITICAL ERROR: logic missing in %s: function '%s' not found!" % [path, method]
				print(msg)
				log_file.store_line(msg)
				errors += 1
			else:
				# log_file.store_line("  OK: %s.%s" % [path, method])
				pass
	
	log_file.store_line("---------------------------------------------------")
	if errors == 0:
		var msg = "Integrity Check PASSED. All critical methods found."
		print(msg)
		log_file.store_line(msg)
		log_file.close()
		quit(0)
	else:
		var msg = "Integrity Check FAILED with %d errors." % errors
		print(msg)
		log_file.store_line(msg)
		log_file.close()
		quit(1)
