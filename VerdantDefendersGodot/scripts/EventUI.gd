extends Control

signal event_done

@onready var gc = get_node("/root/GameController")
@onready var data = get_node("/root/DataLayer")

var event_type := ""

func _ready():
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	event_type = "heal" if (rng.randi() % 2 == 0) else "remove"
	_build()

func _build():
	var root = $Panel/VBox
	for c in root.get_children():
		c.queue_free()

	if event_type == "heal":
		var lab = Label.new()
		lab.text = "Sacred Spring: Drink to heal 15 HP?"
		root.add_child(lab)

		var yes = Button.new()
		yes.text = "Drink (+15 HP)"
		yes.pressed.connect(func():
			gc.player_hp = min(gc.player_hp + 15, gc.max_hp)
			_close())
		root.add_child(yes)

		var no = Button.new()
		no.text = "Leave"
		no.pressed.connect(_close)
		root.add_child(no)
	else:
		var lab2 = Label.new()
		lab2.text = "Ancient Altar: Remove a card from your deck?"
		root.add_child(lab2)

		for i in range(gc.current_deck.size()):
			var cid = String(gc.current_deck[i])
			var b = Button.new()
			b.text = "Remove: %s" % String(data.get_card(cid).get("name", cid))
			b.pressed.connect(func():
				var idx: int = gc.current_deck.find(cid)
				if idx != -1:
					gc.current_deck.remove_at(idx)
				_close())
			root.add_child(b)

		var skip = Button.new()
		skip.text = "Leave"
		skip.pressed.connect(_close)
		root.add_child(skip)

func _close():
	emit_signal("event_done")
	queue_free()
