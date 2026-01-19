extends Control

@onready var container = $Panel/VBox
@onready var flow = get_node("/root/FlowController")
@onready var dm = get_node("/root/DeckManager")

var _offers: Array = []

func _ready() -> void:
	name = "RewardScreen"
	if flow and "cards" in flow.transition_data:
		_offers = flow.transition_data["cards"]
		
	var shards = 0
	if flow and "shards" in flow.transition_data:
		shards = flow.transition_data["shards"]
		
	_build(shards)

func _build(bonus_shards: int) -> void:
	if not container: return
	for c in container.get_children(): c.queue_free()
	
	# Victory Header
	var title = Label.new()
	title.text = "VICTORY!"
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color("f0e68c"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(title)
	
	container.add_child(HSeparator.new())
	
	# Shards Reward
	if bonus_shards > 0:
		var sl = Button.new()
		sl.text = "Collect %d Verdant Shards" % bonus_shards
		sl.icon = preload("res://Art/ui/gold.png") # Optional if exists
		sl.alignment = HORIZONTAL_ALIGNMENT_LEFT
		sl.pressed.connect(_collect_shards.bind(bonus_shards, sl))
		container.add_child(sl)
		
	# Sigil Reward (from flow)
	if flow and "sigil" in flow.transition_data:
		var sigil_data = flow.transition_data["sigil"]
		var sb = Button.new()
		sb.text = "Take Sigil: %s" % sigil_data.get("name", "Unknown")
		sb.alignment = HORIZONTAL_ALIGNMENT_LEFT
		sb.pressed.connect(_collect_sigil.bind(sigil_data, sb))
		container.add_child(sb)
	
	container.add_child(HSeparator.new())
	
	# Card Rewards
	if not _offers.is_empty():
		var lab = Label.new()
		lab.text = "Choose a card to add to your deck:"
		container.add_child(lab)
		
		for i in range(_offers.size()):
			var c = _offers[i]
			var b = Button.new()
			b.text = _card_title(c)
			b.pressed.connect(_pick.bind(i))
			container.add_child(b)
			
		var skip = Button.new()
		skip.text = "Skip Card Reward"
		skip.pressed.connect(_skip)
		container.add_child(skip)
	else:
		var cont = Button.new()
		cont.text = "Continue"
		cont.pressed.connect(_go_map)
		container.add_child(cont)

func _collect_shards(amount: int, btn: Button) -> void:
	btn.disabled = true
	btn.text = "Collected %d Shards" % amount
	var gc = get_node_or_null("/root/GameController")
	if gc:
		var current = gc.get("verdant_shards")
		gc.set("verdant_shards", current + amount)

func _collect_sigil(data: Dictionary, btn: Button) -> void:
	btn.disabled = true
	btn.text = "Taken: %s" % data.get("name")
	var ss = get_node_or_null("/root/SigilSystem")
	if ss:
		ss.add_sigil(data.get("id"))

func _card_title(c: Dictionary) -> String:
	var name_str = c.get("name", "Unknown")
	var cost = c.get("cost", 0)
	return "%s (%s e)" % [name_str, cost]

func _pick(i: int) -> void:
	var card = _offers[i]
	if dm:
		if dm.has_method("add_card_to_deck"):
			dm.add_card_to_deck(card)
	
	_go_map()

func _skip() -> void:
	_go_map()

func _go_map() -> void:
	if flow:
		# DungeonController needs to trigger next_room?
		# Previously RoomController finished, then GameUI showed rewards, then done -> next_room.
		# Rewiring:
		# Combat finishes -> RoomController -> Flow(REWARD)
		# Reward finishes -> Flow(MAP).
		# BUT DungeonController logic state needs to advance (current_node processing complete).
		# We must call dc.next_room() BEFORE going to map? Or AFTER?
		# dc.next_room() usually resets the view.
		var dc = get_node_or_null("/root/DungeonController")
		if dc: dc.next_room() # This unlocks movement
		
		flow.goto(flow.GameState.MAP)
