const CardDatabase = preload("res://scripts/CardDatabase.gd")
extends Control
class_name ShopController

var shop_data := {}
signal card_bought(card_name)
signal heal_clicked
signal remove_clicked
var card_db := CardDatabase.new()

func _ready():
	randomize()
	var file = FileAccess.open("res://Data/shop_data.json", FileAccess.READ)
	if file:
		shop_data = JSON.parse_string(file.get_as_text())
	_populate_shop()
	_connect_buttons()

func _populate_shop():
	var options = []
	var names = card_db.cards.keys()
	for i in range(int(shop_data.get("options_per_shop", 3))):
		var n = names[randi() % names.size()]
		options.append(n)
	
	var cards_container = $VBoxContainer/Cards
	for n in options:
		var b = Button.new()
		b.text = n + " (" + str(shop_data.get("common_price", 50)) + " gold)"
		cards_container.add_child(b)
		b.connect("pressed", Callable(self, "_on_card_pressed").bind(n))

func _connect_buttons():
	if has_node("VBoxContainer/HealButton"):
		$VBoxContainer/HealButton.connect("pressed", Callable(self, "_on_heal"))
	if has_node("VBoxContainer/RemoveButton"):
		$VBoxContainer/RemoveButton.connect("pressed", Callable(self, "_on_remove"))

func _on_card_pressed(name:String):
	emit_signal("card_bought", name)

func _on_heal():
	emit_signal("heal_clicked")

func _on_remove():
	emit_signal("remove_clicked")
