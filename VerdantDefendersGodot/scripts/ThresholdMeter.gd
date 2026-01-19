extends ProgressBar

# ThresholdMeter
# Generic meter with Green/Yellow/Red states and threshold logic.

@export var threshold: int = 10
var _current_val: int = 0

func _ready() -> void:
    step = 1.0
    percent_visible = false
    # Default styling (can be overridden by theme or custom texture)
    # We'll use StyleBoxFlat for simplicity in code-only setup
    var bg = StyleBoxFlat.new()
    bg.bg_color = Color(0.1, 0.1, 0.1, 0.8)
    bg.border_width_bottom = 2
    bg.border_width_top = 2
    bg.border_width_left = 2
    bg.border_width_right = 2
    bg.border_color = Color.BLACK
    add_theme_stylebox_override("background", bg)
    
    _update_style()

func setup(p_current: int, p_threshold: int, p_max: int = -1) -> void:
    _current_val = p_current
    threshold = p_threshold
    
    if p_max == -1: max_value = max(p_threshold, p_current)
    else: max_value = p_max
    
    value = p_current
    
    # Label logic
    var lbl = get_node_or_null("Label")
    if not lbl:
        lbl = Label.new()
        lbl.name = "Label"
        lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
        lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        add_child(lbl)
    
    # "A / B" format
    lbl.text = "%d / %d" % [_current_val, threshold]
    if _current_val >= threshold:
        lbl.text = "%d (MAX)" % _current_val # Or just number
        
    _update_style()
    
    # Flash on cross? Logic handled by caller or delta check?
    # Caller usually calls setup() every update.
    # pulse if close
    if _current_val >= threshold - 1:
        pulse()

func _update_style() -> void:
    var fg = StyleBoxFlat.new()
    fg.border_width_bottom = 2
    fg.border_width_top = 2
    fg.border_width_left = 2
    fg.border_width_right = 2
    fg.border_color = Color.BLACK
    
    if _current_val >= threshold:
        fg.bg_color = Color.RED
    elif _current_val >= threshold - 1:
        fg.bg_color = Color.YELLOW
    else:
        fg.bg_color = Color.GREEN
        
    add_theme_stylebox_override("fill", fg)

func pulse() -> void:
    var tw = create_tween()
    tw.tween_property(self, "scale", Vector2(1.1, 1.1), 0.1)
    tw.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
