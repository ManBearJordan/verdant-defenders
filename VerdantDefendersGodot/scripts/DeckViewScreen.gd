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
	elif mode == "sell":
		title_lbl.text = "Select Card to Sell (+50 Shards)"
		cancel_btn.visible = true
	elif mode == "sacrifice_sigil":
		title_lbl.text = "Sacrifice Card for Sigil"
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
		
		# Resource Binding (Strict)
		var card_res = null
		if data_layer:
			card_res = data_layer.get_card(card_id)
			
		if card_res:
			var art_texture: Texture2D = null
			if card_res.art_path != "":
				if ResourceLoader.exists(card_res.art_path):
					art_texture = load(card_res.art_path)
				else:
					push_error("DeckView: Art path not found: " + card_res.art_path)
			
			# User requirement: If art_texture is null (failed load or empty path), print error if we expected it? 
			# Or just default behavior.
			# "If art_texture is null, display a placeholder and print an error to the console."
			# I'll rely on CardView's fallback for placeholder, but logs here.
			
			if view.has_method("setup"):
				view.setup(card_res, art_texture)
		else:
			push_error("DeckView: Failed to resolve card resource for ID: " + card_id)
			# Fallback or Skip? User says "log error; do not silently fall back".
			# We can show a placeholder or just error.
			# Let's show it with a warning visual if possible, or just error string
			if view.has_method("set_title"):
				view.set_title("MISSING: " + card_id)
		
		# Connect Click
		if mode in ["remove", "upgrade", "sell", "sacrifice_sigil"]:
			# Make it clickable
			if view.has_signal("pressed"):
				view.pressed.connect(_on_card_clicked.bind(card_id))
			elif view.find_child("ClickCatcher"):
				view.find_child("ClickCatcher").pressed.connect(_on_card_clicked.bind(card_id))
				view.mouse_filter = Control.MOUSE_FILTER_PASS

func _on_card_clicked(card_id: String) -> void:
	print("DeckView: Selected (Mode: %s) %s" % [mode, card_id])
	
	if mode == "remove" or mode == "sell" or mode == "sacrifice_sigil":
		card_selected.emit(card_id)
	elif mode == "upgrade":
		if run_controller and run_controller.has_method("upgrade_card"):
			run_controller.upgrade_card(card_id)
			cancelled.emit() # Close after action

func _on_cancel() -> void:
	cancelled.emit()
