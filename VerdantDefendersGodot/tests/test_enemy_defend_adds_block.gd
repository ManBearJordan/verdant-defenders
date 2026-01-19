extends GutTest

# Test that after End Turn with intent defend 6, enemy gains 6 block

func test_enemy_defend_adds_block():
	# Setup
	var game_controller = GameController
	var combat_system = CombatSystem
	
	# Create a mock enemy with defend intent
	var mock_enemy = Node2D.new()
	mock_enemy.name = "TestEnemyDefend"
	mock_enemy.set_script(preload("res://scripts/enemy.gd"))
	add_child_autofree(mock_enemy)
	
	# Setup enemy with defend intent
	mock_enemy.setup({
		"name": "Test Enemy",
		"hp": 30,
		"max_hp": 30,
		"block": 0,
		"intent": {"type": "defend", "value": 6}
	})
	
	# Verify initial state
	assert_eq(mock_enemy.hp, 30, "Enemy should start with 30 HP")
	assert_eq(mock_enemy.block, 0, "Enemy should start with 0 block")
	assert_eq(mock_enemy.intent.get("type"), "defend", "Enemy should have defend intent")
	assert_eq(mock_enemy.intent.get("value"), 6, "Enemy should defend for 6")
	
	# Execute the enemy's intent directly
	mock_enemy.execute_intent()
	
	# Verify enemy gained block
	assert_eq(mock_enemy.block, 6, "Enemy should have gained 6 block")
	assert_eq(mock_enemy.hp, 30, "Enemy HP should remain unchanged")

func test_enemy_attack_intent():
	# Setup
	var game_controller = GameController
	var combat_system = CombatSystem
	
	# Create a mock enemy with attack intent
	var mock_enemy = Node2D.new()
	mock_enemy.name = "TestEnemyAttack"
	mock_enemy.set_script(preload("res://scripts/enemy.gd"))
	add_child_autofree(mock_enemy)
	
	# Setup enemy with attack intent
	mock_enemy.setup({
		"name": "Test Enemy",
		"hp": 30,
		"max_hp": 30,
		"block": 0,
		"intent": {"type": "attack", "value": 8}
	})
	
	# Setup player state
	game_controller.player_hp = 80
	combat_system.player_block = 0
	
	# Verify initial state
	assert_eq(mock_enemy.intent.get("type"), "attack", "Enemy should have attack intent")
	assert_eq(mock_enemy.intent.get("value"), 8, "Enemy should attack for 8")
	assert_eq(game_controller.player_hp, 80, "Player should start with 80 HP")
	assert_eq(combat_system.player_block, 0, "Player should start with 0 block")
	
	# Execute the enemy's intent
	mock_enemy.execute_intent()
	
	# Verify player took damage
	assert_eq(game_controller.player_hp, 72, "Player should have 72 HP after taking 8 damage")
	assert_eq(combat_system.player_block, 0, "Player block should remain 0")

func test_enemy_attack_respects_player_block():
	# Setup
	var game_controller = GameController
	var combat_system = CombatSystem
	
	# Create a mock enemy with attack intent
	var mock_enemy = Node2D.new()
	mock_enemy.name = "TestEnemyAttackBlock"
	mock_enemy.set_script(preload("res://scripts/enemy.gd"))
	add_child_autofree(mock_enemy)
	
	# Setup enemy with attack intent
	mock_enemy.setup({
		"name": "Test Enemy",
		"hp": 30,
		"max_hp": 30,
		"block": 0,
		"intent": {"type": "attack", "value": 8}
	})
	
	# Setup player state with block
	game_controller.player_hp = 80
	combat_system.player_block = 5
	
	# Verify initial state
	assert_eq(game_controller.player_hp, 80, "Player should start with 80 HP")
	assert_eq(combat_system.player_block, 5, "Player should start with 5 block")
	
	# Execute the enemy's intent (8 damage vs 5 block = 3 damage to HP)
	mock_enemy.execute_intent()
	
	# Verify damage was absorbed by block first
	assert_eq(game_controller.player_hp, 77, "Player should have 77 HP (80 - 3 after block)")
	assert_eq(combat_system.player_block, 0, "Player block should be reduced to 0")

func test_intent_alternates_after_execution():
	# Setup
	var mock_enemy = Node2D.new()
	mock_enemy.name = "TestEnemyAlternate"
	mock_enemy.set_script(preload("res://scripts/enemy.gd"))
	add_child_autofree(mock_enemy)
	
	# Setup enemy with defend intent
	mock_enemy.setup({
		"name": "Test Enemy",
		"hp": 30,
		"max_hp": 30,
		"block": 0,
		"intent": {"type": "defend", "value": 6}
	})
	
	# Verify initial intent
	assert_eq(mock_enemy.intent.get("type"), "defend", "Enemy should start with defend intent")
	
	# Execute intent
	mock_enemy.execute_intent()
	
	# Verify intent changed to attack
	assert_eq(mock_enemy.intent.get("type"), "attack", "Enemy should switch to attack intent")
	assert_eq(mock_enemy.intent.get("value"), 6, "Enemy should attack for 6")
	
	# Execute again
	mock_enemy.execute_intent()
	
	# Verify intent changed back to defend
	assert_eq(mock_enemy.intent.get("type"), "defend", "Enemy should switch back to defend intent")
	assert_eq(mock_enemy.intent.get("value"), 5, "Enemy should defend for 5")
