extends Node
class_name GameFlowController

# State Machine for the Root Scene (Main.tscn)
# Enforces strictly ONE active screen at a time in ScreenLayer.

@onready var screen_layer: CanvasLayer = %ScreenLayer

# Scene Paths
const SCENES = {
	"MAIN_MENU": "res://Scenes/MainMenu.tscn",
	"MAP": "res://Scenes/UI/Map/MapScreen.tscn",
	"COMBAT": "res://Scenes/UI/Combat/CombatScreen.tscn",
	"REWARD": "res://Scenes/UI/Combat/RewardScreen.tscn",
	"SHOP": "res://Scenes/UI/Shop/ShopScreen.tscn",
	"EVENT": "res://Scenes/UI/Event/EventScreen.tscn",
	"REST": "res://Scenes/RestScreen.tscn",
	"GAME_OVER": "res://Scenes/WinLossUI.tscn",
	"VICTORY": "res://Scenes/WinLossUI.tscn"
}

func _ready() -> void:
	# Default start
	change_state("MAIN_MENU")

func change_state(state_key: String, params: Dictionary = {}) -> void:
	print("GameFlowController: Switching to state %s" % state_key)
	
	# 1. Clear current screen
	if screen_layer.get_child_count() > 0:
		for c in screen_layer.get_children():
			c.queue_free()
	
	# 2. Instantiate new screen
	if not SCENES.has(state_key):
		push_error("GameFlowController: Unknown state %s" % state_key)
		return
		
	var path = SCENES[state_key]
	var ps = load(path)
	if ps:
		var instance = ps.instantiate()
		screen_layer.add_child(instance)
		
		# Pass params if supported
		# FlowController (Autoload) stores them in transition_data usually,
		# but we can also push them directly if the screen has a setup method.
		var fc = get_node_or_null("/root/FlowController")
		if fc:
			fc.transition_data = params # Sync with autoload for compatibility
			
	else:
		push_error("GameFlowController: Failed to load scene %s" % path)
