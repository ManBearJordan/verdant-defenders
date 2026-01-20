extends HBoxContainer
class_name SigilBar

const MAX_SLOTS = 6
var _slots: Array[Panel] = []
var _no_sigils_label: Label = null

func _ready() -> void:
    # Title
    var title = Label.new()
    title.text = "Sigils:"
    title.add_theme_font_size_override("font_size", 14)
    add_child(title)
    
    # Create Fixed Slots
    for i in range(MAX_SLOTS):
        var slot = Panel.new()
        slot.custom_minimum_size = Vector2(48, 48)
        var sb = StyleBoxFlat.new()
        sb.bg_color = Color(0, 0, 0, 0.3)
        sb.set_corner_radius_all(4)
        sb.set_border_width_all(1)
        sb.border_color = Color(1, 1, 1, 0.2)
        slot.add_theme_stylebox_override("panel", sb)
        
        add_child(slot)
        _slots.append(slot)
        
    # "No Sigils" Label
    _no_sigils_label = Label.new()
    _no_sigils_label.text = "(No Sigils)"
    _no_sigils_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
    _no_sigils_label.add_theme_font_size_override("font_size", 12)
    add_child(_no_sigils_label)
        
    var ss = get_node_or_null("/root/SigilSystem")
    if ss:
        ss.sigil_added.connect(_refresh_all)
        ss.sigil_removed.connect(_refresh_all)
        if ss.has_signal("sigil_triggered"):
            ss.sigil_triggered.connect(_on_sigil_triggered)
        
        _refresh_all()

const SIGIL_ICON_SCENE = preload("res://Scenes/UI/Combat/SigilIcon.tscn")

func _refresh_all(_unused_arg = null) -> void:
    # Clear all slots
    for slot in _slots:
        for c in slot.get_children():
            c.queue_free()
            
    var ss = get_node_or_null("/root/SigilSystem")
    if not ss: return
    
    var active = ss.get_active_sigils()
    
    # Fill slots
    for i in range(min(active.size(), MAX_SLOTS)):
        var sigil = active[i]
        var slot = _slots[i]
        
        # Instance SigilIcon
        var icon = SIGIL_ICON_SCENE.instantiate()
        icon.name = "Icon"
        # Anchors handled by SigilIcon Control props if using layout, 
        # but slot is a Panel (Container?). If Panel is container, we might need layout presets.
        # Panel is a Control. Children are just positioned.
        # Let's set anchors to full rect.
        icon.layout_mode = 1 # Anchors
        icon.set_anchors_preset(Control.PRESET_FULL_RECT)
        
        if icon.has_method("setup"):
            icon.setup(sigil)
            
        slot.add_child(icon)
    
    # Update "No Sigils" visibility
    if _no_sigils_label:
        _no_sigils_label.visible = active.is_empty()

func _on_sigil_triggered(id: String) -> void:
    var ss = get_node_or_null("/root/SigilSystem")
    if not ss: return
    var active = ss.get_active_sigils()
    
    for i in range(active.size()):
        if active[i].get("id") == id:
            if i < _slots.size():
                var slot = _slots[i]
                var icon = slot.get_node_or_null("Icon")
                if icon:
                    var tw = create_tween()
                    tw.tween_property(icon, "scale", Vector2(1.2, 1.2), 0.1).set_trans(Tween.TRANS_CUBIC)
                    tw.tween_property(icon, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_CUBIC)
            return
