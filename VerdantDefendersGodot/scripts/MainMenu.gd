extends Control

func _ready() -> void:
	_setup_ui()

func _setup_ui() -> void:
	# Background
	var bg = TextureRect.new()
	bg.texture = load("res://Art/backgrounds/growth_combat.png")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	# Vignette / Dark Overlay
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.4)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	
	# Main Container (Centered)
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 24)
	center.add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "OVERGROWTH"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 84)
	title.add_theme_color_override("font_color", Color("d4af37")) # Gold
	title.add_theme_color_override("font_shadow_color", Color.BLACK)
	title.add_theme_constant_override("shadow_offset_x", 4)
	title.add_theme_constant_override("shadow_offset_y", 4)
	vbox.add_child(title)
	
	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size.y = 20
	vbox.add_child(spacer)
	
	# Class Selector
	var hbox_class = HBoxContainer.new()
	hbox_class.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(hbox_class)
	
	var lbl_class = Label.new()
	lbl_class.text = "Class: "
	lbl_class.add_theme_font_size_override("font_size", 24)
	hbox_class.add_child(lbl_class)
	
	var opt_class = OptionButton.new()
	opt_class.add_item("Growth", 0)
	opt_class.add_item("Decay", 1)
	opt_class.add_item("Elemental", 2)
	opt_class.selected = 0
	opt_class.custom_minimum_size = Vector2(150, 0)
	hbox_class.add_child(opt_class)
	
	# New Game
	var btn_new = Button.new()
	btn_new.text = "New Run"
	btn_new.custom_minimum_size = Vector2(250, 60)
	btn_new.add_theme_font_size_override("font_size", 28)
	btn_new.pressed.connect(func(): 
		var cls = "growth"
		match opt_class.selected:
			0: cls = "growth"
			1: cls = "decay"
			2: cls = "elemental"
		_start_run(cls)
	)
	vbox.add_child(btn_new)
	
	# Continue
	var rp = get_node_or_null("/root/RunPersistence")
	if rp and FileAccess.file_exists("user://savegame.json"):
		var btn_cont = Button.new()
		btn_cont.text = "Continue Run"
		btn_cont.custom_minimum_size = Vector2(250, 50)
		btn_cont.pressed.connect(_continue_run)
		vbox.add_child(btn_cont)
		
	# Quit
	var btn_quit = Button.new()
	btn_quit.text = "Quit"
	btn_quit.custom_minimum_size = Vector2(250, 50)
	btn_quit.pressed.connect(func(): get_tree().quit())
	vbox.add_child(btn_quit)
	
	# Animation Juice
	title.modulate.a = 0
	var tw = create_tween()
	tw.tween_property(title, "modulate:a", 1.0, 1.5).set_trans(Tween.TRANS_SINE)
	
	# Wait for layout to determine center for pivot
	get_tree().process_frame.connect(func():
		title.pivot_offset = title.size / 2
		
		# Breathing Animation
		var loop = create_tween().set_loops()
		loop.tween_property(title, "scale", Vector2(1.05, 1.05), 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		loop.tween_property(title, "scale", Vector2(1.0, 1.0), 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	, CONNECT_ONE_SHOT)

func _start_run(class_id: String) -> void:
	var gc = get_node_or_null("/root/GameController")
	if gc:
		gc.start_run(class_id)
		
	var flow = get_node_or_null("/root/FlowController")
	if flow:
		flow.goto(flow.GameState.MAP)
	else:
		push_error("FlowController not found")

func _continue_run() -> void:
	var gc = get_node_or_null("/root/GameController")
	if gc:
		if gc.load_run():
			var flow = get_node_or_null("/root/FlowController")
			if flow:
				flow.goto(flow.GameState.MAP)
