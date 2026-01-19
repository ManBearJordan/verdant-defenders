extends Node2D
class_name MapNode

# MapNode.gd - Node2D-based Map Node Component
# REQUIRED: No Control/Card prefabs. Node2D + Area2D click only.

signal node_selected(node_id: int)

# Debug flag
const DEBUG_MAP = false

# Exported Properties
@export var node_id: int = 0
@export var node_type: String = "SKIRMISH"
@export var layer_index: int = 0
@export var is_locked: bool = true
@export var is_completed: bool = false
@export var is_current: bool = false

# Node References
@onready var icon_sprite: Sprite2D = $IconSprite
@onready var frame_sprite: Sprite2D = $FrameSprite
@onready var click_area: Area2D = $ClickArea
@onready var debug_label: Label = $DebugLabel

# Icon Mapping
const ICON_MAP = {
	"START": "res://Art/map/node_combat.png",
	"SKIRMISH": "res://Art/map/node_combat.png",
	"FIGHT": "res://Art/map/node_combat.png",
	"ELITE": "res://Art/map/node_elite.png",
	"SHOP": "res://Art/map/node_shop.png",
	"EVENT": "res://Art/map/node_event.png",
	"SANCTUARY": "res://Art/map/node_event.png",
	"CACHE": "res://Art/map/node_chest.png",
	"MINIBOSS": "res://Art/map/node_elite.png",
	"MINIBOSS_GATE": "res://Art/map/node_elite.png",
	"MINIBOSS_OPT": "res://Art/map/node_elite.png",
	"BOSS": "res://Art/map/node_boss.png"
}

func _ready() -> void:
	# Connect Area2D click detection
	if click_area:
		click_area.input_event.connect(_on_input_event)
	
	# Hide debug label unless DEBUG_MAP is true
	if debug_label:
		debug_label.visible = DEBUG_MAP
	
	_update_visuals()

func setup(id: int, type: String, layer: int) -> void:
	node_id = id
	node_type = type.to_upper()
	layer_index = layer
	_update_visuals()

func set_state(locked: bool, completed: bool, current: bool) -> void:
	is_locked = locked
	is_completed = completed
	is_current = current
	_update_visuals()

func _update_visuals() -> void:
	# Icon
	if icon_sprite:
		var icon_path = ICON_MAP.get(node_type, "res://Art/map/node_combat.png")
		if ResourceLoader.exists(icon_path):
			icon_sprite.texture = load(icon_path)
		else:
			icon_sprite.texture = null
	
	# Debug Label (only visible if DEBUG_MAP)
	if debug_label and DEBUG_MAP:
		debug_label.text = node_type.substr(0, 3)
	
	# START node special styling
	if node_type == "START":
		scale = Vector2(1.15, 1.15)
		modulate = Color(0.8, 1.0, 0.6, 1.0)
		return
	
	# VISUAL PRIORITY RULES
	# Current: scale 1.15, bright
	# Available: scale 1.0, normal
	# Locked: scale 0.9, 50% opacity
	# Completed: desaturated
	
	if is_current:
		scale = Vector2(1.15, 1.15)
		modulate = Color(1.0, 1.0, 0.5, 1.0)
	elif is_completed:
		scale = Vector2(1.0, 1.0)
		modulate = Color(0.6, 0.6, 0.6, 0.8)
	elif is_locked:
		scale = Vector2(0.9, 0.9)
		modulate = Color(0.5, 0.5, 0.5, 0.5)
	else:
		# Available
		scale = Vector2(1.0, 1.0)
		modulate = Color(1.0, 1.0, 1.0, 1.0)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if not is_locked:
				node_selected.emit(node_id)
