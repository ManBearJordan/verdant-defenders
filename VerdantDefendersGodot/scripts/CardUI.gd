extends Panel

var card_data : CardData

onready var name_label = $NameLabel
onready var cost_label = $CostLabel

func setup(data):
    card_data = data
    name_label.text = card_data.name
    cost_label.text = str(card_data.cost)

func _gui_input(event):
    if event is InputEventMouseButton and event.pressed:
        get_node("/root/Main/Game").play_card(card_data.name)
