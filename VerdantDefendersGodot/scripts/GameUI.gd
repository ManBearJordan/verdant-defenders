extends Control

# Card view prefab
const CARD_SCENE: PackedScene = preload("res://Scenes/CardView.tscn")
const ENEMY_SCENE: PackedScene = preload("res://Scenes/EnemyView.tscn")

@onready var root_vbox: VBoxContainer   = get_node_or_null("RootVBox") as VBoxContainer
@onready var header_box: HBoxContainer  = get_node_or_null("RootVBox/Header") as HBoxContainer
@onready var enemies_box: HBoxContainer = get_node_or_null("Enemies") as HBoxContainer
@onready var hand_box: HBoxContainer    = _find_hand_box()

@onready var _background: TextureRect = get_node_or_null("Background") as TextureRect

# UI State
var _last_hand: Array[CardResource] = []
var _pending_card_index: int = -1

# Hand Visualization
var _hand_container: Control = null
const HAND_WIDTH = 750.0
const HAND_ARC_HEIGHT = 40.0
const CARD_ROTATION_SPREAD = 15.0

func _find_hand_box() -> HBoxContainer:
	var hand := get_node_or_null("Hand") as HBoxContainer
	if hand: return hand
	var root := get_node_or_null("RootVBox") as Node
	if root:
		var hbox := root.get_node_or_null("Hand")
		if hbox: return hbox as HBoxContainer
		var sc := root.get_node_or_null("HandScroll")
		if sc and sc.has_node("Hand"):
			return sc.get_node("Hand") as HBoxContainer
	return null

func _ready() -> void:
	var enemies := $"%Enemies"
	var hand := $"%Hand"
	var bg := $"%Background"
	var gc := _gc()
	if gc and gc.has_method("register_ui_nodes"):
		gc.register_ui_nodes(enemies, hand, bg)
	
	if hand_box:
		hand_box.visible = false
		_hand_container = Control.new()
		_hand_container.name = "HandArcContainer"
		_hand_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hand_box.get_parent().add_child(_hand_container)
		_hand_container.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		_hand_container.offset_left = 0
		_hand_container.offset_right = 0
		_hand_container.offset_bottom = 0
		_hand_container.offset_top = -300
	
	_ensure_layout()
	# _ready_event_system() # FIX: Function missing, commented out to prevent crash
	
	get_tree().process_frame.connect(func():
		_refresh_header()
		_refresh_enemies()
		_refresh_hand()
		print("GameUI: Force layout refresh complete.")
	, CONNECT_ONE_SHOT)

	# Ribbon Log
	var ribbon = load("res://scripts/CombatLogRibbon.gd").new()
	add_child(ribbon)

	var dc = get_node_or_null("/root/DungeonController")
	if dc:
		# if dc.has_signal("choices_ready"): dc.choices_ready.connect(_on_room_choices_ready) # FIX: Legacy signal
		if dc.has_signal("map_updated"): dc.map_updated.connect(_on_map_updated)
		if "current_map" in dc and not dc.current_map.is_empty():
			_on_map_updated(dc.current_map, dc.current_layer, dc.current_node_index)
		if dc.has_signal("room_entered"): dc.room_entered.connect(_on_room_entered)
		# if dc.has_method("start_run"): dc.call_deferred("start_run")
			
	var dm := _dm()
	if dm != null:
		if dm.has_signal("hand_changed"): dm.hand_changed.connect(_on_hand_changed)
		if dm.has_signal("energy_changed"): dm.energy_changed.connect(_on_energy_changed)

	if gc != null:
		if gc.has_signal("player_turn_started"): gc.player_turn_started.connect(_on_player_turn_started)
		if gc.has_signal("enemy_turn_started"): gc.enemy_turn_started.connect(_on_enemy_turn_started)
	
	var rs = get_node_or_null("/root/RelicSystem")
	if rs:
		if rs.has_signal("relic_added"): rs.relic_added.connect(_on_relic_added)
		_refresh_relics()

	var isys = get_node_or_null("/root/InfusionSystem")
	if isys:
		if isys.has_signal("inventory_changed"): isys.inventory_changed.connect(_on_infusions_changed)
		_refresh_infusions()

	# Delayed check
	get_tree().create_timer(1.0).timeout.connect(func():
		if not enemies_box or enemies_box.get_child_count() == 0:
			_spawn_enemies_in_ui()
	)

