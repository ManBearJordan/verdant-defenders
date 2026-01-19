extends Control

# CombatScreen - Handles the Fight View

const CARD_SCENE: PackedScene = preload("res://Scenes/CardView.tscn")
const ENEMY_SCENE: PackedScene = preload("res://Scenes/EnemyView.tscn")

@onready var enemies_box: HBoxContainer = $Enemies
@onready var hand_box: HBoxContainer = $Hand
@onready var _background: TextureRect = $Background

# Header / Turn Flow
@onready var _turn_label: Label = %TurnLabel
@onready var _end_turn_btn: Button = %EndTurnButton
@onready var _turn_banner: Label = %TurnBanner

# Piles
@onready var _draw_btn: Button = %DrawPile
@onready var _discard_btn: Button = %DiscardPile
@onready var _exhaust_btn: Button = %ExhaustPile
@onready var _deck_view: DeckView = %DeckView

# Visuals
var _hand_container: Control = null
var _last_hand: Array = []
var _pending_card_index: int = -1

const HAND_WIDTH = 750.0
const HAND_ARC_HEIGHT = 40.0
const CARD_ROTATION_SPREAD = 15.0

# --- Setup ---
func _ready() -> void:
	name = "CombatScreen"
	
	# 1. Setup Hand Container
	_hand_container = Control.new()
	_hand_container.name = "HandArcContainer"
	_hand_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hand_container)
	_hand_container.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_hand_container.offset_top = -300
	
	if hand_box: hand_box.visible = false
	
	# 2. Signals
	var dm = get_node_or_null("/root/DeckManager")
	if dm:
		dm.hand_changed.connect(_on_hand_changed)
		dm.energy_changed.connect(_on_energy_changed)
		if dm.has_signal("piles_changed"):
			dm.piles_changed.connect(_update_piles)
		
	var gc = get_node_or_null("/root/GameController")
	if gc:
		gc.player_turn_started.connect(_on_player_turn_started)
		gc.enemy_turn_started.connect(_on_enemy_turn_started)
		
	# Pile Connections
	_draw_btn.pressed.connect(_on_pile_clicked.bind("draw_pile"))
	_discard_btn.pressed.connect(_on_pile_clicked.bind("discard_pile"))
	_exhaust_btn.pressed.connect(_on_pile_clicked.bind("exhaust"))
	
	# End Turn
	_end_turn_btn.pressed.connect(_on_end_turn_pressed)
	
	# Initial Refresh
	_refresh_all()
	_update_piles()
	
	# Check Background or Phase
	var fc = get_node_or_null("/root/FlowController")
	if fc and fc.transition_data.has("type"):
		pass 
		
	# Lifecycle
	call_deferred("_spawn_enemies")
	
	# If loaded in middle of turn?
	if gc and gc.is_current_player_turn():
		_end_turn_btn.disabled = false
	else:
		_end_turn_btn.disabled = true

func _refresh_all() -> void:
	_refresh_header()
	_refresh_hand()
	_update_piles()

# --- Piles ---
func _update_piles() -> void:
	var dm = get_node_or_null("/root/DeckManager")
	if not dm: return
	_draw_btn.text = "Draw\n%d" % dm.draw_pile.size()
	_discard_btn.text = "Discard\n%d" % dm.discard_pile.size()
	_exhaust_btn.text = "Exhaust\n%d" % dm.exhaust.size()

func _on_pile_clicked(type: String) -> void:
	var dm = get_node_or_null("/root/DeckManager")
	if not dm: return
	
	var list = []
	var title = "Deck"
	match type:
		"draw_pile": 
			list = dm.draw_pile
			title = "Draw Pile"
		"discard_pile": 
			list = dm.discard_pile
			title = "Discard Pile"
		"exhaust": 
			list = dm.exhaust
			title = "Exhaust Pile"
			
	if _deck_view:
		_deck_view.show_list(list, title)

# --- Header / Turn ---
func _refresh_header() -> void:
	var gc = get_node_or_null("/root/GameController")
	var turn = gc.get_current_turn() if gc else 1
	_turn_label.text = "Turn %d" % turn
	
	if gc:
		_end_turn_btn.disabled = not gc.is_current_player_turn()

func _on_end_turn_pressed() -> void:
	var gc = get_node_or_null("/root/GameController")
	if gc: gc.end_player_turn()

func _on_player_turn_started() -> void:
	_refresh_all()
	_end_turn_btn.disabled = false
	_show_turn_banner("PLAYER TURN")
	if _hand_container: _hand_container.visible = true

func _on_enemy_turn_started() -> void:
	_refresh_header()
	_end_turn_btn.disabled = true
	_show_turn_banner("ENEMY TURN")
	# Hide hand or block input?
	# Visual blocking:
	if _hand_container: _hand_container.visible = false 
	# Or keep visible but non-interactable:
	# _hand_container.mouse_filter = IGNORE

