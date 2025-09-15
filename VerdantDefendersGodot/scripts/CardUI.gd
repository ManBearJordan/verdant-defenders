extends Panel

var card_data : CardData
var game_controller : Node
var original_position : Vector2
var is_hovered : bool = false

@onready var name_label = $NameLabel
@onready var cost_label = $CostLabel

func _ready():
    # Add some visual styling
    set_custom_minimum_size(Vector2(120, 180))
    # Store original position for hover effect
    original_position = position

func setup(data):
    card_data = data
    name_label.text = card_data.name
    cost_label.text = str(card_data.cost)
    
    # Show card type if the label exists
    if has_node("TypeLabel"):
        $TypeLabel.text = card_data.type
    
    # Color code by card type
    match card_data.type:
        "Strike":
            modulate = Color(1.2, 1.0, 1.0)  # Slightly red tint
        "Tactic":
            modulate = Color(1.0, 1.2, 1.0)  # Slightly green tint
        "Ritual":
            modulate = Color(1.0, 1.0, 1.2)  # Slightly blue tint
        _:
            modulate = Color(1.0, 1.0, 1.0)  # Normal color
    
    # Find the game controller in the scene tree
    game_controller = get_tree().get_nodes_in_group("game_controller")[0] if get_tree().get_nodes_in_group("game_controller").size() > 0 else null

func _gui_input(event):
    if event is InputEventMouseButton and event.pressed:
        if game_controller and game_controller.has_method("play_card"):
            game_controller.play_card(card_data.name)
        elif get_node("/root/Main/Game"):
            get_node("/root/Main/Game").play_card(card_data.name)

func _on_mouse_entered():
    is_hovered = true
    # Scale up slightly when hovered
    var tween = create_tween()
    tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.1)
    tween.tween_property(self, "position", original_position + Vector2(0, -10), 0.1)

func _on_mouse_exited():
    is_hovered = false
    # Scale back to normal
    var tween = create_tween()
    tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
    tween.tween_property(self, "position", original_position, 0.1)
