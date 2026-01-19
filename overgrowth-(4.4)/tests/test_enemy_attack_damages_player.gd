extends GutTest

# Test: enemy with {"type":"attack","value":7} reduces player hp by 7 after End Turn

func test_enemy_attack_damages_player():
	# Setup systems
	var game_controller = get_node("/root/GameController")
	var combat_system = get_node("/root/CombatSystem")
	
	assert_not_null(game_controller, "GameController should be available")
	assert_not_null(combat_system, "CombatSystem should be available")
	
	# Set initial player HP
	game_controller.player_hp = 50
	var initial_hp = game_controller.player_hp
	
	# Create enemy with attack intent
	var enemy_data = {
		"name": "TestEnemy",
		"hp": 20,
		"max_hp": 20,
		"block": 0,
		"intent": {"type": "attack", "value": 7}
	}
	
	# Set up combat with this enemy
	combat_system.begin_encounter([enemy_data])
	
	# Verify enemy was created with correct intent
	var enemies = combat_system.get_enemies()
	assert_gt(enemies.size(), 0, "Should have at least one enemy")
	
	var enemy = enemies[0]
	assert_eq(enemy.get("intent", {}).get("type", ""), "attack", "Enemy should have attack intent")
	assert_eq(enemy.get("intent", {}).get("value", 0), 7, "Enemy should attack for 7 damage")
	
	# End turn to trigger enemy phase
	game_controller.end_turn()
	
	# Wait a frame for deferred calls
	await get_tree().process_frame
	
	# Check that player HP was reduced by 7
	var final_hp = game_controller.player_hp
	assert_eq(final_hp, initial_hp - 7, "Player HP should be reduced by 7 (from %d to %d)" % [initial_hp, final_hp])
