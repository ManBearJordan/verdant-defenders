extends Control
class_name MainMenu

signal start_game

func _ready():
	_setup_ui()

func _setup_ui():
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	add_child(vbox)
	
	var title = Label.new()
	title.text = "Verdant Defenders"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	vbox.add_child(title)
	
	var subtitle = Label.new()
	subtitle.text = "A Roguelike Deckbuilder"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(subtitle)
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 50)
	vbox.add_child(spacer)
	
	var start_button = Button.new()
	start_button.text = "Start Game"
	start_button.custom_minimum_size = Vector2(200, 50)
	vbox.add_child(start_button)
	start_button.connect("pressed", Callable(self, "_on_start_pressed"))
	
	var quit_button = Button.new()
	quit_button.text = "Quit"
	quit_button.custom_minimum_size = Vector2(200, 50)
	vbox.add_child(quit_button)
	quit_button.connect("pressed", Callable(self, "_on_quit_pressed"))

func _on_start_pressed():
	emit_signal("start_game")
	
func _on_quit_pressed():
	get_tree().quit()