extends Control

# MapScene.gd
# UI for Room Deck selection (3 Choices)

const CardBtnScene = preload("res://Scenes/UI/Map/RoomCardButton.tscn")

@onready var layer_label = $VBox/TopInfo/LayerLabel
@onready var prog_label = $VBox/TopInfo/ProgressLabel
@onready var grid = $VBox/CenterContainer/Grid
@onready var wait_label = $VBox/CenterContainer/WaitLabel

var map_controller: Node

func _ready() -> void:
	map_controller = get_node_or_null("/root/MapController")
	if map_controller:
		map_controller.choices_ready.connect(_on_choices_ready)
		map_controller.layer_changed.connect(_on_layer_changed)
		
		# Initial state update
		_update_progress()
		if map_controller.active_choices.size() > 0:
			_render_choices(map_controller.active_choices)
		else:
			# Maybe first load, wait for signal or force draw?
			# MapController might have emitted before we connected?
			# Check logic: MapController draws at start_run.
			# If we load Scene AFTER start_run, we might miss signal.
			# So we must verify active_choices.
			pass

func _update_progress() -> void:
	if map_controller:
		layer_label.text = map_controller.active_layer_name
		# 1-indexed for display
		prog_label.text = "Room %d / %d" % [map_controller.current_room_index + 1, MapController.ROOMS_PER_LAYER]

func _on_layer_changed(_idx, name_str) -> void:
	layer_label.text = name_str
	_update_progress()

func _on_choices_ready(cards: Array) -> void:
	_render_choices(cards)
	_update_progress()

func _render_choices(cards: Array) -> void:
	for c in grid.get_children():
		c.queue_free()
		
	if cards.is_empty():
		wait_label.visible = true
		return
		
	wait_label.visible = false
	for card in cards:
		var btn = CardBtnScene.instantiate()
		grid.add_child(btn)
		btn.setup(card)
		btn.card_selected.connect(_on_card_selected)

func _on_card_selected(card) -> void:
	if map_controller:
		map_controller.select_card(card)
