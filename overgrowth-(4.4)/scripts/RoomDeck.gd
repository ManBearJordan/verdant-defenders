# res://scripts/RoomDeck.gd
extends Node

var _rng := RandomNumberGenerator.new()
var _deck: Array[Dictionary] = []
var _discard: Array[Dictionary] = []
var _choices: Array[Dictionary] = []

func _ready() -> void:
	_rng.randomize()

func start(new_deck: Array) -> void:
	_deck.clear()
	_discard.clear()
	_choices.clear()
	
	# Convert and validate the input array
	for item in new_deck:
		if item is Dictionary:
			_deck.append(item as Dictionary)
	
	_shuffle(_deck)
	_refill_choices()

func get_current_choices() -> Array[Dictionary]:
	return _choices.duplicate(true)

func pick_room(index: int) -> Dictionary:
	if index < 0 or index >= _choices.size():
		return {}
	var picked := _choices[index]
	_choices.remove_at(index)
	# Don't add to discard - rooms are permanently consumed when picked
	_refill_choices()
	return picked

func total_cards() -> int:
	return _deck.size() + _choices.size()

# --- internals ---
func _draw_one() -> Dictionary:
	if _deck.is_empty():
		if _discard.is_empty():
			return {}
		_deck = _discard.duplicate(true)
		_discard.clear()
		_shuffle(_deck)
	return _deck.pop_back()

func _refill_choices() -> void:
	while _choices.size() < 3:
		var r := _draw_one()
		if r.is_empty():
			break
		_choices.append(r)

func _shuffle(arr: Array[Dictionary]) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var tmp: Dictionary = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
