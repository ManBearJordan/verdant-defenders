extends Control
class_name CardView

@onready var _art_node: Node = _find_art_node()
@onready var _name: Label = %NameLabel
@onready var _cost: Label = %CostLabel
@onready var _effect: Node = get_node_or_null("Effect")

var resource: CardResource = null

func _find_art_node() -> Node:
	var node = get_node_or_null("%Art")
	if node: return node
	node = get_node_or_null("ArtContainer/Art")
	if node: return node
	node = get_node_or_null("Art")
	if node: return node
	return find_child("Art")

func setup(card: CardResource) -> void:
	resource = card
	_set_labels(card)
	_set_art(card)
	_set_description(card)

func set_card(card: CardResource) -> void:
	setup(card)

func _set_labels(card: CardResource) -> void:
	if _name: _name.text = card.display_name
	if _cost: _cost.text = str(card.cost)

func _set_description(card: CardResource) -> void:
	var eff = find_child("Effect")
	if eff:
		# Use effect_text directly; logic_meta is for internal resolution
		var text = card.effect_text
		if eff is RichTextLabel:
			eff.text = "[center]" + text + "[/center]"
		else:
			eff.text = text

func _set_art(card: CardResource) -> void:
	if not _art_node: return
	var tex = _resolve_art_texture(card)
	if _art_node is TextureRect:
		_art_node.texture = tex
	elif _art_node is Sprite2D:
		_art_node.texture = tex

func _resolve_art_texture(card: CardResource) -> Texture2D:
	var art_id = card.art_id
	if art_id == "":
		if card.id != "": art_id = "art_" + card.id
		else: art_id = "art_" + card.display_name.to_lower().replace(" ", "_")
		
	var candidate_paths := [
		"res://Art/%s.png" % art_id,
		"res://Art/cards/%s.png" % art_id,
		"res://Art/cards/Growth Cards/%s.png" % art_id,
		"res://Art/cards/Decay Cards/%s.png" % art_id,
		"res://Art/cards/Elemental Cards/%s.png" % art_id
	]

	var tex: Texture2D = null
	for p in candidate_paths:
		if ResourceLoader.exists(p):
			tex = load(p)
			break
	if tex == null and ResourceLoader.exists("res://Art/card_back.png"):
		tex = load("res://Art/card_back.png")
	return tex

func _ready() -> void:
	pass