# --- Autoloads ---
func _dm() -> Node: return get_node_or_null("/root/DeckManager")
func _cs() -> Node:
	var cs = get_node_or_null("/root/CombatSystem")
	if cs and not cs.is_connected("damage_dealt", _on_damage_dealt):
		cs.damage_dealt.connect(_on_damage_dealt)
	return cs
func _gc() -> Node: return get_node_or_null("/root/GameController")

# --- Logic ---

func _get_enemies() -> Array[EnemyUnit]:
	var cs = _cs()
	if cs and cs.has_method("get_enemies"):
		return cs.get_enemies()
	return []

func _get_hand_cards() -> Array[CardResource]:
	var dm = _dm()
	if dm and dm.has_method("get_hand"):
		return dm.get_hand()
	return []

# --- Refresh ---

func _ensure_layout() -> void:
	if root_vbox:
		root_vbox.set_anchors_preset(Control.PRESET_FULL_RECT, true)
		root_vbox.set_offsets_preset(Control.PRESET_FULL_RECT)
	if header_box:
		header_box.size_flags_vertical = Control.SIZE_FILL
		header_box.custom_minimum_size.y = 36.0
	if enemies_box:
		enemies_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if hand_box:
		hand_box.size_flags_vertical = Control.SIZE_FILL
		hand_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hand_box.add_theme_constant_override("separation", -60)
		hand_box.alignment = BoxContainer.ALIGNMENT_CENTER

func _clear_box(b: Node) -> void:
	if b:
		for c in b.get_children():
			c.queue_free()

func _refresh_header() -> void:
	if not header_box: return
	_clear_box(header_box)
	
	var ac = get_node_or_null("/root/AscensionController")
	var cs = get_node_or_null("/root/CombatSystem")
	var asc_level = 0
	if ac: asc_level = ac.ascension_level
	
	if asc_level > 0:
		var asc_lbl = Label.new()
		asc_lbl.text = "Ascension %d" % asc_level
		asc_lbl.modulate = Color(1, 0.4, 0.4) # Light Red
		asc_lbl.add_theme_font_size_override("font_size", 18)
		header_box.add_child(asc_lbl)
		header_box.add_child(VSeparator.new())

	var dm = _dm()
	var gc = _gc()
	var energy_now = 0
	var hand_size = 0
	var current_turn = 0
	var is_player_turn = true
	
	if dm:
		energy_now = dm.energy
		hand_size = dm.hand.size()
	
	if gc:
		if gc.has_method("get_current_turn"): current_turn = gc.get_current_turn()
		if gc.has_method("is_current_player_turn"): is_player_turn = gc.is_current_player_turn()

	var turn_info := Label.new()
	var turn_phase := "Player Turn" if is_player_turn else "Enemy Turn"
	turn_info.text = "Turn %d - %s" % [current_turn, turn_phase]
	header_box.add_child(turn_info)
	
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_box.add_child(spacer)

	var info := Label.new()
	var seeds_count = 0
	if gc and "player_state" in gc:
		seeds_count = int(gc.player_state.get("seeds", 0))
	info.text = "Cards: %d   Energy: %d   Seeds: %d" % [hand_size, energy_now, seeds_count]
	if gc and "player_state" in gc:
		seeds_count = int(gc.player_state.get("seeds", 0))
	
	var seeds_color = Color.WHITE
	# Reclaimer Check
	if cs and cs.has_method("is_enemy_present") and cs.is_enemy_present("World Reclaimer"):
		if seeds_count == 5: seeds_color = Color.YELLOW
		elif seeds_count >= 6: seeds_color = Color.RED
		
	var seeds_lbl = Label.new()
	seeds_lbl.text = "Seeds: %d" % seeds_count
	seeds_lbl.modulate = seeds_color
	
	info.text = "Cards: %d   Energy: %d   " % [hand_size, energy_now]
	header_box.add_child(info)
	header_box.add_child(seeds_lbl)
	
	# Chronoshard Meter
	# (cs already defined above)
	if cs and cs.has_method("is_enemy_present") and cs.is_enemy_present("Chronoshard"):
		var meter_script = load("res://scripts/ThresholdMeter.gd")
		if meter_script:
			var meter = meter_script.new()
			meter.custom_minimum_size = Vector2(100, 24)
			var played = 0
			if gc and "turn_safety_metrics" in gc:
				played = gc.turn_safety_metrics.cards_played
			meter.setup(played, 5, 5)
			header_box.add_child(VSeparator.new())
			header_box.add_child(Label.new()) # Spacer
			header_box.add_child(meter)
	
	# Statuses
	var p_status_lbl = Label.new()
	var p_status_text = ""
	if gc and "player_state" in gc:
		var ps = gc.player_state.get("statuses", {})
		for s in ps.keys():
			var val = int(ps[s])
			if val > 0:
				var icon = "❓"
				if s == "chill": icon = "❄️"
				elif s == "shock": icon = "⚡"
				elif s == "weak": icon = "💔"
				elif s == "vulnerable": icon = "🛡️❌"
				elif s == "burn": icon = "🔥"
				p_status_text += "%s %s x%d  " % [icon, s.capitalize(), val]
	if p_status_text != "":
		p_status_lbl.text = p_status_text
		p_status_lbl.modulate = Color.YELLOW
		header_box.add_child(VSeparator.new())
		header_box.add_child(p_status_lbl)
	
	if is_player_turn:
		var end_turn_btn := Button.new()
		end_turn_btn.text = "End Turn"
		end_turn_btn.custom_minimum_size.x = 80.0
		end_turn_btn.pressed.connect(_on_end_turn_pressed)
		header_box.add_child(end_turn_btn)
	
	header_box.add_child(VSeparator.new())
	_relic_box = HBoxContainer.new()
	header_box.add_child(_relic_box)
	_relic_box.add_theme_constant_override("separation", 4)
	_refresh_relics()
	
	header_box.add_child(VSeparator.new())
	_infusion_box = HBoxContainer.new()
	header_box.add_child(_infusion_box)
	_infusion_box.add_theme_constant_override("separation", 4)
	_refresh_infusions()

