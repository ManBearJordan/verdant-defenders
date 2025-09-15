extends Panel

var card_data : CardData
var game_controller : Node

@onready var name_label = $NameLabel
@onready var cost_label = $CostLabel

func setup(data):
	card_data = data
	name_label.text = card_data.name
	cost_label.text = str(card_data.cost)
	# Find the game controller in the scene tree
	game_controller = get_tree().get_nodes_in_group("game_controller")[0] if get_tree().get_nodes_in_group("game_controller").size() > 0 else null

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		if game_controller and game_controller.has_method("play_card"):
			game_controller.play_card(card_data.name)
		elif get_node("/root/Main/Game"):
			get_node("/root/Main/Game").play_card(card_data.name)
