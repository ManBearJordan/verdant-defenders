extends Node

signal event_started(event_data: Dictionary)
signal event_completed

var _events_data: Dictionary = {}
var _current_event: Dictionary = {}

var game_controller: Node
var deck_manager: Node
var data_layer: Node

func _ready() -> void:
	game_controller = get_node_or_null("/root/RunController") # Was GameController
	deck_manager = get_node_or_null("/root/DeckManager")
	data_layer = get_node_or_null("/root/DataLayer")
	_load_events()

func _load_events() -> void:
	var path = "res://Data/events.json"
	if not FileAccess.file_exists(path):
		print("EventController: events.json not found")
		return
	var f = FileAccess.open(path, FileAccess.READ)
	var txt = f.get_as_text()
	var json = JSON.new()
	if json.parse(txt) == OK:
		_events_data = json.data

func start_random_event() -> void:
	if _events_data.is_empty():
		print("EventController: No events loaded")
		event_completed.emit()
		return
	
	var keys = _events_data.keys()
	var key = keys[randi() % keys.size()]
	_current_event = _events_data[key]
	emit_signal("event_started", _current_event)

func select_choice(index: int) -> void:
	if _current_event.is_empty():
		return
	
	var choices = _current_event.get("choices", [])
	if index < 0 or index >= choices.size():
		return
		
	var choice = choices[index]
	var outcome = choice.get("outcome", {})
	_apply_outcome(outcome)
	
	_current_event = {}
	event_completed.emit()

func _apply_outcome(outcome: Dictionary) -> void:
	var type = outcome.get("type", "none")
	
	# Handle costs first
	if "cost_hp" in outcome:
		var cost = int(outcome["cost_hp"])
		if game_controller:
			game_controller.modify_hp(-cost)
			
	if type == "heal":
		var amt = int(outcome.get("amount", 0))
		if game_controller:
			game_controller.modify_hp(amt)
			
	elif type == "resource":
		var res = outcome.get("resource", "")
		var amt = int(outcome.get("amount", 0))
		if res == "gold" or res == "shards":
			if game_controller:
				game_controller.modify_shards(amt)
				
	elif type == "card":
		var rarity = outcome.get("rarity", "common")
		if data_layer and deck_manager:
			var all_cards = data_layer.get_all_cards()
			var candidates = []
			for c in all_cards:
				if c.get("rarity", "common") == rarity:
					candidates.append(c)
			
			if not candidates.is_empty():
				var picked = candidates[randi() % candidates.size()]
				deck_manager.discard_card(picked.duplicate(true))

	elif type == "remove_card":
		if game_controller:
			game_controller.goto_deck_view("remove", "map")

	elif type == "upgrade_card":
		if game_controller:
			game_controller.goto_deck_view("upgrade", "map")

	elif type == "reward":
		# Trigger Reward Screen (e.g. for Treasure)
		if game_controller:
			game_controller.goto_reward("treasure")

	elif type == "damage":
		# Direct damage (duplicate of cost_hp logic but as outcome)
		var amt = int(outcome.get("amount", 0))
		if game_controller:
			game_controller.modify_hp(-amt)

