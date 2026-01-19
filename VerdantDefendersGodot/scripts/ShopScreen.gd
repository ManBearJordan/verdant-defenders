extends Control

# ShopScreen.gd
# Visual Interface for Merchant's Hollow

const CARD_SCENE = preload("res://Scenes/CardView.tscn")

@onready var title_label = $Panel/VBox/Title
@onready var deck_info_label = $Panel/VBox/DeckInfo
@onready var cards_container = $Panel/VBox/Scroll/Items/CardsGrid
@onready var remove_btn = $Panel/VBox/Scroll/Items/Actions/RemoveButton
@onready var heal_btn = $Panel/VBox/Scroll/Items/Actions/HealButton
@onready var leave_btn = $Panel/VBox/LeaveButton

var shop_system: Node
var run_controller: Node

func _ready() -> void:
	shop_system = get_node_or_null("/root/ShopSystem")
	run_controller = get_node_or_null("/root/RunController")
	
	leave_btn.pressed.connect(_on_leave_pressed)
	remove_btn.pressed.connect(_on_remove_pressed)
	heal_btn.pressed.connect(_on_heal_pressed)
	
	_populate_shop()
	_update_ui()

func _populate_shop() -> void:
	if not shop_system: return
	
	# Generate Inventory if empty? Or RunController calls generate?
	# Typically RunController.goto_shop() implies entry.
	# ShopSystem state should persist during visit.
	# We'll assume inventory is generated on entry signal or manually here if empty.
	
	if shop_system.current_inventory.is_empty():
		var class_id = "growth"
		if run_controller: class_id = run_controller.current_class_id
		shop_system.generate_inventory(5, class_id)
		
	# Clear grid
	for c in cards_container.get_children():
		c.queue_free()
		
	# Populate Cards
	for i in range(shop_system.current_inventory.size()):
		var card = shop_system.current_inventory[i]
		var view = CARD_SCENE.instantiate()
		cards_container.add_child(view)
		
		if view.has_method("setup"):
			view.setup(card)
			
		# Price Tag (Hack: Use view label or add child?)
		var price = shop_system.price_for_card(card)
		var price_lbl = Label.new()
		price_lbl.text = "%d Shards" % price
		price_lbl.add_theme_color_override("font_color", Color.GOLD)
		price_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		price_lbl.position = Vector2(0, -20) # Float above?
		# Actually view is Control. layout logic needed.
		# For now, let's just make the card clickable 
		
		# Connect Click
		if view.has_signal("pressed"): # If CardView is button
			view.pressed.connect(_on_card_clicked.bind(i))
		elif view.find_child("ClickCatcher"):
			view.find_child("ClickCatcher").pressed.connect(_on_card_clicked.bind(i))
			
		# Add price label to view
		view.add_child(price_lbl)
		price_lbl.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		price_lbl.position.y += 250 # Below card

func _update_ui() -> void:
	if not run_controller: return
	
	var shards = run_controller.shards
	var deck_size = run_controller.deck.size()
	var hp = run_controller.player_hp
	var max_hp = run_controller.max_hp
	
	deck_info_label.text = "Shards: %d | Deck: %d | HP: %d/%d" % [shards, deck_size, hp, max_hp]
	
	# Update Buttons
	if shop_system:
		var rem_cost = shop_system.remove_price()
		remove_btn.text = "Purge Card (%d)" % rem_cost
		remove_btn.disabled = (shards < rem_cost)
		
		var heal_cost = shop_system.heal_cost_for(20) # Heal 20?
		# Heals 30% usually. Let's say 24 HP.
		var heal_amt = int(max_hp * 0.3)
		heal_cost = shop_system.heal_cost_for(heal_amt)
		
		heal_btn.text = "Rest (+%d HP) (%d)" % [heal_amt, heal_cost]
		heal_btn.disabled = (shards < heal_cost) or (hp >= max_hp)

func _on_card_clicked(idx: int) -> void:
	if not shop_system: return
	
	var success = shop_system.purchase(idx)
	if success:
		print("Purchased card index %d" % idx)
		_populate_shop() # Re-render (removes purchased)
		_update_ui()
	else:
		print("Cannot afford or invalid.")
		# Shake animation?

func _on_remove_pressed() -> void:
	# Opens deck view to pick card to remove.
	# Simplification: Remove RANDOM filler for now?
	# User wants "Remove Card". Usually implies selection.
	# Implementing DeckSelectionScreen is separate task.
	# FOR NOW: Random filler remove as fallback.
	if shop_system:
		var dm = get_node_or_null("/root/DeckManager")
		if dm: 
			# Hack: Purge first strike/defend found
			var filler = dm.find_filler_card()
			if filler:
				if shop_system.remove_card_from_deck(filler):
					print("Purged %s" % filler.id)
					_update_ui()
			else:
				print("No filler to purge!")
	
func _on_heal_pressed() -> void:
	if not shop_system: return
	var amt = int(run_controller.max_hp * 0.3)
	if shop_system.heal_player(amt):
		print("Healed player")
		_update_ui()

func _on_leave_pressed() -> void:
	if run_controller:
		run_controller.return_to_map()
