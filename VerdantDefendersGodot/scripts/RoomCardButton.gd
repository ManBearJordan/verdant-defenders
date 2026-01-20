extends Button

signal card_selected(card: RoomCard)

var card_data: RoomCard

@onready var icon_rect = $VBox/Icon
@onready var title_lbl = $VBox/Title
@onready var type_lbl = $VBox/TypeLabel

func _ready() -> void:
	pressed.connect(_on_pressed)

func setup(card: RoomCard) -> void:
	card_data = card
	title_lbl.text = card.title
	type_lbl.text = card.type
	
	if card.icon_path != "" and ResourceLoader.exists(card.icon_path):
		icon_rect.texture = load(card.icon_path)
	else:
		icon_rect.texture = null
		
	# Elite/Mini-Boss Visuals
	if card.type == "ELITE" or card.type == "MINI_BOSS":
		# Add a gold/red hue or border
		modulate = Color(1.2, 0.8, 0.8) # Reddish tint
		type_lbl.modulate = Color(1, 0.5, 0.5)
		title_lbl.text = "[!] " + card.title
	else:
		modulate = Color.WHITE
		type_lbl.modulate = Color(0.7, 0.7, 0.7)

func _on_pressed() -> void:
	if card_data:
		card_selected.emit(card_data)
