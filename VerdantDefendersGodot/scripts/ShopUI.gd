extends Control
signal shop_done
@onready var shop = get_node("/root/ShopSystem")
@onready var data = get_node("/root/DataLayer")
@onready var gc = get_node("/root/GameController")
var inventory: Array = []; var heal_step := 10
func _ready(): inventory = shop.generate_inventory(5, gc.current_class); _build()
func _build():
	$Panel/VBox/DeckInfo.text = "Shards: %s | Deck size: %s | HP: %s/%s" % [str(gc.verdant_shards), str(gc.current_deck.size()), str(gc.player_hp), str(gc.max_hp)]
	var list = $Panel/VBox/Scroll/Items
	for c in list.get_children(): c.queue_free()
	for id in inventory:
		var card: Dictionary = data.get_card(str(id))
		var btn = Button.new()
		btn.text = _card_title(card) + "  — Buy (%s)" % str(shop.price_for_card(card))
		btn.disabled = gc.verdant_shards < shop.price_for_card(card)
		btn.pressed.connect(_buy_card.bind(str(id)))
		list.add_child(btn)
	var rem = Button.new(); rem.text = "Remove a card  — %s shards" % str(shop.remove_price()); rem.pressed.connect(_open_remove); list.add_child(rem)
	var heal = Button.new(); heal.text = "Heal %s HP  — %s shards" % [str(heal_step), str(shop.heal_cost_for(heal_step))]; heal.pressed.connect(_do_heal); list.add_child(heal)
	var leave = Button.new(); leave.text = "Leave Shop"; leave.pressed.connect(_leave); list.add_child(leave)
func _card_title(c: Dictionary) -> String:
	var title := "%s (Cost:%s)" % [str(c.get("name","?")), str(c.get("cost",0))]
	if c.has("damage"): title += "  DMG:%s" % str(c.get("damage"))
	if c.has("block"): title += "  BLK:%s" % str(c.get("block"))
	if c.has("apply"): var ap: Dictionary = c["apply"]; if ap.has("poison"): title += "  PSN:%s" % str(ap["poison"])
	return title
func _buy_card(id: String): if shop.purchase_card(id): _build()
func _open_remove():
	var root = $Panel/VBox
	if root.has_node("RemoveBox"): root.get_node("RemoveBox").queue_free()
	var box = VBoxContainer.new(); box.name = "RemoveBox"; box.add_theme_constant_override("separation", 6)
	var lab = Label.new(); lab.text = "Choose a card to remove:"; box.add_child(lab)
	for i in range(gc.current_deck.size()):
		var cid = str(gc.current_deck[i])
		var b = Button.new(); var card = data.get_card(cid)
		b.text = "%s — Remove (%s shards)" % [str(card.get("name", cid)), str(shop.remove_price())]
		b.pressed.connect(_remove_card.bind(cid)); box.add_child(b)
	var cancel = Button.new(); cancel.text = "Cancel"; cancel.pressed.connect(func(): box.queue_free()); box.add_child(cancel)
	root.add_child(box)
func _remove_card(cid: String):
	if shop.remove_card_from_deck(cid):
		var root = $Panel/VBox; if root.has_node("RemoveBox"): root.get_node("RemoveBox").queue_free(); _build()
func _do_heal(): if shop.heal_player(heal_step): _build()
func _leave(): emit_signal("shop_done"); queue_free()
