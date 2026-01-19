extends GutTest

# Test: after End Turn, hand is empty and next start draws to hand size

func test_end_turn_discards_hand():
	# Setup systems
	var game_controller = get_node("/root/GameController")
	var deck_manager = get_node("/root/DeckManager")
	
	assert_not_null(game_controller, "GameController should be available")
	assert_not_null(deck_manager, "DeckManager should be available")
	
	# Create a test deck and start turn
	var test_deck = []
	for i in range(10):
		test_deck.append({
			"id": "test_card_%d" % i,
			"name": "Test Card %d" % i,
			"type": "skill",
			"cost": 1,
			"effects": []
		})
	
	deck_manager.build_starting_deck(test_deck)
	deck_manager.start_turn()
	
	# Verify we have cards in hand
	var initial_hand_size = deck_manager.get_hand().size()
	assert_gt(initial_hand_size, 0, "Should have cards in hand after start_turn")
	
	# End turn
	game_controller.end_turn()
	
	# Wait a frame for deferred calls
	await get_tree().process_frame
	
	# Check that hand is empty after end turn
	var hand_after_end_turn = deck_manager.get_hand().size()
	assert_eq(hand_after_end_turn, 0, "Hand should be empty after end turn")
	
	# Wait another frame for the next turn to start
	await get_tree().process_frame
	
	# Check that next turn draws to hand size
	var hand_after_new_turn = deck_manager.get_hand().size()
	assert_eq(hand_after_new_turn, deck_manager.HAND_SIZE, "Should draw to hand size on new turn")