func _show_turn_banner(text: String) -> void:
	if not _turn_banner: return
	_turn_banner.text = text
	_turn_banner.visible = true
	_turn_banner.modulate.a = 0.0
	
	var tw = create_tween()
	tw.tween_property(_turn_banner, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_interval(1.0)
	tw.tween_property(_turn_banner, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_callback(func(): _turn_banner.visible = false)

# --- Enemies ---
func _spawn_enemies() -> void:
	if not enemies_box: return
	for c in enemies_box.get_children(): c.queue_free()
	
	var cs = get_node_or_null("/root/CombatSystem")
	if not cs: return
	
	var enemies = cs.get_enemies()
	for unit in enemies:
		if unit.is_dead(): continue
		var view = ENEMY_SCENE.instantiate()
		enemies_box.add_child(view)
		if view.has_method("setup"):
			view.setup(unit)

# --- Hand ---
func _on_hand_changed(h): _refresh_hand()
func _on_energy_changed(e): pass # Handled by pile/HUD maybe? Or just refresh pile

func _refresh_hand() -> void:
	if not _hand_container: return
	for c in _hand_container.get_children(): c.queue_free()
	
	var dm = get_node_or_null("/root/DeckManager")
	if not dm: return
	
	_last_hand = dm.get_hand()
	for i in range(_last_hand.size()):
		var card = _last_hand[i]
		var v = CARD_SCENE.instantiate()
		if v.has_method("setup"): v.setup(card)
		_hand_container.add_child(v)
		
		# Click
		var catcher = v.get_node_or_null("ClickCatcher")
		if catcher: catcher.pressed.connect(_on_card_pressed.bind(i))
		elif v is BaseButton: v.pressed.connect(_on_card_pressed.bind(i))

# --- Input / Play ---
func _on_card_pressed(idx: int) -> void:
	if _end_turn_btn.disabled: return # Block input if enemy turn
	
	if idx < 0 or idx >= _last_hand.size(): return
	var card = _last_hand[idx]
	
	if _card_needs_target(card):
		_pending_card_index = idx
		print("CombatScreen: Select Target for %s" % card.name)
		# Show targeting cursor?
	else:
		_play_card(idx, -1)

func _card_needs_target(card) -> bool:
	return (card.damage > 0 or "target" in card.tags)

func _input(event: InputEvent) -> void:
	if _end_turn_btn.disabled: return
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _pending_card_index != -1:
			var t_idx = _check_enemy_click(get_global_mouse_position())
			if t_idx != -1:
				_play_card(_pending_card_index, t_idx)
				_pending_card_index = -1
			else:
				# Cancel
				_pending_card_index = -1

func _check_enemy_click(pos: Vector2) -> int:
	if not enemies_box: return -1
	for i in range(enemies_box.get_child_count()):
		var c = enemies_box.get_child(i)
		if c.get_global_rect().has_point(pos):
			return i
	return -1

func _play_card(hand_idx: int, target_idx: int) -> void:
	if hand_idx < 0 or hand_idx >= _last_hand.size(): return
	var card = _last_hand[hand_idx]
	
	if not _can_play_card(card):
		print("CombatScreen: Not enough resources to play %s" % card.display_name)
		return
		
	var gc = get_node_or_null("/root/GameController")
	if gc:
		var success = gc.play_card(hand_idx, target_idx)
		if not success:
			print("CombatScreen: Failed to play card (GC rejected)")
		else:
			# Visual feedback? Tween card to center?
			pass

func _can_play_card(card) -> bool:
	var gc = get_node_or_null("/root/GameController")
	if not gc: return false
	
	var cost = card.cost
	
	if "cost_seeds" in card.tags:
		var seeds = gc.player_state.get("seeds", 0)
		return seeds >= cost
	elif "cost_runes" in card.tags:
		var runes = gc.player_state.get("runes", 0)
		return runes >= cost
	else:
		# Energy
		var dm = get_node_or_null("/root/DeckManager")
		if dm: return dm.energy >= cost
		return false

func _process(delta: float) -> void:
	_data_bind_update(delta)

func _data_bind_update(delta: float) -> void:
	# Targeting Highlight
	if _pending_card_index != -1:
		var mpos = get_global_mouse_position()
		if enemies_box:
			for i in range(enemies_box.get_child_count()):
				var c = enemies_box.get_child(i)
				var hover = c.get_global_rect().has_point(mpos)
				if c.has_method("set_highlight"):
					c.set_highlight(hover)
	else:
		# Clear highlights
		if enemies_box:
			for c in enemies_box.get_children():
				if c.has_method("set_highlight"): c.set_highlight(false)

	# Hand Arc Logic
	if _hand_container and _hand_container.get_child_count() > 0:
		var cards = _hand_container.get_children()
		var count = cards.size()
		var center_x = get_viewport_rect().size.x / 2.0
		var total_w = min(count * 110, HAND_WIDTH)
		var start_x = center_x - (total_w / 2.0)
		var step = 0
		if count > 1: step = total_w / (count - 1)
		
		for i in range(count):
			var c = cards[i]
			var tx = start_x + (i * step)
			if count == 1: tx = center_x - (c.size.x / 2.0)
			
			# Hover logic
			if c.get_global_rect().has_point(get_global_mouse_position()) and not c.is_disabled:
				c.position.y = lerp(c.position.y, -40.0, 15 * delta) # Pop up
				c.scale = c.scale.lerp(Vector2(1.2, 1.2), 15 * delta)
				c.z_index = 10
			else:
				c.position.y = lerp(c.position.y, 0.0, 10 * delta)
				c.scale = c.scale.lerp(Vector2(1.0, 1.0), 10 * delta)
				c.z_index = 0
				
			c.position.x = lerp(c.position.x, tx, 10 * delta)
			
			# Check playability
			var card_res = c.resource
			if card_res and c.has_method("set_disabled"):
				var playable = _can_play_card(card_res)
				c.set_disabled(not playable, "Not enough resources")