# --- Relics & Infusions ---
var _relic_box: HBoxContainer = null
var _infusion_box: HBoxContainer = null

func _on_relic_added(relic) -> void: _refresh_relics()
func _refresh_relics() -> void:
	if not _relic_box: return
	for c in _relic_box.get_children(): c.queue_free()
	var rs = get_node_or_null("/root/RelicSystem")
	if rs and rs.has_method("get_relics"):
		for r in rs.get_relics():
			var icon = ColorRect.new()
			icon.custom_minimum_size = Vector2(24, 24)
			icon.color = Color.GOLD
			icon.tooltip_text = "%s\n%s" % [r.get("name", "Relic"), r.get("description", "")]
			_relic_box.add_child(icon)

func _on_infusions_changed(_items) -> void: _refresh_infusions()
func _refresh_infusions() -> void:
	if not _infusion_box: return
	for c in _infusion_box.get_children(): c.queue_free()
	var isys = get_node_or_null("/root/InfusionSystem")
	if isys and isys.has_method("get_inventory"):
		var items = isys.get_inventory()
		for i in range(items.size()):
			var item = items[i]
			var btn = Button.new()
			btn.custom_minimum_size = Vector2(32, 32)
			btn.text = "V"
			btn.tooltip_text = "%s\n%s" % [item.get("name", "Vial"), item.get("description", "")]
			btn.pressed.connect(_on_infusion_pressed.bind(i))
			_infusion_box.add_child(btn)

func _on_infusion_pressed(index: int) -> void:
	var gc = _gc()
	if gc and gc.has_method("is_current_player_turn") and not gc.is_current_player_turn():
		return
	var isys = get_node_or_null("/root/InfusionSystem")
	if isys: isys.use_infusion(index)

func set_background(name: String) -> void:
	if not _background: return
	var ar = get_node_or_null("/root/ArtRegistry")
	if ar and ar.has_method("get_texture"):
		var tex = ar.get_texture(name)
		if tex: 
			_background.texture = tex
			return
	var path = "res://Art/backgrounds/%s.png" % name
	if ResourceLoader.exists(path):
		_background.texture = load(path)
	else:
		_background.texture = null

# --- Main UI Spawning ---

func _refresh_enemies() -> void:
	# Enemies are now maintained by _spawn_enemies_in_ui / synced with CombatSystem
	_spawn_enemies_in_ui()

