extends Control

signal rewards_done

@onready var container = $Panel/VBox
var _offers: Array = []

func setup(offers: Array) -> void:
	_offers = offers
	_build()

func _build() -> void:
	if not container: return
	for c in container.get_children(): c.queue_free()
	
	var lab = Label.new()
	lab.text = "Choose a card to add to your deck:"
	container.add_child(lab)
	
	for i in range(_offers.size()):
		var c = _offers[i]
		var b = Button.new()
		b.text = _card_title(c)
		# b.tooltip_text = str(c) # Debug string, redundant with text
		b.pressed.connect(_pick.bind(i))
		container.add_child(b)
		
	var skip = Button.new()
	skip.text = "Skip"
	skip.pressed.connect(_skip)
	container.add_child(skip)

func _card_title(c: Dictionary) -> String:
	# Handle Resource object or Dictionary
	var name_str = c.get("name", "Unknown")
	var cost = c.get("cost", 0)
	var title := "%s (%s)" % [name_str, cost]
	return title

func _pick(i: int) -> void:
	var card = _offers[i]
	var dm = get_node_or_null("/root/DeckManager")
	if dm:
		# Assume DeckManager handles adding. 
		# If card is Resource, add_card works.
		if dm.has_method("add_card_to_deck"):
			dm.add_card_to_deck(card)
		else:
			print("RewardsUI: DeckManager missing add_card_to_deck")
	
	_close()

func _skip() -> void:
	_close()

func _close() -> void:
	emit_signal("rewards_done")
	# We don't queue_free immediately if GameUI manages us, but usually we do.
	# GameUI.show_rewards creates a new instance.
	# But wait, GameUI logic uses a persistent instance variable?
	# GameUI logic will likely expect to manage this.
	# For now, queue_free is fine if we notify parent.
	# Actually, GameUI should handle cleanup to avoid null refs.
	# But standard pattern is queue_free self.
	queue_free()

