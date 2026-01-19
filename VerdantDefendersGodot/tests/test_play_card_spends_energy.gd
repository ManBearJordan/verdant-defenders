extends GutTest

# Test that playing a 1-cost attack reduces energy by 1 and removes the card from hand

func test_play_card_spends_energy():
	# Setup
	var deck_manager = DeckManager
	var game_controller = GameController
	var card_rules = CardRules
	
	# Reset deck manager
	deck_manager.draw_pile.clear()
	deck_manager.discard_pile.clear()
	deck_manager.hand.clear()
	deck_manager.energy = 3
	deck_manager.max_energy = 3
	
	# Add a test card to hand
	var test_card = {
		"id": "test_attack",
		"name": "Test Attack",
		"type": "attack",
		"cost": 1,
		"effects": [{"type": "deal_damage", "amount": 7}],
		"art_id": "art_sap_shot"
	}
	deck_manager.hand.append(test_card)
	
	# Verify initial state
	assert_eq(deck_manager.energy, 3, "Should start with 3 energy")
	assert_eq(deck_manager.hand.size(), 1, "Should have 1 card in hand")
	
	# Set up a target (mock enemy)
	var targeting_system = TargetingSystem
	var mock_enemy = Node2D.new()
	mock_enemy.name = "MockEnemy"
	mock_enemy.set_script(preload("res://scripts/enemy.gd"))
	add_child_autofree(mock_enemy)
	targeting_system.set_target(mock_enemy)
	
	# Play the card
	game_controller.play_card(0)
	
	# Verify energy was spent
	assert_eq(deck_manager.energy, 2, "Energy should be reduced by 1")
	
	# Verify card was removed from hand
	assert_eq(deck_manager.hand.size(), 0, "Card should be removed from hand")

func test_insufficient_energy_prevents_play():
	# Setup
	var deck_manager = DeckManager
	var game_controller = GameController
	
	# Reset deck manager with insufficient energy
	deck_manager.draw_pile.clear()
	deck_manager.discard_pile.clear()
	deck_manager.hand.clear()
	deck_manager.energy = 0  # No energy
	deck_manager.max_energy = 3
	
	# Add a test card to hand
	var test_card = {
		"id": "test_attack",
		"name": "Test Attack",
		"type": "attack",
		"cost": 1,
		"effects": [{"type": "deal_damage", "amount": 7}],
		"art_id": "art_sap_shot"
	}
	deck_manager.hand.append(test_card)
	
	# Verify initial state
	assert_eq(deck_manager.energy, 0, "Should start with 0 energy")
	assert_eq(deck_manager.hand.size(), 1, "Should have 1 card in hand")
	
	# Try to play the card (should fail)
	game_controller.play_card(0)
	
	# Verify energy unchanged
	assert_eq(deck_manager.energy, 0, "Energy should remain 0")
	
	# Verify card still in hand
	assert_eq(deck_manager.hand.size(), 1, "Card should remain in hand")
