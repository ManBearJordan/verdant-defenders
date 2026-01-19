extends GutTest

# Test that with a +1 energy sigil, start-turn energy = max+1

func test_sigil_energy_bonus():
	# Setup
	var sigil_system = get_node("/root/SigilSystem")
	var deck_manager = get_node("/root/DeckManager")
	var game_controller = get_node("/root/GameController")
	
	# Clear any existing sigils
	sigil_system.clear_all_sigils()
	
	# Setup deck manager
	deck_manager.max_energy = 3
	deck_manager.energy = 0
	
	# Add a +1 energy sigil
	var energy_sigil = {
		"id": "energy_boost",
		"name": "Energy Boost",
		"description": "Gain +1 energy at the start of each turn",
		"effects": {
			"start_turn_energy_bonus": 1
		}
	}
	sigil_system.add_sigil(energy_sigil)
	
	# Verify sigil was added
	assert_eq(sigil_system.active_sigils.size(), 1, "Should have 1 active sigil")
	assert_true(sigil_system.has_sigil("energy_boost"), "Should have energy_boost sigil")
	
	# Start a player turn (should apply sigil bonus)
	game_controller.start_player_turn()
	
	# Verify energy bonus was applied (max_energy + bonus)
	assert_eq(deck_manager.energy, 4, "Energy should be max_energy (3) + bonus (1) = 4")

func test_multiple_energy_sigils_stack():
	# Test that multiple energy sigils stack
	var sigil_system = get_node("/root/SigilSystem")
	var deck_manager = get_node("/root/DeckManager")
	var game_controller = get_node("/root/GameController")
	
	# Clear any existing sigils
	sigil_system.clear_all_sigils()
	
	# Setup deck manager
	deck_manager.max_energy = 3
	deck_manager.energy = 0
	
	# Add two energy sigils
	var energy_sigil1 = {
		"id": "energy_boost_1",
		"name": "Energy Boost 1",
		"description": "Gain +1 energy at the start of each turn",
		"effects": {
			"start_turn_energy_bonus": 1
		}
	}
	var energy_sigil2 = {
		"id": "energy_boost_2", 
		"name": "Energy Boost 2",
		"description": "Gain +2 energy at the start of each turn",
		"effects": {
			"start_turn_energy_bonus": 2
		}
	}
	
	sigil_system.add_sigil(energy_sigil1)
	sigil_system.add_sigil(energy_sigil2)
	
	# Verify sigils were added
	assert_eq(sigil_system.active_sigils.size(), 2, "Should have 2 active sigils")
	
	# Start a player turn (should apply both bonuses)
	game_controller.start_player_turn()
	
	# Verify energy bonuses stacked (max_energy + bonus1 + bonus2)
	assert_eq(deck_manager.energy, 6, "Energy should be max_energy (3) + bonus1 (1) + bonus2 (2) = 6")

func test_card_cost_discount_sigil():
	# Test card cost discount sigil
	var sigil_system = get_node("/root/SigilSystem")
	var deck_manager = get_node("/root/DeckManager")
	var game_controller = get_node("/root/GameController")
	
	# Clear any existing sigils
	sigil_system.clear_all_sigils()
	
	# Add a cost discount sigil
	var discount_sigil = {
		"id": "cost_reduction",
		"name": "Cost Reduction",
		"description": "Reduce card costs by 1 (minimum 0)",
		"effects": {
			"card_cost_discount": 1
		}
	}
	sigil_system.add_sigil(discount_sigil)
	
	# Setup deck manager with energy and a test card
	deck_manager.draw_pile.clear()
	deck_manager.discard_pile.clear()
	deck_manager.hand.clear()
	deck_manager.energy = 3
	deck_manager.max_energy = 3
	
	# Add a 2-cost test card to hand (use skill type to avoid targeting issues)
	var test_card = {
		"id": "test_expensive_card",
		"name": "Expensive Card",
		"type": "skill",
		"cost": 2,
		"effects": [{"type": "gain_block", "amount": 10}],
		"art_id": "art_seed_shield"
	}
	deck_manager.hand.append(test_card)
	
	# Verify initial state
	assert_eq(deck_manager.energy, 3, "Should have 3 energy")
	assert_eq(deck_manager.hand.size(), 1, "Should have 1 card in hand")
	
	# Clear any existing target to avoid freed instance issues
	var targeting_system = get_node("/root/TargetingSystem")
	targeting_system.clear_target()
	
	# Play the card (should cost 1 instead of 2 due to discount)
	game_controller.play_card(0)
	
	# Verify discounted cost was applied
	assert_eq(deck_manager.energy, 2, "Energy should be 2 (3 - 1 discounted cost)")
	assert_eq(deck_manager.hand.size(), 0, "Card should be removed from hand")

func test_sigil_hooks_with_no_sigils():
	# Test that hooks work correctly when no sigils are active
	var sigil_system = get_node("/root/SigilSystem")
	var deck_manager = get_node("/root/DeckManager")
	var game_controller = get_node("/root/GameController")
	
	# Clear all sigils
	sigil_system.clear_all_sigils()
	
	# Setup deck manager
	deck_manager.max_energy = 3
	deck_manager.energy = 0
	
	# Start a player turn
	game_controller.start_player_turn()
	
	# Verify no bonus was applied (just normal max_energy)
	assert_eq(deck_manager.energy, 3, "Energy should be max_energy (3) with no sigil bonus")

func test_sigil_system_add_remove():
	# Test adding and removing sigils
	var sigil_system = get_node("/root/SigilSystem")
	
	# Clear all sigils
	sigil_system.clear_all_sigils()
	assert_eq(sigil_system.active_sigils.size(), 0, "Should start with no sigils")
	
	# Add a test sigil
	var test_sigil = {
		"id": "test_sigil",
		"name": "Test Sigil",
		"description": "A test sigil",
		"effects": {
			"start_turn_energy_bonus": 1
		}
	}
	sigil_system.add_sigil(test_sigil)
	
	# Verify sigil was added
	assert_eq(sigil_system.active_sigils.size(), 1, "Should have 1 sigil after adding")
	assert_true(sigil_system.has_sigil("test_sigil"), "Should have test_sigil")
	
	# Remove the sigil
	sigil_system.remove_sigil("test_sigil")
	
	# Verify sigil was removed
	assert_eq(sigil_system.active_sigils.size(), 0, "Should have 0 sigils after removing")
	assert_false(sigil_system.has_sigil("test_sigil"), "Should not have test_sigil")

func test_apply_hook_returns_correct_values():
	# Test that apply_hook returns the correct values
	var sigil_system = get_node("/root/SigilSystem")
	
	# Clear all sigils
	sigil_system.clear_all_sigils()
	
	# Test with no sigils
	var result1 = sigil_system.apply_hook("start_turn_energy_bonus", {})
	assert_eq(result1, 0, "Should return 0 when no sigils provide the hook")
	
	# Add a sigil with energy bonus
	var energy_sigil = {
		"id": "energy_test",
		"name": "Energy Test",
		"effects": {
			"start_turn_energy_bonus": 2
		}
	}
	sigil_system.add_sigil(energy_sigil)
	
	# Test with sigil
	var result2 = sigil_system.apply_hook("start_turn_energy_bonus", {})
	assert_eq(result2, 2, "Should return 2 from the energy sigil")
	
	# Test unknown hook
	var result3 = sigil_system.apply_hook("unknown_hook", {})
	assert_eq(result3, null, "Should return null for unknown hook")
