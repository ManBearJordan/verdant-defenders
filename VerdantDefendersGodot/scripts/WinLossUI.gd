extends Control

signal restart_requested
signal menu_requested

func setup_game_over() -> void:
	_clear()
	_create_overlay(Color(0.2, 0, 0, 0.8))
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	add_child(vbox)
	
	var lbl = Label.new()
	lbl.text = "YOU DIED"
	lbl.add_theme_font_size_override("font_size", 64)
	lbl.add_theme_color_override("font_color", Color.RED)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl)
	
	vbox.add_child(HSeparator.new())
	
	var btn = Button.new()
	btn.text = "Restart Run"
	btn.custom_minimum_size = Vector2(200, 50)
	btn.pressed.connect(_on_restart_pressed)
	vbox.add_child(btn)

func setup_victory() -> void:
	_clear()
	_create_overlay(Color(0, 0.2, 0, 0.8))
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	add_child(vbox)
	
	var lbl = Label.new()
	lbl.text = "VICTORY"
	lbl.add_theme_font_size_override("font_size", 64)
	lbl.add_theme_color_override("font_color", Color.GREEN)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl)
	
	var sub = Label.new()
	sub.text = "The corruption is purged... for now."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(sub)
	
	vbox.add_child(HSeparator.new())
	
	var btn = Button.new()
	btn.text = "Return to Main Menu"
	btn.custom_minimum_size = Vector2(200, 50)
	btn.pressed.connect(_on_menu_pressed)
	vbox.add_child(btn)

func _create_overlay(col: Color) -> void:
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = col
	add_child(bg)

func _clear() -> void:
	for c in get_children():
		c.queue_free()

func _on_restart_pressed() -> void:
	# Go to Menu (Simple)
	var flow = get_node_or_null("/root/FlowController")
	if flow: flow.return_to_map() # Actually return_to_map goes to MAP. We want MAIN_MENU.
	if flow: flow.goto(flow.GameState.MAIN_MENU)

func _on_menu_pressed() -> void:
	var flow = get_node_or_null("/root/FlowController")
	if flow: flow.goto(flow.GameState.MAIN_MENU)
