extends Node
class_name RelicController

var relics := {}

func _ready():
    var file = FileAccess.open("res://Data/relic_data.json", FileAccess.READ)
    if file:
        relics = JSON.parse_string(file.get_as_text())

func grant_relic(id:String):
    if relics.has(id):
        print("Granted relic %s" % id)