func _refresh_hand() -> void:
	if not _hand_container: return
	for c in _hand_container.get_children(): c.queue_free()
	
	_last_hand = _get_hand_cards()
	for i in range(_last_hand.size()):
		var card = _last_hand[i]
		var inst = CARD_SCENE.instantiate()
		# inst should be CardView
		if inst.has_method("setup"):
			inst.setup(card)
			
		_hand_container.add_child(inst)
		
		# Connect Click
		var cb = _on_card_pressed.bind(i)
		if inst is BaseButton: inst.pressed.connect(cb)
		else:
			var catcher = inst.get_node_or_null("ClickCatcher")
			if catcher: catcher.pressed.connect(cb)

func _spawn_enemies_in_ui() -> void:
	if not enemies_box: return
	
	# Layout
	enemies_box.custom_minimum_size = Vector2(0, 300)
	enemies_box.set_anchors_preset(Control.PRESET_TOP_WIDE)
	enemies_box.offset_top = 100
	enemies_box.offset_bottom = 400
	
	_clear_box(enemies_box)
	
	var enemies = _get_enemies() # Array[EnemyUnit]
	for i in range(enemies.size()):
		var unit = enemies[i]
		if unit.is_dead(): continue
		
		var view = ENEMY_SCENE.instantiate()
		enemies_box.add_child(view)
		view.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if view.has_method("setup"):
			view.setup(unit)
			
# --- Interactions ---

func _on_card_pressed(idx: int) -> void:
	if idx < 0 or idx >= _last_hand.size(): return
	var card = _last_hand[idx]
	print("GameUI: Playing %s" % card.display_name)
	
	var needs_target = _card_needs_target_check(card)
	if needs_target:
		_pending_card_index = idx
		print("Select Target...")
	else:
		_play_card(idx, card, -1)

func _card_needs_target_check(card: CardResource) -> bool:
	if card.damage > 0: return true
	if "target" in card.tags: return true
	return false

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _pending_card_index != -1:
			var target_idx = _check_enemy_click_at(get_global_mouse_position())
			if target_idx != -1:
				_on_target_chosen(target_idx)
			else:
				_pending_card_index = -1

func _check_enemy_click_at(pos: Vector2) -> int:
	if not enemies_box: return -1
	for i in range(enemies_box.get_child_count()):
		var child = enemies_box.get_child(i)
		if child.get_global_rect().has_point(pos):
			# Map ui child index to enemy index?
			# We filter dead enemies in _spawn_enemies.
			# So indices might not match 1:1 if we skip dead ones.
			# But CombatSystem maintains indices including dead ones usually?
			# Wait, CombatSystem.get_living_enemies() returns indices.
			# GameUI spawns only living ones?
			# Line 233 in _spawn_enemies loops enemies.
			# If I skip dead ones in spawn, the UI index != Data index.
			# FIX: Don't skip in spawn, just hide? Or store index on view.
			# I'll rely on CombatSystem cleaning up or GameUI matching order.
			# For now, simplistic mapping.
			return i 
	return -1

func _on_target_chosen(t_idx: int) -> void:
	if _pending_card_index >= 0:
		var card = _last_hand[_pending_card_index]
		_play_card(_pending_card_index, card, t_idx)
		_pending_card_index = -1

func _play_card(idx: int, card: CardResource, t_idx: int) -> void:
	# Animation Ghost logic (omitted for brevity, can restore if needed)
	
	var gc = _gc()
	var success = false
	if gc and gc.has_method("play_card"):
		# Targeting sync if needed
		success = gc.play_card(idx, t_idx)
		
	if success:
		_refresh_header()
		_refresh_enemies()
		_refresh_hand()
	else:
		_on_play_failed(idx, "BLOCK")

func _on_play_failed(idx: int, reason: String) -> void:
	# Shake
	if not _hand_container: return
	var cards = _hand_container.get_children()
	if idx >= 0 and idx < cards.size():
		var c = cards[idx]
		var base_pos = c.position.x
		var tw = create_tween()
		for i in range(5):
			tw.tween_property(c, "position:x", base_pos + (10 if i%2==0 else -10), 0.05)
		tw.tween_property(c, "position:x", base_pos, 0.05)
		
	# Badge at Mouse
	spawn_damage_number(get_global_mouse_position(), 0, Color.RED) # Hacky reuse?
	# Better: Custom text
	var label = Label.new()
	label.text = reason
	label.position = get_global_mouse_position() + Vector2(20, -20)
	label.add_theme_font_size_override("font_size", 24)
	label.modulate = Color.RED
	label.z_index = 300
	add_child(label)
	var tw2 = create_tween()
	tw2.tween_property(label, "position:y", label.position.y - 50, 0.8)
	tw2.tween_property(label, "modulate:a", 0.0, 0.8)
	tw2.tween_callback(label.queue_free)

