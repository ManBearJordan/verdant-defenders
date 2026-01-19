extends Control
class_name CardView

@onready var _art_node: TextureRect = %Art
@onready var _name: Label = %NameLabel
@onready var _cost: Label = %CostLabel
@onready var _type: Label = %TypeLabel
@onready var _effect: RichTextLabel = $DescContainer/Effect
@onready var _cost_orb: TextureRect = $CostOrb
@onready var _frame: TextureRect = $Frame

var resource: CardResource = null
var is_disabled: bool = false

const COLOR_ENERGY = Color(0.2, 0.6, 1.0) # Blue-ish
const COLOR_SEED   = Color(0.4, 0.8, 0.4) # Green-ish
const COLOR_RUNE   = Color(0.8, 0.4, 0.8) # Purple-ish
const COLOR_NEUTRAL= Color(1, 1, 1)

func _ready() -> void:
	pass

func setup(card: CardResource) -> void:
	resource = card
	_update_view()

func set_card(card: CardResource) -> void:
	setup(card)

func set_disabled(disabled: bool, reason: String = "") -> void:
	is_disabled = disabled
	if is_disabled:
		modulate = Color(0.6, 0.6, 0.6, 1.0)
		tooltip_text = reason
	else:
		modulate = Color.WHITE
		tooltip_text = ""

func _update_view() -> void:
	if not resource: return
	
	# Basic Info
	if _name: _name.text = resource.display_name
	if _cost: _cost.text = str(resource.cost)
	if _type: _type.text = resource.type
	
	# Description (RichText)
	if _effect:
		var text = resource.effect_text
		# Parse simple replacements if needed, e.g. !D! -> Damage
		_effect.text = "[center]" + text + "[/center]"
		
	# Cost Icon / Tint
	if _cost_orb:
		var tint = COLOR_ENERGY
		if "cost_seeds" in resource.tags:
			tint = COLOR_SEED
		elif "cost_runes" in resource.tags:
			tint = COLOR_RUNE
		
		# If cost is 0 and no special type, maybe just white or transparent? 
		# But usually 0 cost energy cards still show orb.
		_cost_orb.modulate = tint
		
	# Art Resolution
	_resolve_art()

func _resolve_art() -> void:
	if not _art_node: return
	
	# Use new ArtRegistry dynamic resolution
	var tex = ArtRegistry.get_card_texture(resource.id, resource.pool)
	
	if tex:
		_art_node.texture = tex
	else:
		# Fallback should be handled by ArtRegistry returning card_back or similar, 
		# but if it returns null, use a placeholder.
		# _art_node.texture = preload("res://icon.svg") 
		pass 
