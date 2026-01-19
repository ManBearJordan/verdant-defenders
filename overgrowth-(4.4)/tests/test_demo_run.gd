extends GutTest

func before_all():
	pass

func test_simulate_short_run():
	var dc = get_node_or_null("/root/DungeonController")
	var gc = get_node_or_null("/root/GameController")
	var dm = get_node_or_null("/root/DeckManager")
	var cs = get_node_or_null("/root/CombatSystem")
	
	assert_not_null(dc, "DungeonController missing")
	
	print("\n=== STARTING OVERGROWTH DEMO RUN ===\n")
	
	# Start the run
	dc.start_run()
	print("Entered Layer Index: %d" % dc.layer_index)
	
	# Loop through a few rooms
	for i in range(5):
		await get_tree().create_timer(0.1).timeout
		# Wait a bit
		await get_tree().create_timer(0.1).timeout
		
		# If we have a current room, process it
		var current_room = dc.current_room
		if current_room.is_empty():
			# Might be at choice screen
			pass
		else:
			print("\n--- Room %d: %s ---" % [dc.room_counter, current_room.get("name", "Unknown")])
			var type = current_room.get("type")
			
			if type == "fight" or type == "elite" or type == "boss":
				await _handle_combat(cs, dm, gc)
				# Combat finished, force next if not auto
				if dc.current_room == current_room: # Still in same room?
					dc.next_room()
			elif type == "shop":
				print("Player entered Shop.")
				var shop = get_node_or_null("/root/ShopSystem")
				if shop:
					print("Player heals up!")
					shop.heal_player(20)
				dc.next_room()
			elif type == "event":
				print("Player encountered an Event.")
				# Event controller auto-completes in some tests, or we force it
				dc.next_room()
		
		await get_tree().create_timer(0.1).timeout
		# Wait a bit
		await get_tree().create_timer(0.1).timeout

		# Make a choice if choices are available
		var rd = dc.get_node_or_null("RoomDeck") # Instance is named RoomDeck? Checked DC code: _room_deck_instance assigned. 
		# Wait, DC adds child but doesn't name it "RoomDeck". It's a script instance.
		# I'll check children of DC.
		if rd == null:
			for c in dc.get_children():
				if "RoomDeck" in c.name or c.get_script().resource_path.ends_with("RoomDeck.gd"):
					rd = c
					break
		
		if rd:
			var choices = rd.get_current_choices()
			if not choices.is_empty():
				print("Forward Options: %s" % str(choices.map(func(x): return x.name)))
				var pick = 0
				print("Player chooses path: %s" % choices[pick].name)
				dc.choose_room(pick)
		else:
			print("Waiting for choices or run end...")

	print("\n=== DEMO RUN COMPLETE ===")

func _handle_combat(cs, dm, gc):
	print("Combat Started!")
	# We need to simulate the loop until enemies are dead
	var max_turns = 5
	var turn = 0
	
	while turn < max_turns:
		await get_tree().create_timer(0.1).timeout
		turn += 1
		var enemies = cs.get_enemies()
		var alive_count = 0
		for e in enemies:
			if int(e.get("hp", 0)) > 0: alive_count += 1
		
		if alive_count == 0:
			print("  Victory! All enemies defeated.")
			return
		
		print("  Turn %d | HP: %d | Energy: %d | Enemies: %d" % [turn, gc.player_hp, dm.energy, alive_count])
		
		# Play cards
		var hand = dm.get_hand()
		if hand.is_empty():
			print("    Hand empty! Ending turn.")
			gc.end_player_turn()
		else:
			# Play first affordable card
			var played = false
			for idx in range(hand.size()):
				var card = hand[idx]
				if int(card.get("cost", 0)) <= dm.energy:
					print("    Played: %s" % card.get("name"))
					cs.play_card(idx, card, 0) # Target first enemy
					played = true
					break 
			
			if not played:
				print("    Not enough energy for any card.")
				gc.end_player_turn()
		
		# Update world
		await get_tree().create_timer(0.2).timeout
		
		# Check player death
		if gc.player_hp <= 0:
			print("  DEFEAT.")
			return
