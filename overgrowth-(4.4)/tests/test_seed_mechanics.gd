extends GutTest

var game_controller: Node
var effect_system: Node
var enemy_view: EnemyView

func before_each():
	# Set up test environment
	game_controller = preload("res://scripts/GameController.gd").new()
	game_controller.name = "GameController"
	add_child_autofree(game_controller)
	
	effect_system = preload("res://scripts/EffectSystem.gd").new()
	effect_system.name = "EffectSystem"
	add_child_autofree(effect_system)
	
	# Create a mock enemy
	enemy_view = preload("res://scripts/EnemyView.gd").new()
	enemy_view.name = "TestEnemy"
	add_child_autofree(enemy_view)
	
	# Initialize enemy data
	enemy_view.data = {
		"name": "Test Enemy",
		"hp": 20,
		"max_hp": 20,
		"statuses": {}
	}

func test_plant_seed_increases_seeds():
	# Arrange
	game_controller.player_state.seeds = 0
	var effect = {"type": "plant_seed", "count": 2}
	var ctx = {"player": game_controller}
	
	# Act
	effect_system._resolve_effect(effect, null, ctx)
	
	# Assert
	assert_eq(game_controller.player_state.seeds, 2, "Seeds should increase by 2")

func test_consume_seeds_spends_and_exposes_ctx():
	# Arrange
	game_controller.player_state.seeds = 5
	var effect = {"type": "consume_seeds", "count": 3}
	var ctx = {"player": game_controller}
	
	# Act
	effect_system._resolve_effect(effect, null, ctx)
	
	# Assert
	assert_eq(game_controller.player_state.seeds, 2, "Should have 2 seeds remaining")
	assert_eq(ctx.get("consumed_seeds", 0), 3, "Context should track consumed seeds")

func test_consume_seeds_up_to_limits_consumption():
	# Arrange
	game_controller.player_state.seeds = 2
	var effect = {"type": "consume_seeds", "up_to": 5}
	var ctx = {"player": game_controller}
	
	# Act
	effect_system._resolve_effect(effect, null, ctx)
	
	# Assert
	assert_eq(game_controller.player_state.seeds, 0, "Should consume all available seeds")
	assert_eq(ctx.get("consumed_seeds", 0), 2, "Should only consume available seeds")

func test_if_condition_on_seeds_triggers_effect():
	# Arrange
	game_controller.player_state.seeds = 5
	var effect = {
		"type": "if",
		"condition": {"left": "player.seeds", "op": ">=", "right": 3},
		"then": [{"type": "plant_seed", "count": 1}],
		"else": []
	}
	var ctx = {"player": game_controller}
	
	# Act
	effect_system._resolve_effect(effect, null, ctx)
	
	# Assert
	assert_eq(game_controller.player_state.seeds, 6, "Should have gained 1 seed from condition")

func test_apply_seeded_status_to_enemy():
	# Arrange
	var effect = {"type": "apply_status", "status": "seeded", "amount": 2, "target": "enemy"}
	var ctx = {"player": game_controller}
	
	# Act
	effect_system._resolve_effect(effect, enemy_view, ctx)
	
	# Assert
	assert_eq(enemy_view.get_status("seeded"), 2, "Enemy should have 2 seeded stacks")

func test_consume_status_removes_stacks_and_triggers_effects():
	# Arrange
	enemy_view.apply_status("seeded", 3)
	var effect = {
		"type": "consume_status",
		"status": "seeded",
		"target": "enemy",
		"up_to": 2,
		"per_stack": [{"type": "plant_seed", "count": 1}]
	}
	var ctx = {"player": game_controller}
	game_controller.player_state.seeds = 0
	
	# Act
	effect_system._resolve_effect(effect, enemy_view, ctx)
	
	# Assert
	assert_eq(enemy_view.get_status("seeded"), 1, "Should have 1 seeded stack remaining")
	assert_eq(game_controller.player_state.seeds, 2, "Should have gained 2 seeds from consumed stacks")

func test_seeded_condition_evaluates_correctly():
	# Arrange
	enemy_view.apply_status("seeded", 2)
	var condition = {"left": "target.status.seeded", "op": ">=", "right": 1}
	var ctx = {"player": game_controller}
	
	# Act
	var result = effect_system._eval_cond(condition, enemy_view, ctx)
	
	# Assert
	assert_true(result, "Condition should evaluate to true when enemy has seeded stacks")

func test_seeded_condition_fails_when_no_stacks():
	# Arrange
	var condition = {"left": "target.status.seeded", "op": ">=", "right": 1}
	var ctx = {"player": game_controller}
	
	# Act
	var result = effect_system._eval_cond(condition, enemy_view, ctx)
	
	# Assert
	assert_false(result, "Condition should evaluate to false when enemy has no seeded stacks")
