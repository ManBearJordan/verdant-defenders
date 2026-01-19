extends Control

func open(deck: Array, sigils: Array):
	$Background/VBox/DeckCards.clear()
	for card_id in deck:
		var card_data = DataLayer.get_card(card_id)
		var display_text = card_data.get("name", card_id)
		$Background/VBox/DeckCards.add_item(display_text)

	$Background/VBox/Sigils.clear()
	for sigil_id in sigils:
		var sigil_data = DataLayer.get_sigil(sigil_id)
		var sigil_text = sigil_data.get("name", sigil_id)
		$Background/VBox/Sigils.add_item(sigil_text)

	self.visible = true

func _ready():
	$Background/VBox/CloseButton.connect("pressed", self, "_on_close_pressed")

func _on_close_pressed():
	self.visible = false
