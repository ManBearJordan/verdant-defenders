extends Control

@onready var label = $Label
@onready var button = $Button
@onready var flow = get_node("/root/FlowController")
@onready var dc = get_node("/root/DungeonController")

func _ready() -> void:
	if label: label.text = name
	if button: button.pressed.connect(_on_leave)

func _on_leave() -> void:
	if dc: dc.next_room()
	if flow: flow.return_to_map()
