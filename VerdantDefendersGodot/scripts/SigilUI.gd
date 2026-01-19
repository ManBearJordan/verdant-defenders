extends Control

@onready var grid: GridContainer = %Grid
@onready var title_lab: Label = %Title

func _ready() -> void:
	title_lab.text = "Sigils"
	_refresh()
	var ss = get_node_or_null("/root/SigilSystem")
	if ss:
		ss.sigil_added.connect(_on_changed)
		ss.sigil_removed.connect(_on_changed)

func _on_changed(_id: String) -> void:
	_refresh()

func _refresh() -> void:
	_clear_grid()
	var ss = get_node_or_null("/root/SigilSystem")
	if not ss:
		return
	var ids: Array = ss.list()
	for id in ids:
		var icon_scene: PackedScene = load("res://scenes/SigilIcon.tscn")
		if icon_scene:
			var inst = icon_scene.instantiate()
			grid.add_child(inst)
			inst.call_deferred("setup", id)

func _clear_grid() -> void:
	for c in grid.get_children():
		c.queue_free()