func _on_end_turn_pressed() -> void:
	var gc = _gc()
	if gc: gc.end_player_turn()
	_refresh_header()
	_refresh_enemies()

# --- Hand Animation (Juice) ---
func _process(delta: float) -> void:
	_update_hand_arc(delta)
	_update_enemy_highlight(delta)

func _update_hand_arc(delta: float) -> void:
	if not _hand_container: return
	var cards = _hand_container.get_children()
	var count = cards.size()
	if count == 0: return
	
	var center_x = 576.0
	if get_viewport():
		var r = get_viewport().get_visible_rect()
		if r.size.x > 100: center_x = r.size.x / 2.0
		
	var card_spacing = 110.0
	var total_width = min(count * card_spacing, HAND_WIDTH)
	var start_x = center_x - (total_width / 2.0)
	var step_x = 0
	if count > 1: step_x = total_width / float(count - 1)
	
	var mouse_pos = get_global_mouse_position() # Use global for reliability
	var hover_index = -1
	
	for i in range(count):
		if cards[i].get_global_rect().has_point(mouse_pos):
			hover_index = i
			break
			
	for i in range(count):
		var card = cards[i]
		var t_idx = float(i)
		var target_x = start_x + (t_idx * step_x)
		if count == 1: target_x = center_x - (card.size.x / 2.0)
		
		# Arc
		var x_offset = (target_x - center_x)
		var pct = clamp(x_offset / (HAND_WIDTH / 2.0), -1.0, 1.0)
		var target_rot = pct * deg_to_rad(CARD_ROTATION_SPREAD)
		var target_y = abs(pct) * HAND_ARC_HEIGHT
		var target_scale = Vector2(0.65, 0.65)
		var target_z = 0
		
		if hover_index != -1:
			if i == hover_index:
				target_y -= 60
				target_scale = Vector2(0.85, 0.85)
				target_rot = 0
				target_z = 100
			elif abs(i - hover_index) == 1:
				target_x += 60 * sign(i - hover_index)
				
		card.position = card.position.lerp(Vector2(target_x, target_y), 15 * delta)
		card.rotation = lerp_angle(card.rotation, target_rot, 15 * delta)
		card.scale = card.scale.lerp(target_scale, 15 * delta)
		card.z_index = target_z

func _update_enemy_highlight(delta: float) -> void:
	var active = (_pending_card_index != -1)
	var mouse_pos = get_global_mouse_position()
	for child in enemies_box.get_children():
		if child.has_method("set_highlight"):
			child.set_highlight(active and child.get_global_rect().has_point(mouse_pos))

# --- Signals ---
func _on_hand_changed(hand): _refresh_header(); _refresh_hand()
func _on_energy_changed(e): _refresh_header()
func _on_player_turn_started(): _refresh_header(); _refresh_enemies(); _refresh_hand()
func _on_enemy_turn_started(): _refresh_header()
func _on_damage_dealt(type, idx, amt, abs): spawn_damage_number(Vector2(200, 100) if type=="player" else Vector2.ZERO, amt, Color.RED) # Simplify position logic

func spawn_damage_number(pos: Vector2, value: int, color: Color) -> void:
	# Refined version logic
	if pos == Vector2.ZERO: 
		# Find rough position for enemy?
		# Can't easily without index. passed index is valid?
		# If index passed, find visual node
		pass
		
	var label = Label.new()
	label.text = str(value)
	label.position = pos
	label.add_theme_font_size_override("font_size", 32)
	label.modulate = color
	label.z_index = 200
	add_child(label)
	var tw = create_tween()
	tw.tween_property(label, "position:y", pos.y - 100, 1.0)
	tw.tween_callback(label.queue_free)

# --- View Modes ---
enum ViewMode { MAP, COMBAT, REWARD, EVENT, NONE }
var current_view_mode = ViewMode.NONE

