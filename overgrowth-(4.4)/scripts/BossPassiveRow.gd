extends HBoxContainer

# BossPassiveRow
# Displays a row of passive icons with tooltips under the Boss HP bar.

class PassiveIcon extends TextureRect:
	var tooltip_text_custom: String = ""
	
	func _make_custom_tooltip(for_text: String) -> Object:
		var label = Label.new()
		label.text = for_text
		return label
		
	func _gui_input(event: InputEvent) -> void:
		pass # Standard tooltip handling via 'tooltip_text' property

func add_passive(id: String, label: String, tooltip: String) -> void:
	# Check if exists
	if has_node(id): return
	
	var container = VBoxContainer.new()
	container.name = id
	add_child(container)
	
	# Icon (Placeholder Box for now, or load texture if available)
	var icon = PassiveIcon.new()
	icon.custom_minimum_size = Vector2(32, 32)
	icon.texture = _get_icon_texture(id)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.tooltip_text = tooltip
	container.add_child(icon)
	
	# Icon Background/Border?
	var bg = ColorRect.new()
	bg.show_behind_parent = true
	bg.color = Color(0.2, 0.2, 0.2, 0.8)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	# icon.add_child(bg) # TextureRect doesn't clip children nicely usually
	
	# Label
	var lbl = Label.new()
	lbl.text = label
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 10)
	container.add_child(lbl)

func _get_icon_texture(id: String) -> Texture2D:
	# Placeholder generation or load from resources
	var placeholder = GradientTexture2D.new()
	placeholder.width = 32
	placeholder.height = 32
	placeholder.fill_from = Vector2(0, 0)
	placeholder.fill_to = Vector2(1, 1)
	
	var grad = Gradient.new()
	if id == "HARVEST":
		grad.colors = [Color.WEB_GREEN, Color.DARK_GREEN]
	elif id == "EQUILIBRIUM" or id == "CAP":
		grad.colors = [Color.PURPLE, Color.WEB_PURPLE]
	elif id == "LOCK":
		grad.colors = [Color.GOLD, Color.ORANGE]
	elif id == "PURGE":
		grad.colors = [Color.GRAY, Color.WHITE]
	else:
		grad.colors = [Color.GRAY, Color.DARK_GRAY]
		
	placeholder.gradient = grad
	return placeholder
