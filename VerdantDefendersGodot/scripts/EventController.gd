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
	
	# Handle Shard Costs
	if "cost_shards" in outcome:
		var cost = int(outcome["cost_shards"])
		if game_controller:
			if game_controller.shards < cost:
				# Cannot pay? Should check before clicking?
				# UI should probably disable button. But for now, just fail or go negative?
				# Let's check in UI building, but here we assume valid if clicked 
				# (Or we just deduct and if negative, handle it?)
				# Better to just deduct.
				game_controller.modify_shards(-cost)
			else:
				game_controller.modify_shards(-cost)

	if type == "heal":
		var amt = int(outcome.get("amount", 0))
		if game_controller:
			game_controller.modify_hp(amt)

	elif type == "pay_shards_heal_full":
		if game_controller:
			game_controller.heal_full()

	elif type == "resource":
		var res = outcome.get("resource", "")
		var amt = int(outcome.get("amount", 0))
		if res == "gold" or res == "shards":
			if game_controller:
				game_controller.modify_shards(amt)
				
	elif type == "card":
		var rarity = outcome.get("rarity", "common")
		if data_layer and deck_manager:
			# ... (Random card logic)
			pass

	elif type == "remove_card":
		if game_controller:
			game_controller.goto_deck_view("remove", "map")

	elif type == "upgrade_card":
		if game_controller:
			game_controller.goto_deck_view("upgrade", "map")

	elif type == "sell_card":
		if game_controller:
			game_controller.goto_deck_view("sell", "map") # Implies Amount gained is handled in RunController callback

	elif type == "sacrifice_card_sigil":
		if game_controller:
			game_controller.goto_deck_view("sacrifice_sigil", "map")

	elif type == "buy_random_card":
		if game_controller and data_layer:
			var all_cards = data_layer.get_all_cards()
			if not all_cards.is_empty():
				game_controller.add_card(all_cards.pick_random().id)
				
	elif type == "combat":
		if game_controller:
			var enemy = outcome.get("enemy_type", "miniboss")
			# This requires RunController to setup combat
			game_controller.start_combat_event(enemy)

	elif type == "gamble":
		var chance = float(outcome.get("chance", 0.5))
		var win_amt = int(outcome.get("win_shards", 0))
		if randf() < chance:
			if game_controller: game_controller.modify_shards(win_amt)
			# Needs feedback?
		else:
			# Lost the cost (already deducted above)
			pass

	elif type == "transform_card_rare":
		if game_controller:
			game_controller.transform_random_card("rare")

	elif type == "reward":
		if game_controller:
			game_controller.goto_reward("treasure")

	elif type == "damage":
		var amt = int(outcome.get("amount", 0))
		if game_controller:
			game_controller.modify_hp(-amt)

