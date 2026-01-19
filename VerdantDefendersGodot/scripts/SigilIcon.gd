extends Control

@onready var tex: TextureRect = %Icon
@onready var name_lab: Label = %Name
@onready var desc_lab: Label = %Desc

var _id: String = ""

func setup(id: String) -> void:
	_id = id
	var ss = get_node_or_null("/root/SigilSystem")
	if not ss:
		return
	var d: Dictionary = ss.get_def(id)
	name_lab.text = String(d.get("name", id))
	desc_lab.text = String(d.get("text", ""))
	var p := ss.get_icon_path(id)
	if ResourceLoader.exists(p):
		tex.texture = load(p)
