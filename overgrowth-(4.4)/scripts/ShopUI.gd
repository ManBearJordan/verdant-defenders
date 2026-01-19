extends Control

signal shop_done

@onready var shop = get_node_or_null("/root/ShopSystem")
@onready var data = get_node_or_null("/root/DataLayer")
@onready var gc = get_node_or_null("/root/GameController")
@onready var dm = get_node_or_null("/root/DeckManager")

var inventory: Array = []
var heal_step := 10

func _ready() -> void:
	if not shop or not gc:
		return
	inventory = shop.generate_inventory(5, gc.current_class)
	_build()

func _build() -> void:
	# Update Info Header
	var deck_size = 0
	if dm: deck_size = dm.get_all_cards().size()
	
	var label = get_node_or_null("Panel/VBox/DeckInfo")
	if label:
		label.text = "Shards: %s | Deck size: %s | HP: %s/%s" % [str(gc.verdant_shards), str(deck_size), str(gc.player_hp), str(gc.max_hp)]

	var list = get_node_or_null("Panel/VBox/Scroll/Items")
	if not list: return
	
	for c in list.get_children(): c.queue_free()
	
	# Cards
	for i in range(inventory.size()):
		var card = inventory[i]
		var btn = Button.new()
		var price = shop.price_for_card(card)
		btn.text = _card_title(card) + "  — Buy (%s)" % str(price)
		btn.disabled = gc.verdant_shards < price
		btn.pressed.connect(_buy_card.bind(i))
		list.add_child(btn)
		
	# Actions
	var rem = Button.new()
	var rem_price = shop.remove_price()
	rem.text = "Remove a card  — %s shards" % str(rem_price)
	rem.disabled = gc.verdant_shards < rem_price
	rem.pressed.connect(_open_remove)
	list.add_child(rem)
	
	var heal_price = shop.heal_cost_for(heal_step)
	var heal = Button.new()
	heal.text = "Heal %s HP  — %s shards" % [str(heal_step), str(heal_price)]
	var can_afford = gc.verdant_shards >= heal_price
	var needs_heal = gc.player_hp < gc.max_hp
	heal.disabled = not (can_afford and needs_heal)
	heal.pressed.connect(_do_heal)
	list.add_child(heal)
	
	var leave = Button.new()
	leave.text = "Leave Shop"
	leave.pressed.connect(_leave)
	list.add_child(leave)

func _card_title(c: CardResource) -> String:
	var title := "%s (Cost:%d)" % [c.display_name, c.cost]
	if c.damage > 0: title += "  DMG:%d" % c.damage
	if c.block > 0: title += "  BLK:%d" % c.block
	return title

func _buy_card(index: int) -> void:
	if shop.purchase(index):
		_build()

func _open_remove() -> void:
	var root = get_node_or_null("Panel/VBox")
	if not root: return
	if root.has_node("RemoveBox"): root.get_node("RemoveBox").queue_free()
	
	var box = VBoxContainer.new()
	box.name = "RemoveBox"
	box.add_theme_constant_override("separation", 6)
	
	var lab = Label.new()
	lab.text = "Choose a card to remove:"
	box.add_child(lab)
	
	if dm:
		var all_cards = dm.get_all_cards()
		for i in range(all_cards.size()):
			var card = all_cards[i]
			# Ensure card is resource
			if not (card is CardResource): continue
			
			var b = Button.new()
			b.text = "%s" % card.display_name
			b.pressed.connect(_remove_card_action.bind(card))
			box.add_child(b)
			
	var cancel = Button.new()
	cancel.text = "Cancel"
	cancel.pressed.connect(func(): box.queue_free())
	box.add_child(cancel)
	
	root.add_child(box)

func _remove_card_action(card: CardResource) -> void:
	if shop.remove_card_from_deck(card):
		var root = get_node_or_null("Panel/VBox")
		if root and root.has_node("RemoveBox"): 
			root.get_node("RemoveBox").queue_free()
		_build()

func _do_heal() -> void:
	if shop.heal_player(heal_step):
		_build()

func _leave() -> void:
	emit_signal("shop_done")
	# If instantiated by GameUI, GameUI will handle visibility or queue_free
	if get_parent() == get_tree().root:
		queue_free()
