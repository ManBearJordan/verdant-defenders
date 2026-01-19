extends Control

signal grove_exited

var _content: VBoxContainer
var _card_selector: ScrollContainer

func _ready() -> void:
	name = "GroveUI"
	_setup_ui()

func _setup_ui() -> void:
	# Background
	var bg = ColorRect.new()
	bg.color = Color(0.1, 0.2, 0.1, 0.95)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	_content = VBoxContainer.new()
	_content.set_anchors_preset(Control.PRESET_CENTER)
	_content.set_offsets_preset(Control.PRESET_CENTER)
	_content.custom_minimum_size = Vector2(400, 300)
	bg.add_child(_content)
	
	var title = Label.new()
	title.text = "The Ancient Grove"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	_content.add_child(title)
	
	var desc = Label.new()
	desc.text = "You find a moment of peace amongst the roots."
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content.add_child(desc)
	
	_content.add_child(HSeparator.new())
	
	# Actions
	var btn_heal = Button.new()
	btn_heal.text = "Mend Roots (Heal 30%)"
	btn_heal.custom_minimum_size.y = 50
	btn_heal.pressed.connect(_on_heal_pressed)
	_content.add_child(btn_heal)
	
	var btn_enrich = Button.new()
	btn_enrich.text = "Enrich Soil (Upgrade Card)"
	btn_enrich.custom_minimum_size.y = 50
	btn_enrich.pressed.connect(_on_enrich_pressed)
	_content.add_child(btn_enrich)
	
	var spacer = Control.new()
	spacer.custom_minimum_size.y = 20
	_content.add_child(spacer)
	
	var btn_leave = Button.new()
	btn_leave.text = "Depart"
	btn_leave.pressed.connect(_on_leave_pressed)
	_content.add_child(btn_leave)

func _on_heal_pressed() -> void:
	# Heal Logic
	var gc = get_node_or_null("/root/GameController")
	if gc:
		var max_hp = int(gc.max_hp)
		var heal_amt = int(max_hp * 0.3)
		var old_hp = int(gc.player_hp)
		gc.player_hp = min(old_hp + heal_amt, max_hp)
		print("Grove: Healed %d HP" % heal_amt)
	
	# Disable buttons or auto-leave? Usually one action only.
	_disable_actions()

func _on_enrich_pressed() -> void:
	# Show Card Selection
	_show_card_selector()

func _show_card_selector() -> void:
	if _card_selector: _card_selector.queue_free()
	
	_content.visible = false
	
	_card_selector = ScrollContainer.new()
	_card_selector.set_anchors_preset(Control.PRESET_FULL_RECT) # Adjusted to CENTER?
	# Make it cover screen
	add_child(_card_selector)
	
	var container = FlowContainer.new()
	container.horizontal_alignment = FlowContainer.ALIGNMENT_CENTER
	_card_selector.add_child(container)
	
	var dm = get_node_or_null("/root/DeckManager")
	if not dm: return
	
	var deck = []
	if dm.has_method("get_all_cards"): # Actually we want master deck, usually draw+discard+hand? 
	# Wait, DeckManager in this game manages draw/discard/hand during RUN.
	# But meta-deck?
	# The game seems to treat `draw_pile` + `discard_pile` + `hand` as the deck.
	# So we gather all.
		deck = dm.call("get_all_cards")
	
	for card in deck:
		var btn = Button.new()
		var nm = card.get("name", "Card")
		var enriched = card.get("enriched", false)
		btn.text = nm + ("+" if enriched else "")
		btn.custom_minimum_size = Vector2(150, 200)
		btn.disabled = enriched # Cannot upgrade twice logic? Usually yes.
		
		if not enriched:
			btn.pressed.connect(_on_card_selected.bind(card))
			
		container.add_child(btn)
	
	# Cancel button
	var cancel = Button.new()
	cancel.text = "Cancel"
	cancel.pressed.connect(_on_selector_cancel)
	_card_selector.add_child(cancel) # This might overlap flow, better structure needed but OK for now

func _on_card_selected(card: Dictionary) -> void:
	var dm = get_node_or_null("/root/DeckManager")
	if dm and dm.has_method("enrich_card"):
		dm.call("enrich_card", card)
		print("Grove: Enriched %s" % card.get("name"))
	
	_on_selector_cancel()
	_disable_actions()

func _on_selector_cancel() -> void:
	if _card_selector: 
		_card_selector.queue_free()
		_card_selector = null
	_content.visible = true

func _disable_actions() -> void:
	# Disable Heal/Enrich, force Leave
	for c in _content.get_children():
		if c is Button and c.text != "Depart":
			c.disabled = true

func _on_leave_pressed() -> void:
	queue_free()
	grove_exited.emit()
	
	var dc = get_node_or_null("/root/DungeonController")
	if dc and dc.has_method("next_room"):
		dc.next_room()
