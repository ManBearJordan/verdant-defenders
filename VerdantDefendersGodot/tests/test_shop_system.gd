extends GutTest

var shop_system_script = load("res://scripts/ShopSystem.gd")
var game_controller_script = load("res://scripts/GameController.gd")
var deck_manager_script = load("res://scripts/DeckManager.gd")
var data_layer_script = load("res://scripts/DataLayer.gd")

var ss = null
var gc = null
var dm = null
var dl = null

func before_each():
	# Manual Autoload Setup
	if not has_node("/root/DataLayer"):
		dl = data_layer_script.new()
		dl.name = "DataLayer"
		get_tree().root.add_child(dl)
		autofree(dl)
	else: dl = get_node("/root/DataLayer")
	
	if not has_node("/root/GameController"):
		gc = game_controller_script.new()
		gc.name = "GameController"
		get_tree().root.add_child(gc)
		autofree(gc)
	else: gc = get_node("/root/GameController")
	
	if not has_node("/root/DeckManager"):
		dm = deck_manager_script.new()
		dm.name = "DeckManager"
		get_tree().root.add_child(dm)
		autofree(dm)
	else: dm = get_node("/root/DeckManager")
	
	ss = shop_system_script.new()
	ss.name = "ShopSystem"
	add_child_autofree(ss)
	
	# DI
	ss.game_controller = gc
	ss.deck_manager = dm
	ss.data_layer = dl
	
	# Ensure basic config exists in ss or mocked via private method if needed
	# But _ready calls _read_json logic which might fail if file missing/invalid
	# Just ensure defaults are good.

func test_generate_inventory():
	gc.current_class = "growth"
	var inv = ss.generate_inventory(5, "growth")
	assert_eq(inv.size(), 5, "Should generate 5 items")

func test_price_calculation():
	var card = {"rarity": "rare"}
	var price = ss.price_for_card(card)
	# Assuming shop_config default or loaded
	assert_gt(price, 0, "Price should be positive")

func test_purchase_card():
	# Setup
	gc.verdant_shards = 100
	var card: Dictionary = {"name": "Test Card", "rarity": "common", "cost": 1}
	var inv: Array[Dictionary] = [card]
	ss.current_inventory = inv
	
	# Action
	var result = ss.purchase(0)
	
	# Assert
	assert_true(result, "Purchase should succeed")
	assert_lt(gc.verdant_shards, 100, "Should spend shards")
	assert_gt(dm.discard_pile.size(), 0, "Card should be in discard")
	assert_eq(ss.current_inventory.size(), 0, "Inventory should be empty")

func test_heal_player():
	gc.player_hp = 50
	gc.max_hp = 100
	gc.verdant_shards = 100
	
	# heal_step is usually 10, cost is 10 (1 * 10)
	var result = ss.heal_player(10)
	
	assert_true(result, "Heal should succeed")
	assert_eq(gc.player_hp, 60, "HP should increase")
	assert_lt(gc.verdant_shards, 100, "Should spend shards")

func test_remove_card():
	gc.verdant_shards = 100
	var card: Dictionary = {"name": "Bad Card"}
	var deck: Array[Dictionary] = [card]
	dm.draw_pile = deck
	
	var result = ss.remove_card_from_deck(card)
	
	assert_true(result, "Removal should succeed")
	assert_eq(dm.draw_pile.size(), 0, "Card should be gone")
	assert_lt(gc.verdant_shards, 100, "Should spend shards")
