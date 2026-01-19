extends Control

# Combat Log Ribbon
# Displays single-line scrolling messages for high-priority combat events.
# "Pressure without pop-ups"

const FADE_TIME = 3.0
const SCROLL_SPEED = 20.0

var _messages: Array[Label] = []
var _vbox: VBoxContainer

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
    position = Vector2(20, -60) # Offset from bottom left
    
    _vbox = VBoxContainer.new()
    _vbox.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
    _vbox.grow_horizontal = Control.GROW_DIRECTION_END
    _vbox.grow_vertical = Control.GROW_DIRECTION_BEGIN
    _vbox.add_theme_constant_override("separation", 2)
    add_child(_vbox)

    # Listen to GameController for messages
    var gc = get_node_or_null("/root/GameController")
    if gc and not gc.has_user_signal("ribbon_message"):
        gc.add_user_signal("ribbon_message", [{"name": "text", "type": TYPE_STRING}])
        gc.connect("ribbon_message", _add_message)

func _add_message(text: String) -> void:
    var lbl = Label.new()
    lbl.text = text
    lbl.modulate = Color(1, 1, 1, 0) # Start invisible
    lbl.add_theme_font_size_override("font_size", 20)
    lbl.add_theme_color_override("font_outline_color", Color.BLACK)
    lbl.add_theme_constant_override("outline_size", 4)
    
    _vbox.add_child(lbl)
    _vbox.move_child(lbl, 0) # Add to bottom (grow up)? VBox layouts down.
    # If anchored bottom-left and grow-vertical BEGIN, adding child appends to bottom?
    # Actually VBox lays out top-to-bottom.
    # We want newest at bottom.
    
    # Animate In
    var tw = create_tween()
    tw.tween_property(lbl, "modulate:a", 1.0, 0.2)
    tw.tween_interval(2.0)
    tw.tween_property(lbl, "modulate:a", 0.0, 1.0)
    tw.tween_callback(lbl.queue_free)
    
    # Limit count
    if _vbox.get_child_count() > 5:
        _vbox.get_child(0).queue_free()

func public_log(text: String) -> void:
    _add_message(text)
