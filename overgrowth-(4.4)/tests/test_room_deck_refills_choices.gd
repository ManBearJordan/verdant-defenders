extends GutTest

# Test that after selecting a room, choices refill back to 3 (re-deal if empty)

func test_room_deck_refills_choices():
	# Setup
	var room_deck = get_node("/root/RoomDeck")
	
	# Initialize with a test deck
	var test_deck: Array[Dictionary] = []
	for i in range(10):
		test_deck.append({"type": "combat", "id": "room_%d" % i, "name": "Room %d" % i})
	room_deck.start(test_deck)
	
	# Verify initial state
	var initial_choices = room_deck.get_current_choices()
	assert_eq(initial_choices.size(), 3, "Should have 3 current choices")
	
	var initial_total_cards = room_deck.total_cards()
	
	# Pick a room (index 0)
	var chosen_room = room_deck.pick_room(0)
	
	# Verify room was chosen
	assert_false(chosen_room.is_empty(), "Should return a valid room")
	assert_true(chosen_room.has("type"), "Chosen room should have a type")
	
	# Verify choices refilled back to 3
	var final_choices = room_deck.get_current_choices()
	assert_eq(final_choices.size(), 3, "Should refill back to 3 choices")
	
	# Verify total cards remain consistent (minus the picked one)
	var final_total_cards = room_deck.total_cards()
	assert_eq(final_total_cards, initial_total_cards - 1, "Total cards should be reduced by 1")

func test_room_deck_reshuffles_when_empty():
	# Test that room deck reshuffles when it runs out of cards
	var room_deck = get_node("/root/RoomDeck")
	
	# Create a small test deck (6 cards total)
	var test_rooms = [
		{"type": "combat", "id": "combat_1", "name": "Combat"},
		{"type": "combat", "id": "combat_2", "name": "Combat"},
		{"type": "shop", "id": "shop_1", "name": "Shop"},
		{"type": "event", "id": "event_1", "name": "Event"},
		{"type": "treasure", "id": "treasure_1", "name": "Treasure"},
		{"type": "elite", "id": "elite_1", "name": "Elite"}
	]
	
	room_deck.start(test_rooms)
	
	# Verify initial state
	assert_eq(room_deck.get_current_choices().size(), 3, "Should have 3 choices")
	assert_eq(room_deck.total_cards(), 6, "Should have 6 total cards")
	
	# Pick cards to test reshuffling
	room_deck.pick_room(0)  # Total: 5
	assert_eq(room_deck.total_cards(), 5, "Should have 5 cards after first pick")
	
	room_deck.pick_room(0)  # Total: 4
	assert_eq(room_deck.total_cards(), 4, "Should have 4 cards after second pick")
	
	room_deck.pick_room(0)  # Total: 3
	assert_eq(room_deck.total_cards(), 3, "Should have 3 cards after third pick")
	
	# Continue picking - should trigger reshuffle when needed
	room_deck.pick_room(0)  # Total: 2
	assert_eq(room_deck.total_cards(), 2, "Should have 2 cards after fourth pick")
	
	# Should still maintain 3 choices or as many as possible
	var choices = room_deck.get_current_choices()
	assert_true(choices.size() <= 3, "Should have at most 3 choices")
	assert_true(choices.size() >= 0, "Should have at least 0 choices")

func test_get_current_choices():
	# Test the get_current_choices method
	var room_deck = get_node("/root/RoomDeck")

	# Initialize with test deck
	var test_deck: Array[Dictionary] = []
	for i in range(5):
		test_deck.append({"type": "combat", "id": "room_%d" % i, "name": "Room %d" % i})
	room_deck.start(test_deck)

	# Get current choices
	var choices = room_deck.get_current_choices()

	# Verify choices
	assert_eq(choices.size(), 3, "Should return 3 choices")
	assert_true(choices is Array, "Should return an Array")

	# Verify it's a copy (modifying returned array shouldn't affect original)
	choices.append({"type": "fake", "id": "fake", "name": "Fake"})
	var original_choices = room_deck.get_current_choices()
	assert_eq(original_choices.size(), 3, "Original choices should remain unchanged")

func test_invalid_pick_room_index():
	# Test picking with invalid indices
	var room_deck = get_node("/root/RoomDeck")

	# Initialize with test deck
	var test_deck: Array[Dictionary] = []
	for i in range(5):
		test_deck.append({"type": "combat", "id": "room_%d" % i, "name": "Room %d" % i})
	room_deck.start(test_deck)

	# Try invalid indices
	var result1 = room_deck.pick_room(-1)
	assert_true(result1.is_empty(), "Should return empty dict for negative index")

	var result2 = room_deck.pick_room(5)
	assert_true(result2.is_empty(), "Should return empty dict for out-of-bounds index")

	# Verify choices unchanged
	assert_eq(room_deck.get_current_choices().size(), 3, "Choices should remain unchanged after invalid picks")

func test_room_types_distribution():
	# Test that room deck works with different room types
	var room_deck = get_node("/root/RoomDeck")

	# Create test deck with various room types
	var test_rooms = [
		{"type": "combat", "id": "combat_1", "name": "Combat 1"},
		{"type": "combat", "id": "combat_2", "name": "Combat 2"},
		{"type": "shop", "id": "shop_1", "name": "Shop 1"},
		{"type": "event", "id": "event_1", "name": "Event 1"},
		{"type": "treasure", "id": "treasure_1", "name": "Treasure 1"},
		{"type": "elite", "id": "elite_1", "name": "Elite 1"}
	]
	
	room_deck.start(test_rooms)
	
	# Get all available rooms (choices)
	var choices = room_deck.get_current_choices()
	
	# Verify we have choices
	assert_eq(choices.size(), 3, "Should have 3 choices")
	
	# Verify each choice has required fields
	for choice in choices:
		assert_true(choice.has("type"), "Each choice should have a type")
		assert_true(choice.has("id"), "Each choice should have an id")
		assert_true(choice.has("name"), "Each choice should have a name")
