extends "res://addons/gut/test.gd"

var deck_manager: Node

func before_each():
	deck_manager = load("res://scripts/DeckManager.gd").new()
	add_child(deck_manager)

func after_each():
	deck_manager.queue_free()

func test_enrich_card_applies_stats():
	# Create a mock card with enrichment data
	var card = {
		"name": "Test Strike",
		"damage": 5,
		"enrichment": {
			"damage": 8,
			"name_suffix": "+"
		}
	}
	
	var success = deck_manager.enrich_card(card)
	
	assert_true(success, "enrich_card returned false")
	assert_true(card.get("enriched", false), "Card should be marked enriched")
	assert_eq(card["damage"], 8, "Damage should remain 8 (enrichment overrides)")
	assert_eq(card["name"], "Test Strike+", "Name should have suffix")

func test_enrich_card_idempotent_name():
	var card = {
		"name": "Test Strike",
		"damage": 5,
		"enrichment": {
			"damage": 8,
			"name_suffix": "+"
		}
	}
	deck_manager.enrich_card(card)
	deck_manager.enrich_card(card) # Call generic enrichment again
	
	assert_eq(card["name"], "Test Strike+", "Name should not append suffix twice")
