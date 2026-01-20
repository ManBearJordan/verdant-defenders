extends Control

# DeckViewScreen.gd
# Allows player to view deck and select a card (for removal/upgrade).

signal card_selected(card_id: String) # Not Card resource because deck is Strings currently
signal cancelled

@onready var grid = $VBox/Scroll/Center/Grid
@onready var title_lbl = $VBox/Header/Title
@onready var cancel_btn = $VBox/Header/CancelBtn

const CARD_SCENE = preload("res://Scenes/CardView.tscn")

var mode: String = "view" # view, remove
var run_controller: Node

func _ready() -> void:
	run_controller = get_node_or_null("/root/RunController")
	cancel_btn.pressed.connect(_on_cancel)
	
	call_deferred("_populate")

func setup(p_mode: String) -> void:
	mode = p_mode
	if mode == "remove":
		title_lbl.text = "Select Card to Remove"
		cancel_btn.visible = true
	elif mode == "upgrade":
		title_lbl.text = "Select Card to Upgrade"
		cancel_btn.visible = true
	else:
		title_lbl.text = "Deck View"
		cancel_btn.visible = true # Always allow back

func _populate() -> void:
	if not run_controller: return
	
	# Clear
	for c in grid.get_children():
		c.queue_free()
		
	var deck_ids = run_controller.deck
	
	# We need DataLayer to resolve Card IDs to Resources for display
	var data_layer = get_node_or_null("/root/DataLayer")
	
	for i in range(deck_ids.size()):
		var card_id = deck_ids[i]
		var view = CARD_SCENE.instantiate()
		grid.add_child(view)
		
		# Resource Binding
		var card_res = null
		if data_layer:
			card_res = data_layer.get_card(card_id)
			
		if card_res:
			if view.has_method("setup"):
				view.setup(card_res)
		else:
			# Fallback
			if view.has_method("set_title"):
				view.set_title(card_id.capitalize())
		
		# Connect Click
		if mode == "remove" or mode == "upgrade":
			# Make it clickable
			if view.has_signal("pressed"):
				view.pressed.connect(_on_card_clicked.bind(card_id))
			elif view.find_child("ClickCatcher"):
				view.find_child("ClickCatcher").pressed.connect(_on_card_clicked.bind(card_id))
				view.mouse_filter = Control.MOUSE_FILTER_PASS

func _bind_card_visuals(view, card_id: String) -> void:
	# Deprecated by _populate logic using DataLayer
	pass

func _on_card_clicked(card_id: String) -> void:
	print("DeckView: Selected (Mode: %s) %s" % [mode, card_id])
	card_selected.emit(card_id)

func _on_cancel() -> void:
	cancelled.emit()
