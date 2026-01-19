extends Node

@onready var energy_label := get_node("UI/EnergyLabel")
@onready var end_turn_button := get_node("UI/EndTurnButton")
@onready var deck_button := get_node("UI/DeckButton")

@onready var card_system := get_node("/root/CardSystem")
@onready var room_controller := get_node("/root/RoomController")
@onready var deck_view := get_node("/root/DeckView")

func _ready():
	end_turn_button.connect("pressed", _on_end_turn_pressed)
	deck_button.connect("pressed", _on_deck_pressed)
	update_energy_display()

func update_energy_display():
	energy_label.text = "Energy: %d" % card_system.energy

func _on_end_turn_pressed():
	card_system.end_turn()
	# You could trigger enemy turn here

func _on_deck_pressed():
	deck_view.open(get_node("/root/GameController").current_deck, get_node("/root/GameController").current_sigils)
