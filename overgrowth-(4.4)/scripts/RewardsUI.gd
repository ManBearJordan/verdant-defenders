extends Control
signal rewards_done
@onready var data = get_node("/root/DataLayer")
@onready var gc = get_node("/root/GameController")
@onready var rewards = get_node("/root/RewardSystem")
var options: Array = []
func _ready(): options = rewards.roll_card_rewards(3, gc.current_class); _build()
func _build():
	var root = $Panel/VBox
	for c in root.get_children(): c.queue_free()
	var lab = Label.new(); lab.text = "Choose a card to add to your deck:"; root.add_child(lab)
	for i in range(options.size()):
		var c: Dictionary = options[i]
		var b = Button.new(); b.text = _card_title(c); b.tooltip_text = str(c); b.pressed.connect(_pick.bind(i)); root.add_child(b)
	var skip = Button.new(); skip.text = "Skip"; skip.pressed.connect(_skip); root.add_child(skip)
func _card_title(c: Dictionary) -> String:
	var title := "%s (Cost:%s)" % [str(c.get("name","?")), str(c.get("cost",0))]
	if c.has("damage"): title += "  DMG:%s" % str(c.get("damage"))
	if c.has("block"): title += "  BLK:%s" % str(c.get("block"))
	if c.has("apply"): var ap: Dictionary = c["apply"]; if ap.has("poison"): title += "  PSN:%s" % str(ap["poison"])
	return title
func _pick(i: int):
	var c: Dictionary = options[i]
	for k in data.cards.keys():
		var d: Dictionary = data.cards[k]
		if d == c: gc.current_deck.append(k); break
	_close()
func _skip(): _close()
func _close(): emit_signal("rewards_done"); queue_free()
