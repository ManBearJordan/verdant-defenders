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

func _populate_shop():
    var options = []
    var names = card_db.cards.keys()
    for i in range(int(shop_data.options_per_shop)):
        var n = names[randi() % names.size()]
        options.append(n)
    for n in options:
        var b = Button.new()
        b.text = n
        $Cards.add_child(b)
        b.connect("pressed", Callable(self, "_on_card_pressed").bind(n))
    $HealButton.connect("pressed", Callable(self, "_on_heal"))
    $RemoveButton.connect("pressed", Callable(self, "_on_remove"))

func _on_card_pressed(name:String):
    emit_signal("card_bought", name)

func _on_heal():
    emit_signal("heal_clicked")

func _on_remove():
    emit_signal("remove_clicked")
