extends Node

signal room_entered(kind: String, index: int)
signal floor_cleared()

@onready var data = get_node("/root/DataLayer")

var layer_index := 0
var room_index := -1
var layers: Array = []
var current_layer_rooms: Array = []

func _ready() -> void:
	var d = _read_json("res://Data/dungeon.json")
	layers = d.get("layers", [])

func _read_json(p: String) -> Dictionary:
	if not FileAccess.file_exists(p): return {}
	var f := FileAccess.open(p, FileAccess.READ)
	var txt := f.get_as_text()
	f.close()
	var j = JSON.parse_string(txt)
	return j if typeof(j)==TYPE_DICTIONARY else {}

func start() -> void:
	layer_index = 0
	room_index = -1
	_load_layer()

func next_room() -> void:
	room_index += 1
	if room_index >= current_layer_rooms.size():
		emit_signal("floor_cleared")
		return
	emit_signal("room_entered", String(current_layer_rooms[room_index]), room_index)

func _load_layer() -> void:
	if layer_index >= layers.size():
		return
	current_layer_rooms = layers[layer_index].get("rooms", []).duplicate()