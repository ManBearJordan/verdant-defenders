extends Control

const GAMEUI: PackedScene = preload("res://Scenes/GameUI.tscn")

func _ready() -> void:
	print("--- StartScreen ready ---")

	# Fill the viewport
	set_anchors_preset(Control.PRESET_FULL_RECT, true)
	set_offsets_preset(Control.PRESET_FULL_RECT)

	# Ensure GameUI exists at runtime
	var ui: Control = get_node_or_null("GameUI") as Control
	if ui == null:
		ui = GAMEUI.instantiate() as Control
		ui.name = "GameUI"
		add_child(ui)
		print("[StartScreen] Instanced GameUI at runtime.")
	else:
		print("[StartScreen] Found GameUI in scene.")

	ui.set_anchors_preset(Control.PRESET_FULL_RECT, true)
	ui.set_offsets_preset(Control.PRESET_FULL_RECT)

	print("--- Tree BEFORE process_frame ---")
	_dump_tree(self)

	await get_tree().process_frame

	print("--- Tree AFTER process_frame ---")
	_dump_tree(self)

func _dump_tree(n: Node, indent: String = "") -> void:
	print(indent, n.name, " (", n.get_class(), ")")
	for c in n.get_children():
		_dump_tree(c, indent + "  ")
