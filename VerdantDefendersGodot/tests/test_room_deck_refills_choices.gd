extends GutTest

# Test that after selecting a room, choices refill back to 3 (re-deal if empty)

func test_room_deck_refills_choices():
	# Setup
	var room_deck = get_node("/root/RoomDeck")
	
	# Reset room deck
	room_deck.room_deck.clear()
	room_deck.current_choices.clear()
	
	# Build a fresh room deck
	room_deck._build_room_deck()
	
	# Verify initial state
	assert_gt(room_deck.room_deck.size(), 0, "Room deck should have cards")
	assert_eq(room_deck.current_choices.size(), 3, "Should have 3 current choices")
	
	var initial_deck_size = room_deck.room_deck.size()
	var initial_total_cards = initial_deck_size + room_deck.current_choices.size()
	
	# Pick a room (index 0)
	var chosen_room = room_deck.pick_room(0)
	
	# Verify room was chosen
	assert_false(chosen_room.is_empty(), "Should return a valid room")
	assert_true(chosen_room.has("type"), "Chosen room should have a type")
	
	# Verify choices refilled back to 3
	assert_eq(room_deck.current_choices.size(), 3, "Should refill back to 3 choices")
	
	# Verify total cards remain consistent (minus the picked one)
	var final_total_cards = room_deck.room_deck.size() + room_deck.current_choices.size()
	assert_eq(final_total_cards, initial_total_cards - 1, "Total cards should be reduced by 1")

func test_room_deck_reshuffles_when_empty():
	# Test that room deck reshuffles when it runs out of cards
	var room_deck = get_node("/root/RoomDeck")
	
	# Reset and build a minimal room deck for testing
	room_deck.room_deck.clear()
	room_deck.current_choices.clear()
	
	# Create a small test deck (6 cards total)
	var test_rooms = [
		{"type": "combat", "id": "combat_1", "name": "Combat"},
		{"type": "combat", "id": "combat_2", "name": "Combat"},
		{"type": "shop", "id": "shop_1", "name": "Shop"},
		{"type": "event", "id": "event_1", "name": "Event"},
		{"type": "treasure", "id": "treasure_1", "name": "Treasure"},
		{"type": "elite", "id": "elite_1", "name": "Elite"}
	]
	
	# Set up the room deck manually
	for room in test_rooms:
		room_deck.room_deck.append(room)
	
	# Refill choices (should take 3 from deck, leaving 3)
	room_deck._refill_choices()
	
	# Verify initial state
	assert_eq(room_deck.current_choices.size(), 3, "Should have 3 choices")
	assert_eq(room_deck.room_deck.size(), 3, "Should have 3 cards left in deck")
	
	# Pick all remaining cards from deck by picking choices
	room_deck.pick_room(0)  # Deck: 2, Choices: 3
	assert_eq(room_deck.room_deck.size(), 2, "Should have 2 cards left in deck")
	
	room_deck.pick_room(0)  # Deck: 1, Choices: 3
	assert_eq(room_deck.room_deck.size(), 1, "Should have 1 card left in deck")
	
	room_deck.pick_room(0)  # Deck: 0, Choices: 3 (should trigger reshuffle)
	assert_eq(room_deck.room_deck.size(), 0, "Deck should be empty")
	assert_eq(room_deck.current_choices.size(), 3, "Should still have 3 choices")
	
	# Pick one more to trigger reshuffle
	room_deck.pick_room(0)  # Should reshuffle and refill
	
	# Verify reshuffle occurred
	assert_gt(room_deck.room_deck.size(), 0, "Deck should be reshuffled and have cards")
	assert_eq(room_deck.current_choices.size(), 3, "Should maintain 3 choices after reshuffle")

func test_get_current_choices():
	# Test the get_current_choices method
	var room_deck = get_node("/root/RoomDeck")

	# Reset and build room deck
	room_deck.room_deck.clear()
	room_deck.current_choices.clear()
	room_deck._build_room_deck()

	# Get current choices
	var choices = room_deck.get_current_choices()

	# Verify choices
	assert_eq(choices.size(), 3, "Should return 3 choices")
	assert_true(choices is Array, "Should return an Array")

	# Verify it's a copy (modifying returned array shouldn't affect original)
	choices.append({"type": "fake", "id": "fake", "name": "Fake"})
	assert_eq(room_deck.current_choices.size(), 3, "Original choices should remain unchanged")

func test_invalid_pick_room_index():
	# Test picking with invalid indices
	var room_deck = get_node("/root/RoomDeck")

	# Reset and build room deck
	room_deck.room_deck.clear()
	room_deck.current_choices.clear()
	room_deck._build_room_deck()

	# Try invalid indices
	var result1 = room_deck.pick_room(-1)
	assert_true(result1.is_empty(), "Should return empty dict for negative index")

	var result2 = room_deck.pick_room(5)
	assert_true(result2.is_empty(), "Should return empty dict for out-of-bounds index")

	# Verify choices unchanged
	assert_eq(room_deck.current_choices.size(), 3, "Choices should remain unchanged after invalid picks")

func test_room_types_distribution():
	# Test that room deck contains expected room types
	var room_deck = get_node("/root/RoomDeck")

	# Reset and build room deck
	room_deck.room_deck.clear()
	room_deck.current_choices.clear()
	room_deck._build_room_deck()
	
	# Count room types in deck + choices
	var all_rooms = room_deck.room_deck + room_deck.current_choices
	var type_counts = {}
	
	for room in all_rooms:
		var room_type = room.get("type", "unknown")
		type_counts[room_type] = type_counts.get(room_type, 0) + 1
	
	# Verify expected room types exist
	assert_true(type_counts.has("combat"), "Should have combat rooms")
	assert_true(type_counts.has("shop"), "Should have shop rooms")
	assert_true(type_counts.has("event"), "Should have event rooms")
	assert_true(type_counts.has("treasure"), "Should have treasure rooms")
	assert_true(type_counts.has("elite"), "Should have elite rooms")
	assert_true(type_counts.has("boss"), "Should have boss rooms")
	
	# Verify combat is most common (based on ROOM_TYPES constant)
	assert_gt(type_counts.get("combat", 0), type_counts.get("shop", 0), "Combat should be more common than shop")
