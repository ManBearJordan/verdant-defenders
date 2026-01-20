extends Control

@onready var container = $Panel/VBox
@onready var flow = get_node("/root/FlowController")
@onready var dm = get_node("/root/DeckManager")

var current_context: String = "normal"
var miniboss_options: Array = []

func setup(context: String) -> void:
	current_context = context
	_generate_rewards(context)

func _generate_rewards(context: String) -> void:
	var rs = get_node_or_null("/root/RewardSystem")
	var rc = get_node_or_null("/root/RunController")
	if not rs or not rc: return
	
	var act = rc.current_act
	
	if context == "elite":
		var rewards = rs.generate_elite_rewards(act)
		# Build Elite UI (Shards + Card + Bonus)
		_build_elite_ui(rewards)
	elif context == "miniboss":
		var rewards = rs.generate_miniboss_rewards(act)
		# Build Choice UI
		_build_miniboss_ui(rewards)
	elif context == "boss":
		# Placeholder boss reward
		_build_normal_ui(rs.generate_normal_rewards(act))
	else:
		_build_normal_ui(rs.generate_normal_rewards(act))

func _build_miniboss_ui(data: Dictionary) -> void:
	if not container: return
	_clear_container()
	
	_add_header("MINI-BOSS DEFEATED!")
	_add_label("Choose ONE Reward:")
	
	miniboss_options = data.get("options", [])
	
	for i in range(miniboss_options.size()):
		var opt = miniboss_options[i]
		var btn = Button.new()
		btn.text = opt["label"]
		btn.pressed.connect(_on_miniboss_option.bind(opt))
		container.add_child(btn)

func _on_miniboss_option(opt: Dictionary) -> void:
	var type = opt.get("type")
	match type:
		"shards":
			_collect_shards(opt.get("amount", 0), null)
			_go_map()
		"card_reward":
			# Switch to card selection view?
			# Simple: use normal card generation and show it
			_clear_container()
			_add_header("Draft a Card")
			var rs = get_node_or_null("/root/RewardSystem")
			_offers = rs.offer_cards(3, "growth") # Todo: proper class
			_show_card_buttons()
		"sigil":
			# Grant random sigil
			var rs = get_node_or_null("/root/RewardSystem")
			if rs: rs.add_sigil_fragment(3) # Force sigil reward
			_go_map()

func _build_elite_ui(rewards: Dictionary) -> void:
	if not container: return
	_clear_container()
	_add_header("ELITE VICTORY!")
	
	# Shards
	if rewards.shards > 0:
		_add_shard_btn(rewards.shards)
		
	# Bonus
	if rewards.bonus:
		var lbl = Label.new()
		lbl.text = "Bonus: " + rewards.bonus.label
		container.add_child(lbl)
		if rewards.bonus.type == "shards":
			_collect_shards(rewards.bonus.amount, null) # Auto or button? Auto for bonus maybe
		elif rewards.bonus.type == "sigil_fragment":
			var rs = get_node_or_null("/root/RewardSystem")
			if rs: rs.add_sigil_fragment(rewards.bonus.amount)
			
	container.add_child(HSeparator.new())
	
	# Cards
	_offers = rewards.cards
	_show_card_buttons()

func _build_normal_ui(rewards: Dictionary) -> void:
	if not container: return
	_clear_container()
	_add_header("VICTORY!")
	
	if rewards.has("shards"):
		_add_shard_btn(rewards.shards)
		
	container.add_child(HSeparator.new())
	
	if rewards.has("cards"):
		_offers = rewards.cards
		_show_card_buttons()
	else:
		_add_continue_btn()

# --- UI Helpers ---

func _clear_container() -> void:
	for c in container.get_children(): c.queue_free()

func _add_header(text: String) -> void:
	var title = Label.new()
	title.text = text
	title.add_theme_font_size_override("font_size", 42)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(title)
	container.add_child(HSeparator.new())

func _add_label(text: String) -> void:
	var l = Label.new()
	l.text = text
	container.add_child(l)

func _add_shard_btn(amount: int) -> void:
	var sl = Button.new()
	sl.text = "Collect %d Verdant Shards" % amount
	sl.pressed.connect(_collect_shards.bind(amount, sl))
	container.add_child(sl)

func _add_continue_btn() -> void:
	var cont = Button.new()
	cont.text = "Continue"
	cont.pressed.connect(_go_map)
	container.add_child(cont)

func _show_card_buttons() -> void:
	if _offers.is_empty():
		_add_continue_btn()
		return
		
	var lab = Label.new()
	lab.text = "Choose a card:"
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

# --- Logic ---

func _ready() -> void:
	name = "RewardScreen"
	# Waith for setup() to be called by RunController

func _collect_shards(amount: int, btn: Button) -> void:
	if btn:
		btn.disabled = true
		btn.text = "Collected %d Shards" % amount
	var gc = get_node_or_null("/root/RunController") # Use RunController
	if gc:
		gc.modify_shards(amount)
		
func _pick(i: int) -> void:
	# Add card to deck
	var card = _offers[i]
	var rc = get_node_or_null("/root/RunController")
	if rc:
		rc.add_card(card.id)
	_go_map()

func _skip() -> void:
	_go_map()

func _go_map() -> void:
	var rc = get_node_or_null("/root/RunController")
	if rc:
		rc.return_to_map()

func _card_title(c: Object) -> String:
	# c is CardResource usually
	if c.get("title"): return c.title
	if c.get("id"): return c.id
	return "Unknown Card"
