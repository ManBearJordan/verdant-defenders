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
		
		# Setup View
		var card_res = null
		if data_layer:
			# Look up resource
			# Assuming DataLayer has a method or we load from standard path
			# RunController has loose IDs.
			# Let's try loading from Resources/Cards if path convention exists?
			# Or DeckManager?
			# Let's try standard path "res://resources/Cards/class/name.tres"?
			# Or iterate DataLayer registry?
			# For now, placeholder or try load.
			# Actually GameController had logic for this.
			pass
			
		# Hack: Use DeckManager helpers if available or create dummy
		# RunController keeps Strings. DeckManager keeps Resources?
		# Let's verify how to get Card Data.
		# `DataLayer.get_card_database()` returns Dict.
		
		# VIEW SETUP
		# If we can't get resource, we can't show art.
		# Assuming we can find it.
		
		_bind_card_visuals(view, card_id)
		
		# Connect Click
		if mode == "remove":
			# Make it clickable
			if view.has_signal("pressed"):
				view.pressed.connect(_on_card_clicked.bind(card_id))
			elif view.find_child("ClickCatcher"):
				view.find_child("ClickCatcher").pressed.connect(_on_card_clicked.bind(card_id))
				view.mouse_filter = Control.MOUSE_FILTER_PASS
			
			# Highlight hover? handled by CardView usually.

func _bind_card_visuals(view, card_id: String) -> void:
	# Try to find resource to call view.setup(res)
	# This logic is duped from many places. Should be in DataLayer.
	var res_path = "res://resources/Cards/%s.tres" % card_id
	if not ResourceLoader.exists(res_path):
		# Try looking in subfolders? Or Growth default.
		res_path = "res://resources/Cards/growth/%s.tres" % card_id
	
	if ResourceLoader.exists(res_path):
		var res = load(res_path)
		view.setup(res)
	else:
		# Fallback text
		if view.has_method("set_title"):
			view.set_title(card_id.capitalize())

func _on_card_clicked(card_id: String) -> void:
	print("DeckView: Selected ", card_id)
	card_selected.emit(card_id)

func _on_cancel() -> void:
	cancelled.emit()
