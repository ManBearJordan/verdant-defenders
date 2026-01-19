extends Control

signal closed

func _ready() -> void:
	_setup_ui()

func _setup_ui() -> void:
	# Overlay
	var bg = ColorRect.new()
	bg.color = Color(0,0,0,0.8)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.set_offsets_preset(Control.PRESET_CENTER)
	add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(300, 200)
	panel.add_child(vbox)
	
	var lbl = Label.new()
	lbl.text = "Settings"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl)
	
	vbox.add_child(HSeparator.new())
	
	# Master Volume
	_add_slider(vbox, "Master Volume", "master")
	_add_slider(vbox, "Music Volume", "music")
	_add_slider(vbox, "SFX Volume", "sfx")
	
	vbox.add_child(Control.new()) # Spacer
	
	var close = Button.new()
	close.text = "Close"
	close.pressed.connect(func(): 
		emit_signal("closed")
		queue_free()
	)
	vbox.add_child(close)

func _add_slider(parent: Control, label_text: String, bus: String) -> void:
	var hbox = HBoxContainer.new()
	parent.add_child(hbox)
	
	var l = Label.new()
	l.text = label_text
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(l)
	
	var slider = HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.custom_minimum_size.x = 150
	
	# Get current val
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		slider.value = sm.volumes.get(bus, 1.0)
	else:
		slider.value = 1.0
		
	slider.value_changed.connect(func(val):
		if sm: sm.set_volume(bus, val)
	)
	hbox.add_child(slider)
