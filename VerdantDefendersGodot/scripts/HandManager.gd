extends Node

@onready var hand_container := get_node("UI/HandContainer")
@onready var card_system := get_node("/root/CardSystem")

const CARD_UI_PATH := "res://Scenes/CardUI.tscn"

var current_hand := []

func draw_hand(count := 5):
	clear_hand()

	var deck = card_system.hand  # Already drawn logic in CardSystem
	for i in range(min(count, deck.size())):
		var card_id = deck[i]
		var card_node = load(CARD_UI_PATH).instantiate()
		card_node.setup(card_id)
		hand_container.add_child(card_node)
		current_hand.append(card_node)

func clear_hand():
	for card in current_hand:
		card.queue_free()
	current_hand.clear()
