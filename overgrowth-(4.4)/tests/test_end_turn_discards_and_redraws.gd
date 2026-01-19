extends GutTest

# Test that End Turn empties hand, next start draws to hand size

func test_end_turn_discards_and_redraws():
	# Setup
	var deck_manager = get_node_or_null("/root/DeckManager")
	var game_controller = get_node_or_null("/root/GameController")
	
	# Reset deck manager and build a test deck
	deck_manager.draw_pile.clear()
	deck_manager.discard_pile.clear()
	deck_manager.hand.clear()
	deck_manager.exhaust.clear()
	deck_manager.energy = 3
	deck_manager.max_energy = 3
	
	# Create a test deck with 10 cards
	var test_deck: Array[Dictionary] = []
	for i in range(10):
		test_deck.append({
			"id": "test_card_%d" % i,
			"name": "Test Card %d" % i,
			"type": "skill",
			"cost": 1,
			"effects": [{"type": "gain_block", "amount": 5}],
			"art_id": "art_seed_shield"
		})
	
	# Build the deck
	deck_manager.build_starting_deck(test_deck)
	
	# Start a turn to draw initial hand
	deck_manager.start_turn()
	
	# Verify initial state
	assert_eq(deck_manager.hand.size(), 5, "Should have 5 cards in hand after start_turn")
	assert_eq(deck_manager.energy, 3, "Should have 3 energy")
	
	# End turn (should discard hand)
	game_controller.end_turn()
	
	# Wait a frame for deferred call
	await get_tree().process_frame
	
	# Verify hand was discarded and new hand drawn
	assert_eq(deck_manager.hand.size(), 5, "Should have 5 cards in new hand")
	assert_eq(deck_manager.energy, 3, "Should have 3 energy after new turn")
	
	# Verify cards were moved to discard pile during the turn cycle
	var total_cards_accounted = deck_manager.hand.size() + deck_manager.draw_pile.size() + deck_manager.discard_pile.size()
	assert_eq(total_cards_accounted, 10, "All 10 cards should be accounted for")

func test_end_turn_discard_only():
	# Test just the discard functionality
	var deck_manager = get_node_or_null("/root/DeckManager")
	
	# Setup with cards in hand
	deck_manager.hand.clear()
	deck_manager.discard_pile.clear()
	
	# Add test cards to hand
	for i in range(3):
		deck_manager.hand.append({
			"id": "test_card_%d" % i,
			"name": "Test Card %d" % i,
			"type": "skill",
			"cost": 1
		})
	
	# Verify initial state
	assert_eq(deck_manager.hand.size(), 3, "Should have 3 cards in hand")
	assert_eq(deck_manager.discard_pile.size(), 0, "Should have 0 cards in discard")
	
	# Call end_turn_discard directly
	deck_manager.end_turn_discard()
	
	# Verify hand was discarded
	assert_eq(deck_manager.hand.size(), 0, "Hand should be empty after discard")
	assert_eq(deck_manager.discard_pile.size(), 3, "Should have 3 cards in discard pile")

func test_start_turn_draws_to_hand_size():
	# Test the start_turn drawing functionality
	var deck_manager = get_node_or_null("/root/DeckManager")
	
	# Setup with cards in draw pile
	deck_manager.draw_pile.clear()
	deck_manager.hand.clear()
	deck_manager.discard_pile.clear()
	deck_manager.energy = 0
	deck_manager.max_energy = 3
	
	# Add cards to draw pile
	for i in range(8):
		deck_manager.draw_pile.append({
			"id": "draw_card_%d" % i,
			"name": "Draw Card %d" % i,
			"type": "skill",
			"cost": 1
		})
	
	# Verify initial state
	assert_eq(deck_manager.hand.size(), 0, "Hand should be empty")
	assert_eq(deck_manager.draw_pile.size(), 8, "Should have 8 cards in draw pile")
	assert_eq(deck_manager.energy, 0, "Should have 0 energy")
	
	# Start turn
	deck_manager.start_turn()
	
	# Verify cards were drawn and energy set
	assert_eq(deck_manager.hand.size(), 5, "Should draw 5 cards")
	assert_eq(deck_manager.draw_pile.size(), 3, "Should have 3 cards left in draw pile")
	assert_eq(deck_manager.energy, 3, "Energy should be set to max_energy")

func test_reshuffle_when_draw_pile_empty():
	# Test that discard pile reshuffles into draw pile when needed
	var deck_manager = get_node_or_null("/root/DeckManager")
	
	# Setup with empty draw pile and cards in discard
	deck_manager.draw_pile.clear()
	deck_manager.hand.clear()
	deck_manager.discard_pile.clear()
	deck_manager.max_energy = 3
	
	# Add cards to discard pile (simulating previous turns)
	for i in range(7):
		deck_manager.discard_pile.append({
			"id": "discard_card_%d" % i,
			"name": "Discard Card %d" % i,
			"type": "skill",
			"cost": 1
		})
	
	# Verify initial state
	assert_eq(deck_manager.draw_pile.size(), 0, "Draw pile should be empty")
	assert_eq(deck_manager.discard_pile.size(), 7, "Should have 7 cards in discard")
	assert_eq(deck_manager.hand.size(), 0, "Hand should be empty")
	
	# Start turn (should trigger reshuffle)
	deck_manager.start_turn()
	
	# Verify reshuffle occurred and cards were drawn
	assert_eq(deck_manager.hand.size(), 5, "Should draw 5 cards after reshuffle")
	assert_eq(deck_manager.draw_pile.size(), 2, "Should have 2 cards left in draw pile")
	assert_eq(deck_manager.discard_pile.size(), 0, "Discard pile should be empty after reshuffle")
