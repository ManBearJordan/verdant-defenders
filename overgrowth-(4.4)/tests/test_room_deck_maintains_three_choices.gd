extends GutTest

# Test: after a pick, choices refill back to 3

func test_room_deck_maintains_three_choices():
	# Setup RoomDeck system
	var room_deck = get_node_or_null("/root/RoomDeck")
	assert_not_null(room_deck, "RoomDeck should be available")
	
	# Initialize with a test deck
	var test_deck: Array[Dictionary] = []
	for i in range(10):
		test_deck.append({"type": "combat", "id": "room_%d" % i, "name": "Room %d" % i})
	room_deck.start(test_deck)
	
	# Verify initial state has 3 choices
	var initial_choices = room_deck.get_current_choices()
	assert_eq(initial_choices.size(), 3, "Should start with 3 choices")
	
	# Pick the first choice
	var chosen_room = room_deck.pick_room(0)
	assert_false(chosen_room.is_empty(), "Should return a valid room when picking")
	
	# Verify we still have 3 choices after picking
	var choices_after_pick = room_deck.get_current_choices()
	assert_eq(choices_after_pick.size(), 3, "Should maintain 3 choices after picking")
	
	# Verify the choices are different (at least one should be different)
	var choices_changed = false
	for i in range(3):
		if i < initial_choices.size() and i < choices_after_pick.size():
			if initial_choices[i].get("id", "") != choices_after_pick[i].get("id", ""):
				choices_changed = true
				break
	
	# Assert that at least one choice changed after picking
	assert_true(choices_changed, "At least one choice should be different after picking a room")
	
	# Note: This test might be flaky if the deck reshuffles and gives the same choices
	# But it should generally pass since we removed one choice
	
	# Pick another choice to test multiple picks
	var second_chosen = room_deck.pick_room(1)
	assert_false(second_chosen.is_empty(), "Should return a valid room when picking second choice")
	
	# Verify we still have 3 choices
	var final_choices = room_deck.get_current_choices()
	assert_eq(final_choices.size(), 3, "Should still maintain 3 choices after second pick")
