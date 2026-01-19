extends Node

# VerdantTheme - Global Theme Manager
# Colors
const COL_BG_DARK = Color("1a261a") # Deep Green
const COL_BG_PANEL = Color("2d3e2d") # Lighter Green
const COL_ACCENT_GOLD = Color("d4af37") # Gold
const COL_TEXT_CREAM = Color("f0f5f0") # Cream White
const COL_TEXT_GOLD = Color("f2d675")

func _ready() -> void:
    _apply_global_theme()

func _apply_global_theme() -> void:
    var theme = Theme.new()
    
    # 1. Labels
    theme.set_color("font_color", "Label", COL_TEXT_CREAM)
    theme.set_color("font_shadow_color", "Label", Color(0,0,0,0.5))
    theme.set_constant("shadow_offset_x", "Label", 1)
    theme.set_constant("shadow_offset_y", "Label", 1)

    # 2. Buttons
    var sb_normal = StyleBoxFlat.new()
    sb_normal.bg_color = COL_BG_PANEL
    sb_normal.border_color = COL_ACCENT_GOLD
    sb_normal.set_border_width_all(1)
    sb_normal.corner_radius_top_left = 4
    sb_normal.corner_radius_top_right = 4
    sb_normal.corner_radius_bottom_right = 4
    sb_normal.corner_radius_bottom_left = 4
    sb_normal.content_margin_left = 8
    sb_normal.content_margin_right = 8
    sb_normal.content_margin_top = 4
    sb_normal.content_margin_bottom = 4
    
    var sb_hover = sb_normal.duplicate()
    sb_hover.bg_color = COL_BG_PANEL.lightened(0.2)
    sb_hover.border_color = Color.WHITE
    
    var sb_pressed = sb_normal.duplicate()
    sb_pressed.bg_color = COL_BG_DARK
    
    theme.set_stylebox("normal", "Button", sb_normal)
    theme.set_stylebox("hover", "Button", sb_hover)
    theme.set_stylebox("pressed", "Button", sb_pressed)
    theme.set_color("font_color", "Button", COL_TEXT_GOLD)

    # 3. Panels
    var sb_panel = StyleBoxFlat.new()
    sb_panel.bg_color = COL_BG_DARK.darkened(0.2)
    sb_panel.border_color = COL_ACCENT_GOLD
    sb_panel.set_border_width_all(2)
    sb_panel.corner_radius_top_left = 8
    sb_panel.corner_radius_top_right = 8
    sb_panel.corner_radius_bottom_right = 8
    sb_panel.corner_radius_bottom_left = 8
    
    theme.set_stylebox("panel", "Panel", sb_panel)

    # Apply to window
    DisplayServer.window_set_title("Verdant Defenders (Themed)")
    # Godot 4: Theme is applied to the root viewport
    get_tree().root.theme = theme