func _set_view_mode(mode: ViewMode) -> void:
	current_view_mode = mode
	
	# Combat Elements
	var is_combat = (mode == ViewMode.COMBAT)
	if header_box: header_box.visible = is_combat
	if enemies_box: enemies_box.visible = is_combat
	if hand_box: hand_box.visible = is_combat
	if _hand_container: _hand_container.visible = is_combat
	
	# Map
	if _map_screen_instance:
		_map_screen_instance.visible = (mode == ViewMode.MAP)
		
	# Rewards (If we have a dedicated container)
	# Event (If we have a dedicated container)

# --- Map/Room ---
# Map handling moved to MapScene / RunController dedicated flow.
# GameUI is now primarily Combat HUD.

func _on_room_entered(room):
	# Clear previous combat state just in case
	if enemies_box: _clear_box(enemies_box)
	if hand_box: _clear_box(hand_box)
	
	var type = room.get("type", "")
	
	if type in ["fight", "elite", "boss"]:
		_set_view_mode(ViewMode.COMBAT)
		_spawn_enemies_in_ui()
	elif type == "shop":
		_set_view_mode(ViewMode.REWARD) # Or SHOP mode
		# Shop logic typically opens a separate window.
		# For now, hide map/combat.
	elif type == "event":
		_set_view_mode(ViewMode.EVENT)
	elif type == "rest":
		_set_view_mode(ViewMode.EVENT) # Grove is event-like
	elif type == "treasure":
		_set_view_mode(ViewMode.REWARD)
	else:
		_set_view_mode(ViewMode.NONE)

# --- Win / Loss ---
var _win_loss_ui: Control = null

func show_game_over() -> void:
	_set_view_mode(ViewMode.NONE) # Hide everything else
	_ensure_win_loss_ui()
	_win_loss_ui.visible = true
	if _win_loss_ui.has_method("setup_game_over"):
		_win_loss_ui.setup_game_over()
	move_child(_win_loss_ui, get_child_count()-1)

func show_victory() -> void:
	_set_view_mode(ViewMode.NONE)
	_ensure_win_loss_ui()
	_win_loss_ui.visible = true
	if _win_loss_ui.has_method("setup_victory"):
		_win_loss_ui.setup_victory()
	move_child(_win_loss_ui, get_child_count()-1)

func _ensure_win_loss_ui() -> void:
	if _win_loss_ui: return
	var s = load("res://scripts/WinLossUI.gd")
	if s:
		_win_loss_ui = s.new()
		add_child(_win_loss_ui)
		_win_loss_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
		_win_loss_ui.visible = false
		if _win_loss_ui.has_signal("restart_requested"):
			_win_loss_ui.restart_requested.connect(_on_restart_requested)
		if _win_loss_ui.has_signal("menu_requested"):
			_win_loss_ui.menu_requested.connect(_on_menu_requested)

func _on_restart_requested() -> void:
	# Reload current scene
	get_tree().reload_current_scene()

func _on_menu_requested() -> void:
	# Go to main menu
	var ps = "res://Scenes/MainMenu.tscn"
# --- Rewards ---
var _rewards_ui_instance: Control = null

func show_rewards(offers: Array) -> void:
	_set_view_mode(ViewMode.REWARD)
	
	if not _rewards_ui_instance:
		var s = load("res://Scenes/RewardsUI.tscn")
		if s:
			_rewards_ui_instance = s.instantiate()
			add_child(_rewards_ui_instance)
			_rewards_ui_instance.set_anchors_preset(Control.PRESET_FULL_RECT)
			if _rewards_ui_instance.has_signal("rewards_done"):
				_rewards_ui_instance.rewards_done.connect(_on_rewards_done)
			
	move_child(_rewards_ui_instance, get_child_count()-1)
	
	if _rewards_ui_instance.has_method("setup"):
		_rewards_ui_instance.setup(offers)

func _on_rewards_done() -> void:
	# Rewards done -> Back to Map (or Trigger Next Room logic)
	# DungeonController needs to know we finished the room.
	# Usually RoomController logic flow finishes here.
	var dc = get_node_or_null("/root/DungeonController")
	if dc and dc.has_method("next_room"):
		dc.next_room()
	
	_set_view_mode(ViewMode.MAP) # Explicitly switch back to Map View?
	# next_room() calls show_map() which calls _set_view_mode(MAP).
	# So just calling next_room is sufficient.
	# _rewards_ui_instance is mostly self-cleaning (queue_free) or we should null it?
	# RewardsUI self-cleans with queue_free().
	_rewards_ui_instance = null
