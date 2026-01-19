extends Control
class_name DeckView

const CARD_SCENE = preload("res://Scenes/CardView.tscn")

@onready var _title: Label = %TitleLabel
@onready var _grid: GridContainer = %CardGrid
@onready var _close_btn: Button = %CloseButton

func _ready() -> void:
	if _close_btn:
		_close_btn.pressed.connect(hide)
	hide()

func show_list(cards: Array, title_text: String = "Deck") -> void:
	if _title: _title.text = title_text + " (%d)" % cards.size()
	
	# Clear
	if _grid:
		for c in _grid.get_children():
			c.queue_free()
			
		# Populate
		for item in cards:
			# Item might be CardResource or String ID depending on DeckManager
			var card_res: CardResource = null
			if item is CardResource:
				card_res = item
			elif item is String:
				card_res = DataLayer.get_card(item)
				
			if card_res:
				var v = CARD_SCENE.instantiate()
				_grid.add_child(v)
				if v.has_method("setup"):
					v.setup(card_res)
				# Scale down slightly for list view?
				v.custom_minimum_size = Vector2(180, 260)
				v.scale = Vector2(0.8, 0.8) # Grid might need to account for scale or just use container sizing
				# Better to just set size flags
				v.scale = Vector2(1,1)
				
	show()
