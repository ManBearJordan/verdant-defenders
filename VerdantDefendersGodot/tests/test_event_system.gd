extends GutTest

var event_controller_script = load("res://scripts/EventController.gd")
var game_controller_script = load("res://scripts/GameController.gd")
var deck_manager_script = load("res://scripts/DeckManager.gd")
var ec = null
var gc = null
var dm = null

func before_each():
	# Setup mocks/stubs
	gc = game_controller_script.new()
	gc.name = "GameController"
	add_child_autofree(gc)
	
	dm = deck_manager_script.new()
	dm.name = "DeckManager"
	add_child_autofree(dm)
	
	ec = event_controller_script.new()
	ec.name = "EventController"
	add_child_autofree(ec)
	
	# Inject dependencies manually
	ec.game_controller = gc
	ec.deck_manager = dm
	# ec.data_layer = ...

func test_load_events():
	# Wait for _ready?
	await wait_seconds(0.1)
	assert_gt(ec._events_data.size(), 0, "Should have loaded events from json")

func test_start_event():
	await wait_seconds(0.1)
	watch_signals(ec)
	ec.start_random_event()
	assert_signal_emitted(ec, "event_started")
	assert_ne(ec._current_event, {}, "Current event should be set")

func test_choice_effect_heal():
	# Manually inject an event to test logic deterministically
	ec._current_event = {
		"title": "Test Heal",
		"text": "Heal test",
		"choices": [
			{
				"text": "Heal 10",
				"outcome": { "type": "heal", "amount": 10 }
			}
		]
	}
	
	gc.player_hp = 50
	gc.max_hp = 100
	
	watch_signals(ec)
	ec.select_choice(0)
	
	assert_eq(gc.player_hp, 60, "Should have healed 10 HP")
	assert_signal_emitted(ec, "event_completed")

func test_choice_effect_gold():
	# Manually inject an event to test logic
	ec._current_event = {
		"title": "Test Gold",
		"choices": [
			{
				"text": "Get Gold",
				"outcome": { "type": "resource", "resource": "gold", "amount": 50 }
			}
		]
	}
	
	gc.verdant_shards = 0
	ec.select_choice(0)
	
	assert_eq(gc.verdant_shards, 50, "Should have gained 50 shards")

func test_choice_cost_hp():
	# Manually inject an event
	ec._current_event = {
		"title": "Test Cost",
		"choices": [
			{
				"text": "Lose HP",
				"outcome": { "type": "none", "cost_hp": 10 }
			}
		]
	}
	
	gc.player_hp = 50
	ec.select_choice(0)
	
	assert_eq(gc.player_hp, 40, "Should have lost 10 HP")
