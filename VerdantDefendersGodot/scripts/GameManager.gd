extends Node2D
class_name GameManager

var current_scene : Node = null
var game_controller : Node = null

func _ready():
	# Start with the main game
	_start_game()

func _start_game():
	# Load the main game scene
	if current_scene:
		current_scene.queue_free()
	
	var main_scene = load("res://Scenes/Main.tscn").instantiate()
	add_child(main_scene)
	current_scene = main_scene
	
	# Find and store reference to game controller
	game_controller = get_tree().get_nodes_in_group("game_controller")[0] if get_tree().get_nodes_in_group("game_controller").size() > 0 else null

func _show_main_menu():
	if current_scene:
		current_scene.queue_free()
	
	var menu_scene = load("res://Scenes/MainMenu.tscn").instantiate()
	add_child(menu_scene)
	current_scene = menu_scene
	menu_scene.connect("start_game", Callable(self, "_start_game"))

func _on_game_over():
	# Could show game over screen or return to menu
	print("Game Over - Restarting...")
	call_deferred("_start_game")

func _on_victory():
	print("Victory! Starting new run...")
	call_deferred("_start_game")