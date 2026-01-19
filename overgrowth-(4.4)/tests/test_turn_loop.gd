extends GutTest

# Test the basic turn loop functionality per TURN_LOOP.md
# Requirements: after start_turn(), energy==max and hand==5

func before_each():
	# Clear sigils to prevent leakage between tests
	SigilSystem.clear_all_sigils()
	
var dm = null
var gc = null

func before_each():
	# Manually instance Autoloads for HEADLESS testing if not present
	if not has_node("/root/DeckManager"):
		var dm_script = load("res://scripts/DeckManager.gd")
		dm = dm_script.new()
		dm.name = "DeckManager"
		get_tree().root.add_child(dm)
		# Add to gutters autofree to clean up
		autofree(dm)
	else:
		dm = get_node("/root/DeckManager")

	if not has_node("/root/GameController"):
		var gc_script = load("res://scripts/GameController.gd")
		gc = gc_script.new()
		gc.name = "GameController"
		get_tree().root.add_child(gc)
		autofree(gc)
	else:
		gc = get_node("/root/GameController")
		
	# Reset states
	SigilSystem.clear_all_sigils()
	dm.draw_pile.clear()
	dm.discard_pile.clear()
	dm.hand.clear()
	dm.exhaust.clear()
	dm.energy = 0
	dm.max_energy = 3

func test_start_turn_sets_energy_to_max():
	# Arrange
	var dm = get_node_or_null("/root/DeckManager")
	assert_not_null(dm, "DeckManager should be available as autoload")
	
	# Create a minimal deck with at least 5 cards for testing
	for i in range(10):
		var card = {"name": "Test Card %d" % i, "cost": 1}
		dm.draw_pile.append(card)
	
	dm.max_energy = 3
	dm.energy = 0
	
	# Act
	dm.start_turn()
	
	# Assert
	assert_eq(dm.energy, dm.max_energy, "Energy should equal max_energy after start_turn()")

func test_start_turn_draws_5_cards():
	# Arrange
	var dm = get_node_or_null("/root/DeckManager")
	assert_not_null(dm, "DeckManager should be available as autoload")
	
	# Create a deck with at least 5 cards for testing
	for i in range(10):
		var card = {"name": "Test Card %d" % i, "cost": 1}
		dm.draw_pile.append(card)
	
	dm.hand.clear()
	
	# Act
	dm.start_turn()
	
	# Assert
	assert_eq(dm.hand.size(), 5, "Hand should contain exactly 5 cards after start_turn()")

func test_start_turn_energy_and_hand_together():
	# Arrange
	var dm = get_node_or_null("/root/DeckManager")
	assert_not_null(dm, "DeckManager should be available as autoload")
	
	# Create a deck with sufficient cards
	for i in range(15):
		var card = {"name": "Test Card %d" % i, "cost": 1}
		dm.draw_pile.append(card)
	
	dm.max_energy = 3
	dm.energy = 1  # Start with different energy
	dm.hand.clear()
	
	# Act
	dm.start_turn()
	
	# Assert - both conditions from TURN_LOOP.md
	assert_eq(dm.energy, dm.max_energy, "Energy should equal max_energy after start_turn()")
	assert_eq(dm.hand.size(), 5, "Hand should contain exactly 5 cards after start_turn()")

func test_discard_hand_empties_hand():
	# Arrange
	var dm = get_node_or_null("/root/DeckManager")
	assert_not_null(dm, "DeckManager should be available as autoload")
	
	# Add some cards to hand
	for i in range(3):
		var card = {"name": "Test Card %d" % i, "cost": 1}
		dm.hand.append(card)
	
	var initial_discard_size = dm.discard_pile.size()
	
	# Act
	dm.discard_hand()
	
	# Assert
	assert_eq(dm.hand.size(), 0, "Hand should be empty after discard_hand()")
	assert_eq(dm.discard_pile.size(), initial_discard_size + 3, "Discard pile should contain the discarded cards")

func test_turn_loop_integration():
	# Test the full turn loop integration with GameController
	var gc = get_node_or_null("/root/GameController")
	var dm = get_node_or_null("/root/DeckManager")
	
	assert_not_null(gc, "GameController should be available as autoload")
	assert_not_null(dm, "DeckManager should be available as autoload")
	
	# Setup a minimal deck
	for i in range(15):
		var card = {"name": "Test Card %d" % i, "cost": 1}
		dm.draw_pile.append(card)
	
	dm.max_energy = 3
	dm.energy = 0
	dm.hand.clear()
	
	# Act - start a player turn
	gc.start_player_turn()
	
	# Assert - verify turn loop requirements
	assert_eq(dm.energy, dm.max_energy, "Energy should equal max_energy after GameController.start_player_turn()")
	assert_eq(dm.hand.size(), 5, "Hand should contain exactly 5 cards after GameController.start_player_turn()")
	assert_true(gc.is_current_player_turn(), "Should be player turn after start_player_turn()")
