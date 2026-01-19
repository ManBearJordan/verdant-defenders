extends Control
class_name PlayerHUD

@onready var _hp_bar: ProgressBar = %HPBar
@onready var _hp_label: Label = %HPLabel
@onready var _block_container: Control = %BlockContainer
@onready var _block_label: Label = %BlockLabel
@onready var _energy_label: Label = %EnergyLabel
@onready var _seeds_label: Label = %SeedsLabel
@onready var _gold_label: Label = %GoldLabel
@onready var _runes_label: Label = %RunesLabel
@onready var _hand_label: Label = %HandLabel
@onready var _status_container: HBoxContainer = %StatusContainer

func _ready() -> void:
	# Connect GameController Signals
	var gc = get_node_or_null("/root/GameController")
	if gc:
		if gc.has_signal("player_hp_changed"):
			gc.player_hp_changed.connect(_on_hp_changed)
		if gc.has_signal("player_stat_changed"):
			gc.player_stat_changed.connect(_on_stat_changed)
		if gc.has_signal("player_status_changed"):
			gc.player_status_changed.connect(_refresh_statuses)
			
		# Initial State
		_update_initial_state(gc)

	# Connect CombatSystem Signals
	var cs = get_node_or_null("/root/CombatSystem")
	if cs:
		if cs.has_signal("player_block_changed"):
			cs.player_block_changed.connect(_on_block_changed)
		_on_block_changed(cs.player_block)
		
	# Connect DeckManager Signals
	var dm = get_node_or_null("/root/DeckManager")
	if dm:
		if dm.has_signal("energy_changed"):
			dm.energy_changed.connect(_on_energy_changed)
		if dm.has_signal("hand_changed"):
			dm.hand_changed.connect(_on_hand_changed)
		
		_on_energy_changed(dm.energy)
		_on_hand_changed(dm.hand)

func _update_initial_state(gc: Node) -> void:
	_on_hp_changed(gc.player_hp, gc.max_hp)
	_refresh_statuses()
	_update_resources(gc)

func _on_energy_changed(amount: int) -> void:
	if _energy_label: _energy_label.text = "%d/3" % amount # TODO: Max energy

func _on_hand_changed(hand: Array) -> void:
	if _hand_label:
		# Max hand size is usually constant but can change
		_hand_label.text = "%d/5" % hand.size() 


func _update_resources(gc: Node) -> void:
	if "player_state" in gc:
		var s = gc.player_state.get("seeds", 0)
		var g = gc.player_state.get("gold", 0)
		var r = gc.player_state.get("runes", 0)
		
		if _seeds_label: _seeds_label.text = str(s)
		if _gold_label: _gold_label.text = str(g)
		if _runes_label: _runes_label.text = str(r)

func _on_hp_changed(current: int, max_hp: int) -> void:
	if _hp_bar:
		_hp_bar.max_value = max_hp
		_hp_bar.value = current
	if _hp_label:
		_hp_label.text = "%d/%d" % [current, max_hp]

func _on_block_changed(amount: int) -> void:
	if _block_label:
		_block_label.text = str(amount)
	
	if _block_container:
		_block_container.visible = (amount > 0)

func _on_stat_changed(stat: String, value: int) -> void:
	if stat == "seeds" and _seeds_label:
		_seeds_label.text = str(value)
	elif stat == "gold" and _gold_label:
		_gold_label.text = str(value)
	elif stat == "runes" and _runes_label:
		_runes_label.text = str(value)

func _refresh_statuses() -> void:
	if not _status_container: return
	
	for c in _status_container.get_children():
		c.queue_free()
		
	var gc = get_node_or_null("/root/GameController")
	if not gc: return
	
	var statuses = gc.player_state.get("statuses", {})
	
	# Create icons
	for name in statuses:
		var stacks = statuses[name]
		if stacks <= 0: continue
		
		var icon = _create_status_icon(name, stacks)
		_status_container.add_child(icon)

func _create_status_icon(id: String, stacks: int) -> Control:
	# Simple placeholder icon logic or load from ArtRegistry
	# Ideally we have a StatusIcon.tscn, but for now we build simple
	var p = Panel.new()
	p.custom_minimum_size = Vector2(40, 40)
	p.add_theme_stylebox_override("panel", _get_status_style(id))
	p.tooltip_text = "%s: %d" % [id.capitalize(), stacks]
	
	var lbl = Label.new()
	lbl.text = str(stacks)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	p.add_child(lbl)
	
	return p

func _get_status_style(id: String) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.set_corner_radius_all(4)
	match id:
		"poison": sb.bg_color = Color.WEB_GREEN
		"burn": sb.bg_color = Color.ORANGE_RED
		"weak": sb.bg_color = Color.YELLOW
		"vulnerable": sb.bg_color = Color.MAGENTA
		"strength": sb.bg_color = Color.RED
		_: sb.bg_color = Color.GRAY
	return sb
