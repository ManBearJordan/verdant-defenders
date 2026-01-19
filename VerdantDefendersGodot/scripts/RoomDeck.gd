extends Node

# RoomDeck system - maintains a shuffled deck of room types and presents 3 choices

var room_deck: Array[Dictionary] = []
var current_choices: Array[Dictionary] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

# Room types and their frequencies
const ROOM_TYPES = {
	"combat": 8,
	"shop": 3,
	"event": 2,
	"treasure": 2,
	"elite": 1,
	"boss": 1
}

signal choices_updated(choices: Array[Dictionary])

func _ready() -> void:
	_rng.randomize()
	_build_room_deck()
	_refill_choices()

func _build_room_deck() -> void:
	"""Build a shuffled room deck with appropriate frequencies"""
	room_deck.clear()
	
	# Add rooms based on frequencies
	for room_type in ROOM_TYPES.keys():
		var count = ROOM_TYPES[room_type]
		for i in range(count):
			room_deck.append({
				"type": room_type,
				"id": "%s_%d" % [room_type, i],
				"name": room_type.capitalize()
			})
	
	# Shuffle the deck
	_shuffle_deck()

func _shuffle_deck() -> void:
	"""Shuffle the room deck using Fisher-Yates algorithm"""
	for i in range(room_deck.size()):
		var j = _rng.randi_range(0, room_deck.size() - 1)
		var temp = room_deck[i]
		room_deck[i] = room_deck[j]
		room_deck[j] = temp

func get_current_choices() -> Array[Dictionary]:
	"""Get the current 3 room choices"""
	return current_choices.duplicate()

func pick_room(choice_index: int) -> Dictionary:
	"""Pick a room choice and refill back to 3"""
	if choice_index < 0 or choice_index >= current_choices.size():
		return {}
	
	var chosen_room = current_choices[choice_index]
	current_choices.remove_at(choice_index)
	
	# Refill back to 3 choices
	_refill_choices()
	
	return chosen_room

func _refill_choices() -> void:
	"""Refill choices back to 3, reshuffling deck if needed"""
	while current_choices.size() < 3:
		if room_deck.is_empty():
			_build_room_deck()  # Reshuffle when empty
		
		if not room_deck.is_empty():
			current_choices.append(room_deck.pop_back())
	
	choices_updated.emit(current_choices.duplicate())

func set_rng(rng: RandomNumberGenerator) -> void:
	"""Set the RNG for deterministic runs"""
	_rng = rng
	_build_room_deck()
	_refill_choices()
