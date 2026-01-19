extends GutTest

# Test that plays a 7-damage card; enemy HP drops by 7

func before_each():
	var sigil_system = get_node_or_null("/root/SigilSystem")
	if sigil_system:
		sigil_system.clear_all_sigils()

class MockPlayer:
	extends Node
	var hp: int = 0
	var max_hp: int = 100
	var block: int = 0

func test_effect_deal_damage():
	# Setup
	var effect_system = get_node_or_null("/root/EffectSystem")
	var targeting_system = get_node_or_null("/root/TargetingSystem")
	
	assert_not_null(effect_system, "EffectSystem should be available")
	assert_not_null(targeting_system, "TargetingSystem should be available")
	
	# Create a mock enemy
	var mock_enemy = HBoxContainer.new()
	mock_enemy.name = "TestEnemy"
	mock_enemy.set_script(preload("res://scripts/enemy.gd"))
	add_child_autofree(mock_enemy)
	
	# Setup enemy with 30 HP and 0 block
	mock_enemy.setup({
		"name": "Test Enemy",
		"hp": 30,
		"max_hp": 30,
		"block": 0,
		"intent": {"type": "attack", "value": 6}
	})
	
	# Verify initial enemy state
	assert_eq(mock_enemy.hp, 30, "Enemy should start with 30 HP")
	assert_eq(mock_enemy.block, 0, "Enemy should start with 0 block")
	
	# Set target
	targeting_system.set_target(mock_enemy)
	assert_eq(targeting_system.current_target, mock_enemy, "Target should be set")
	
	# Create a damage card
	var damage_card = {
		"id": "test_damage_card",
		"name": "Test Damage",
		"type": "Strike",
		"cost": 1,
		"effects": [{"type": "deal_damage", "amount": 7, "target": "enemy"}]
	}
	
	# Create context
	var ctx = {
		"source": self,
		"player": self,
		"enemies": null
	}
	
	# Resolve the card
	effect_system.resolve_card(damage_card, mock_enemy, ctx)
	
	# Verify enemy took damage
	assert_eq(mock_enemy.hp, 23, "Enemy should have 23 HP after taking 7 damage")
	assert_eq(mock_enemy.block, 0, "Enemy block should remain 0")

func test_effect_block_then_damage():
	# Test: enemy block 5 → 7 dmg → block 0, HP −2
	var effect_system = get_node_or_null("/root/EffectSystem")
	var targeting_system = get_node_or_null("/root/TargetingSystem")
	
	# Create a mock enemy with block
	var mock_enemy = HBoxContainer.new()
	mock_enemy.name = "TestEnemyWithBlock"
	mock_enemy.set_script(preload("res://scripts/enemy.gd"))
	add_child_autofree(mock_enemy)
	
	# Setup enemy with 30 HP and 5 block
	mock_enemy.setup({
		"name": "Test Enemy",
		"hp": 30,
		"max_hp": 30,
		"block": 5,
		"intent": {"type": "attack", "value": 6}
	})
	
	# Verify initial enemy state
	assert_eq(mock_enemy.hp, 30, "Enemy should start with 30 HP")
	assert_eq(mock_enemy.block, 5, "Enemy should start with 5 block")
	
	# Set target
	targeting_system.set_target(mock_enemy)
	
	# Create a damage card (7 damage vs 5 block = 2 damage to HP)
	var damage_card = {
		"id": "test_damage_card",
		"name": "Test Damage",
		"type": "Strike",
		"cost": 1,
		"effects": [{"type": "deal_damage", "amount": 7, "target": "enemy"}]
	}
	
	# Create context
	var ctx = {
		"source": self,
		"player": self,
		"enemies": null
	}
	
	# Resolve the card
	effect_system.resolve_card(damage_card, mock_enemy, ctx)
	
	# Verify damage was absorbed by block first
	assert_eq(mock_enemy.hp, 28, "Enemy should have 28 HP (30 - 2 after block)")
	assert_eq(mock_enemy.block, 0, "Enemy block should be reduced to 0")

func test_effect_gain_block():
	# Test gain_block effect
	var effect_system = get_node_or_null("/root/EffectSystem")
	
	# Create a mock player
	var mock_player = MockPlayer.new()
	mock_player.name = "TestPlayer"
	mock_player.hp = 50
	mock_player.max_hp = 80
	mock_player.block = 0
	add_child_autofree(mock_player)
	
	# Create a block card
	var block_card = {
		"id": "test_block_card",
		"name": "Test Block",
		"type": "Tactic",
		"cost": 1,
		"effects": [{"type": "gain_block", "amount": 8, "target": "self"}]
	}
	
	# Create context
	var ctx = {
		"source": self,
		"player": mock_player,
		"enemies": null
	}
	
	# Resolve the card
	effect_system.resolve_card(block_card, null, ctx)
	
	# Verify player gained block
	assert_eq(mock_player.block, 8, "Player should have gained 8 block")

func test_effect_heal():
	# Test heal effect
	var effect_system = get_node_or_null("/root/EffectSystem")
	
	# Create a mock player with reduced HP
	var mock_player = MockPlayer.new()
	mock_player.name = "TestPlayer"
	mock_player.hp = 50
	mock_player.max_hp = 80
	add_child_autofree(mock_player)
	
	# Create a heal card
	var heal_card = {
		"id": "test_heal_card",
		"name": "Test Heal",
		"type": "Tactic",
		"cost": 1,
		"effects": [{"type": "heal", "amount": 10, "target": "self"}]
	}
	
	# Create context
	var ctx = {
		"source": self,
		"player": mock_player,
		"enemies": null
	}
	
	# Resolve the card
	effect_system.resolve_card(heal_card, null, ctx)
	
	# Verify player was healed
	assert_eq(mock_player.hp, 60, "Player should have 60 HP after healing 10")

func test_needs_target():
	# Test needs_target logic
	var effect_system = get_node_or_null("/root/EffectSystem")
	
	# Test Strike card needs target
	var strike_card = {
		"name": "Strike",
		"type": "Strike",
		"cost": 1,
		"effects": [{"type": "deal_damage", "amount": 6, "target": "enemy"}]
	}
	assert_true(effect_system.needs_target(strike_card), "Strike cards should need target")
	
	# Test block card doesn't need target
	var block_card = {
		"name": "Block",
		"type": "Tactic",
		"cost": 1,
		"effects": [{"type": "gain_block", "amount": 5, "target": "self"}]
	}
	assert_false(effect_system.needs_target(block_card), "Block cards should not need target")
	
	# Test card with requires_target flag
	var special_card = {
		"name": "Special",
		"type": "Tactic",
		"cost": 1,
		"requires_target": true,
		"effects": [{"type": "heal", "amount": 5, "target": "enemy"}]
	}
	assert_true(effect_system.needs_target(special_card), "Cards with requires_target should need target")

func test_can_play():
	# Test can_play logic
	var effect_system = get_node_or_null("/root/EffectSystem")
	
	var card = {
		"name": "Test Card",
		"cost": 2
	}
	
	# Test with sufficient energy
	var state_sufficient = {"energy": 3, "cost_discount": 0}
	assert_true(effect_system.can_play(card, state_sufficient), "Should be able to play with sufficient energy")
	
	# Test with insufficient energy
	var state_insufficient = {"energy": 1, "cost_discount": 0}
	assert_false(effect_system.can_play(card, state_insufficient), "Should not be able to play with insufficient energy")
	
	# Test with discount
	var state_discount = {"energy": 1, "cost_discount": 1}
	assert_true(effect_system.can_play(card, state_discount), "Should be able to play with discount")
