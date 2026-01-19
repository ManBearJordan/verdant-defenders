extends Control
signal pressed

var index: int = -1
var data: Dictionary = {}

@onready var art_rect: TextureRect = get_node_or_null("Art")

# Store the original position and scale so we can restore them after a hover.
var _orig_pos_y: float = 0.0
var _orig_scale: Vector2 = Vector2.ONE
var _orig_z_index: int = 0

@onready var title_label: Label = get_node_or_null("Title")
@onready var cost_label: Label = get_node_or_null("CostOrb/CostLabel")
@onready var clicker: Button = get_node_or_null("ClickCatcher")

# Art mapping based on png_filenames.md
const ART_MAPPING = {
	"art_sap_shot": "res://Art/art_sap_shot.png",
	"art_seed_shield": "res://Art/art_seed_shield.png",
	"art_blossom_strike": "res://Art/art_blossom_strike.png",
	"art_thorn_lash": "res://Art/art_thorn_lash.png",
	"art_vine_whip": "res://Art/art_vine_whip.png",
	"art_sprout_heal": "res://Art/art_sprout_heal.png",
	"art_growth_aura": "res://Art/art_growth_aura.png",
	"art_seed_surge": "res://Art/art_seed_surge.png",
	"card_back": "res://Art/card_back.png"
}

func setup(card: Dictionary, i: int) -> void:
	index = i
	data = card.duplicate(true)
	# update labels if present
	if title_label:
		title_label.text = str(card.get("name", "Card"))
	if cost_label:
		cost_label.text = str(card.get("cost", 1))
	# connect click
	if clicker and not clicker.pressed.is_connected(_on_click):
		clicker.pressed.connect(_on_click)

	# Set artwork using art mapping
	_set_card_art(card)

func set_card(card_dict: Dictionary) -> void:
	"""Set card data and update display - fills labels, shows art via art mapping"""
	data = card_dict.duplicate(true)
	
	# Update labels
	if title_label:
		title_label.text = String(card_dict.get("name", "Card"))
	if cost_label:
		cost_label.text = String(card_dict.get("cost", 1))
	
	# Set artwork using art mapping
	_set_card_art(card_dict)

func _set_card_art(card: Dictionary) -> void:
	"""Set card artwork using the art mapping"""
	if not art_rect:
		return
	
	var art_id: String = String(card.get("art_id", ""))
	var texture: Texture2D = null
	
	# Try to get texture from art mapping
	if art_id != "" and ART_MAPPING.has(art_id):
		var path = ART_MAPPING[art_id]
		if ResourceLoader.exists(path):
			texture = load(path)
	
	# Fallback: try to derive art_id from card name/id
	if texture == null:
		var fallback_id = _derive_art_id(card)
		if ART_MAPPING.has(fallback_id):
			var path = ART_MAPPING[fallback_id]
			if ResourceLoader.exists(path):
				texture = load(path)
	
	# Final fallback: card_back
	if texture == null and ART_MAPPING.has("card_back"):
		var path = ART_MAPPING["card_back"]
		if ResourceLoader.exists(path):
			texture = load(path)
	
	# Set the texture
	if texture != null:
		art_rect.texture = texture

func _derive_art_id(card: Dictionary) -> String:
	"""Derive art_id from card name or id"""
	var base_name: String = ""
	
	# Prefer explicit id if present
	if card.has("id"):
		base_name = String(card["id"]).strip_edges().to_lower()
	else:
		base_name = String(card.get("name", "")).strip_edges().to_lower()
	
	# Replace non-alphanumeric characters with underscores
	base_name = base_name.replace(" ", "_")
	base_name = base_name.replace("-", "_")
	base_name = base_name.replace("'", "")
	
	# Prepend art_ prefix if not already present
	if not base_name.begins_with("art_"):
		base_name = "art_" + base_name
	
	return base_name

func _ready() -> void:
	# Record original values for hover effect
	_orig_pos_y = position.y
	_orig_scale = scale
	_orig_z_index = z_index
	# Connect hover signals
	self.mouse_entered.connect(_on_mouse_entered)
	self.mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	# Lift and enlarge the card when hovered
	_z_index_to_front()
	position.y = _orig_pos_y - 20
	scale = _orig_scale * 1.1

func _on_mouse_exited() -> void:
	# Restore original position and scale
	position.y = _orig_pos_y
	scale = _orig_scale
	z_index = _orig_z_index

func _z_index_to_front() -> void:
	# Increase z_index relative to siblings so the hovered card appears on top
	# Find the maximum z_index among siblings and set this card higher.
	var parent := get_parent()
	if parent:
		var max_z := 0
		for c in parent.get_children():
			if c is CanvasItem:
				max_z = max(max_z, (c as CanvasItem).z_index)
		z_index = max_z + 1

func _on_click() -> void:
	# Emit pressed signal or call GameController.play_card(index)
	var game_controller: Node = get_node_or_null("/root/GameController")
	if game_controller != null and game_controller.has_method("play_card"):
		game_controller.call("play_card", index)
	else:
		# Fallback to signal
		emit_signal("pressed")
