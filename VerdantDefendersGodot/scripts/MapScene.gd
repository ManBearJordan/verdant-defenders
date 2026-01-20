extends Control

# MapScene.gd
# UI for Room Deck selection (3 Choices)

const CardBtnScene = preload("res://Scenes/UI/Map/RoomCardButton.tscn")

@onready var layer_label = $VBox/TopInfo/LayerLabel
@onready var prog_label = $VBox/TopInfo/ProgressLabel
@onready var grid = $VBox/CenterContainer/Grid
@onready var wait_label = $VBox/CenterContainer/WaitLabel

var map_controller: Node

@onready var ribbon_container = $VBox/PathRibbon
@onready var boss_btn = $VBox/CenterContainer/BossButton

func _ready() -> void:
	map_controller = get_node_or_null("/root/MapController")
	
	var deck_btn = find_child("DeckButton")
	if deck_btn:
		deck_btn.pressed.connect(_on_deck_pressed)
		
	if boss_btn:
		boss_btn.pressed.connect(_on_boss_pressed)

	if map_controller:
		map_controller.choices_ready.connect(_on_choices_ready)
		map_controller.layer_changed.connect(_on_layer_changed)
		
		# Initial state update
		_update_ui()

func _update_ui() -> void:
	if map_controller:
		_update_progress()
		if map_controller.active_choices.size() > 0:
			_render_choices(map_controller.active_choices)
		_render_ribbon()

func _render_ribbon() -> void:
	if not ribbon_container: return
	
	# Clear existing
	for c in ribbon_container.get_children():
		c.queue_free()
		
	# Draw 15 steps
	# 0-13 = Rooms, 14 = Boss
	var current = map_controller.current_room_index
	
	for i in range(15):
		var icon = ColorRect.new()
		icon.custom_minimum_size = Vector2(32, 32)
		
		# State Logic
		if i < current:
			# Completed
			icon.color = Color.GREEN
		elif i == current:
			# Current
			icon.color = Color.WHITE
			icon.custom_minimum_size = Vector2(40, 40) # Highlight
		else:
			# Future
			icon.color = Color(0.3, 0.3, 0.3)
			
		# Boss Node (14)
		if i == 14:
			icon.color = Color.RED
			icon.custom_minimum_size = Vector2(48, 48)
			if i < current: icon.color = Color.DARK_RED # Defeated? Loop resets though.
			if i == current: icon.color = Color(1, 0, 0, 1) # Bright Red
			
		ribbon_container.add_child(icon)

func _render_choices(cards: Array) -> void:
	for c in grid.get_children():
		c.queue_free()
	
	wait_label.visible = false
	boss_btn.visible = false
	grid.visible = true
	
	# Check for Boss State (Single card "BOSS" type)
	if cards.size() == 1 and cards[0].type == "BOSS":
		grid.visible = false
		boss_btn.visible = true
		boss_btn.text = "ENTER %s BOSS" % map_controller.active_layer_name.to_upper()
		return
		
	if cards.is_empty():
		wait_label.visible = true
		return
		
	for card in cards:
		var btn = CardBtnScene.instantiate()
		grid.add_child(btn)
		btn.setup(card)
		btn.card_selected.connect(_on_card_selected)

func _on_boss_pressed() -> void:
	# Trigger Boss Transition
	# We select the single BOSS card in active_choices[0]
	if map_controller.active_choices.size() > 0:
		_on_card_selected(map_controller.active_choices[0])

func _on_choices_ready(cards: Array) -> void:
	_update_ui()
	
func _update_progress() -> void:
	if map_controller:
		layer_label.text = map_controller.active_layer_name
		# 1-indexed for display
		prog_label.text = "Room %d / %d" % [map_controller.current_room_index + 1, MapController.ROOMS_PER_LAYER]
		_render_ribbon()

func _on_layer_changed(_idx, name_str) -> void:
	layer_label.text = name_str
	_update_progress()

func _on_card_selected(card) -> void:
	map_controller.select_card(card)
	
	# Transition logic (as requested)
	var rc = get_node_or_null("/root/RunController")
	if rc:
		match card.type:
			"COMBAT", "ELITE", "MINI_BOSS":
				rc.start_combat_event(card.type)
			"SHOP":
				rc.goto_shop()
			"EVENT":
				rc.goto_event()
			"TREASURE":
				rc.goto_reward("treasure")
			"BOSS":
				# Added BOSS case to handle boss transition properly
				rc.start_combat_event("boss")
			_:
				print("MapScene: Unknown transition for " + card.type)

func _on_deck_pressed() -> void:
	var rc = get_node_or_null("/root/RunController")
	if rc:
		rc.goto_deck_view("view", "map")
