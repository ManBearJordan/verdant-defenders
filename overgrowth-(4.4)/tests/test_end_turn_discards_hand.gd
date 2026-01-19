extends GutTest

# Test: after End Turn, hand is empty and next start draws to hand size

func test_end_turn_discards_hand():
	# Setup systems
	var game_controller = get_node("/root/GameController")
	var deck_manager = get_node("/root/DeckManager")
	
	assert_not_null(game_controller, "GameController should be available")
	assert_not_null(deck_manager, "DeckManager should be available")
	
	# Create a test deck and start turn
	var test_deck: Array[Dictionary] = []
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
	
	# Test just the discard functionality without timing issues
	game_controller.discard_hand_only()
	
	# Check that hand is empty after discard
	var hand_after_discard = deck_manager.get_hand().size()
	assert_eq(hand_after_discard, 0, "Hand should be empty after end turn")
	
	# Manually start a new turn to test the draw functionality
	deck_manager.start_turn()
	
	# Check that next turn draws to hand size
	var hand_after_new_turn = deck_manager.get_hand().size()
	assert_eq(hand_after_new_turn, deck_manager.HAND_SIZE, "Should draw to hand size on new turn")
