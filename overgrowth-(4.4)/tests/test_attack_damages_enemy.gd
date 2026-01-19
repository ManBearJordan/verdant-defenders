extends GutTest

# Test that with a target selected, a 7-damage attack reduces enemy HP by 7 (0 block)

func before_each():
	var sigil_system = get_node_or_null("/root/SigilSystem")
	if sigil_system:
		sigil_system.clear_all_sigils()

func test_attack_damages_enemy():
	# Setup
	var targeting_system = get_node_or_null("/root/TargetingSystem")
	var card_rules = get_node_or_null("/root/CardRules")
	
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
	
	# Create damage effect
	var damage_effects: Array[Dictionary] = [{"type": "deal_damage", "amount": 7}]
	var ctx = {"source": self}
	
	# Apply damage
	card_rules.apply_effects(mock_enemy, damage_effects, ctx)
	
	# Verify enemy took damage
	assert_eq(mock_enemy.hp, 23, "Enemy should have 23 HP after taking 7 damage")
	assert_eq(mock_enemy.block, 0, "Enemy block should remain 0")

func test_attack_respects_block():
	# Setup
	var targeting_system = get_node_or_null("/root/TargetingSystem")
	var card_rules = get_node_or_null("/root/CardRules")
	
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
	
	# Create damage effect (7 damage vs 5 block = 2 damage to HP)
	var damage_effects: Array[Dictionary] = [{"type": "deal_damage", "amount": 7}]
	var ctx = {"source": self}
	
	# Apply damage
	card_rules.apply_effects(mock_enemy, damage_effects, ctx)
	
	# Verify damage was absorbed by block first
	assert_eq(mock_enemy.hp, 28, "Enemy should have 28 HP (30 - 2 after block)")
	assert_eq(mock_enemy.block, 0, "Enemy block should be reduced to 0")

func test_attack_with_insufficient_damage_only_reduces_block():
	# Setup
	var targeting_system = get_node_or_null("/root/TargetingSystem")
	var card_rules = get_node_or_null("/root/CardRules")
	
	# Create a mock enemy with high block
	var mock_enemy = HBoxContainer.new()
	mock_enemy.name = "TestEnemyHighBlock"
	mock_enemy.set_script(preload("res://scripts/enemy.gd"))
	add_child_autofree(mock_enemy)
	
	# Setup enemy with 30 HP and 10 block
	mock_enemy.setup({
		"name": "Test Enemy",
		"hp": 30,
		"max_hp": 30,
		"block": 10,
		"intent": {"type": "attack", "value": 6}
	})
	
	# Verify initial enemy state
	assert_eq(mock_enemy.hp, 30, "Enemy should start with 30 HP")
	assert_eq(mock_enemy.block, 10, "Enemy should start with 10 block")
	
	# Set target
	targeting_system.set_target(mock_enemy)
	
	# Create damage effect (7 damage vs 10 block = 0 damage to HP)
	var damage_effects: Array[Dictionary] = [{"type": "deal_damage", "amount": 7}]
	var ctx = {"source": self}
	
	# Apply damage
	card_rules.apply_effects(mock_enemy, damage_effects, ctx)
	
	# Verify only block was reduced
	assert_eq(mock_enemy.hp, 30, "Enemy HP should remain 30")
	assert_eq(mock_enemy.block, 3, "Enemy block should be reduced to 3 (10 - 7)")
