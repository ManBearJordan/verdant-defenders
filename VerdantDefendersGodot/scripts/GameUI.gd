extends Control

# Card view prefab (your existing CardView.tscn)
const CARD_SCENE: PackedScene = preload("res://Scenes/CardView.tscn")

@onready var root_vbox: VBoxContainer   = get_node_or_null("RootVBox") as VBoxContainer
@onready var header_box: HBoxContainer  = get_node_or_null("RootVBox/Header") as HBoxContainer
@onready var enemies_box: VBoxContainer = get_node_or_null("RootVBox/Enemies") as VBoxContainer
@onready var hand_box: HBoxContainer    = _find_hand_box()

# Background texture for the combat scene.  Assigned via set_background().
@onready var _background: TextureRect = get_node_or_null("Background") as TextureRect

# Room deck UI elements
var room_choices_container: HBoxContainer = null

var _last_hand: Array[Dictionary] = []
var _pending_card_index: int = -1

## Helper to locate the Hand HBoxContainer even if it is nested in a
## ScrollContainer.  It searches for a node named "Hand" under RootVBox.
func _find_hand_box() -> HBoxContainer:
	var root := get_node_or_null("RootVBox") as Node
	if root:
		# direct child
		var hbox := root.get_node_or_null("Hand")
		if hbox:
			return hbox as HBoxContainer
		# check for a ScrollContainer wrapper named HandScroll
		var sc := root.get_node_or_null("HandScroll")
		if sc and sc.has_node("Hand"):
			return sc.get_node("Hand") as HBoxContainer
	return null


# ========================================================================
# Lifecycle
# ========================================================================

func _ready() -> void:
	_ensure_layout()
	_refresh_header()
	_refresh_enemies()
	_refresh_hand()

	# Connect to DeckManager signals if available.  When the deck or energy
	# changes, update the header and hand display accordingly.
	var dm := _dm()
	if dm != null:
		if dm.has_signal("hand_changed"):
			dm.hand_changed.connect(Callable(self, "_on_hand_changed"))
		if dm.has_signal("energy_changed"):
			dm.energy_changed.connect(Callable(self, "_on_energy_changed"))

	# Connect to GameController signals for turn management
	var gc := _gc()
	if gc != null:
		if gc.has_signal("player_turn_started"):
			gc.player_turn_started.connect(Callable(self, "_on_player_turn_started"))
		if gc.has_signal("enemy_turn_started"):
			gc.enemy_turn_started.connect(Callable(self, "_on_enemy_turn_started"))


# ========================================================================
# Autoload helpers (robust for typed GDScript)
# ========================================================================

func _dm() -> Node:
	# DeckManager autoload if present
	if typeof(DeckManager) != TYPE_NIL:
		return DeckManager
	return null

func _cs() -> Node:
	# CombatSystem autoload if present
	if typeof(CombatSystem) != TYPE_NIL:
		return CombatSystem
	return null

func _gc() -> Node:
	# GameController autoload if present
	if typeof(GameController) != TYPE_NIL:
		return GameController
	return null


# ========================================================================
# Data access (typed, no warnings-as-errors)
# ========================================================================

func _get_enemies() -> Array[Dictionary]:
	var cs := _cs()
	if cs and cs.has_method("get_enemies"):
		var raw: Array = cs.call("get_enemies") as Array
		var out: Array[Dictionary] = []
		for v in raw:
			if v is Dictionary:
				out.append(v as Dictionary)
		return out
	return []

func _get_hand_cards() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var dm := _dm()
	if dm == null:
		return out

	# Prefer a method, fall back to a public array property if exposed
	var raw: Array = []
	if dm.has_method("get_hand"):
		raw = dm.call("get_hand") as Array
	else:
		var h = dm.get("hand")
		if h is Array:
			raw = h

	for v in raw:
		if v is Dictionary:
			out.append(v as Dictionary)
	return out


# ========================================================================
# UI refresh
# ========================================================================

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
		# Fan out cards slightly by overlapping them.  A negative separation causes
		# each card to overlap the previous one, giving a more compact hand.
		# Only apply if supported by theme overrides.
		hand_box.add_theme_constant_override("separation", -60)
		# Center the cards within the hand container.  Alignment 1 corresponds to
		# BoxContainer.ALIGNMENT_CENTER.
		hand_box.alignment = 1

func _clear_box(b: Node) -> void:
	if b == null:
		return
	for c in b.get_children():
		(c as Node).queue_free()

func _refresh_header() -> void:
	if header_box == null:
		return
	_clear_box(header_box)

	var dm := _dm()
	var gc := _gc()
	var energy_now := 0
	var hand_size := 0
	var current_turn := 0
	var is_player_turn := true
	
	if dm:
		var e = dm.get("energy")
		if typeof(e) == TYPE_INT:
			energy_now = int(e)
		var h = dm.get("hand")
		if h is Array:
			hand_size = (h as Array).size()
	
	if gc:
		if gc.has_method("get_current_turn"):
			current_turn = int(gc.call("get_current_turn"))
		if gc.has_method("is_current_player_turn"):
			is_player_turn = bool(gc.call("is_current_player_turn"))

	# Turn and game state info
	var turn_info := Label.new()
	var turn_phase := "Player Turn" if is_player_turn else "Enemy Turn"
	turn_info.text = "Turn %d - %s" % [current_turn, turn_phase]
	header_box.add_child(turn_info)
	
	# Add spacer
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_box.add_child(spacer)

	# Cards and energy info
	var info := Label.new()
	info.text = "Cards: %d   Energy: %d" % [hand_size, energy_now]
	header_box.add_child(info)
	
	# End Turn button (only show during player turn)
	if is_player_turn:
		var end_turn_btn := Button.new()
		end_turn_btn.text = "End Turn"
		end_turn_btn.custom_minimum_size.x = 80.0
		end_turn_btn.pressed.connect(Callable(self, "_on_end_turn_pressed"))
		header_box.add_child(end_turn_btn)

## Set the background texture for the combat scene.  Provide just the base
## filename without extension (e.g. "growth_combat").  The image is
## loaded via ArtRegistry.
func set_background(name: String) -> void:
	if _background == null:
		return
	
	# Try to get texture via ArtRegistry first
	var art_registry: Node = get_node_or_null("/root/ArtRegistry")
	if art_registry != null and art_registry.has_method("get_texture"):
		var texture = art_registry.call("get_texture", name)
		if texture != null:
			_background.texture = texture
			return
	
	# Fallback to direct loading
	var path: String = "res://Art/backgrounds/%s.png" % name
	if ResourceLoader.exists(path):
		_background.texture = load(path)
	else:
		_background.texture = null

func _intent_text(e: Dictionary) -> String:
	var i: Dictionary = e.get("intent", {}) as Dictionary
	var t := String(i.get("type", ""))
	var v := int(i.get("value", 0))
	if t == "attack":
		return "(Attack %d)" % v
	elif t == "defend":
		return "(Defend %d)" % v
	elif t != "":
		return "(%s %d)" % [t.capitalize(), v]
	return ""

func _refresh_enemies() -> void:
	if enemies_box == null:
		return
	_clear_box(enemies_box)

	var list: Array[Dictionary] = _get_enemies()
	for i in range(list.size()):
		var e: Dictionary = list[i] as Dictionary
		# Create a button for each enemy; this will display an icon and text.  Use
		# size flags to make it expand horizontally.
		var btn := Button.new()
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size.y = 40.0
		# Compute HP and intent text
		var hp: int = int(e.get("hp", 0))
		var name := String(e.get("name", "Enemy %d" % i))
		var extra := _intent_text(e)
		# Attempt to load an icon for the enemy based on its name.  Create a slug
		# by lowercasing and replacing spaces and hyphens with underscores.
		var slug: String = name.strip_edges().to_lower().replace(" ", "_").replace("-", "_")
		var icon_paths: Array[String] = [
			"res://Art/%s.png" % slug,
			"res://Art/enemies/%s.png" % slug,
			"res://Art/characters/%s.png" % slug
		]
		var tex: Texture2D = null
		for path in icon_paths:
			if ResourceLoader.exists(path):
				tex = load(path)
				break
		# If no texture found by direct slug, search the directories for a file that
		# contains the slug as a substring.  This allows matching art even when
		# the file names have prefixes or suffixes.  Search in common art folders.
		if tex == null:
			var search_dirs: Array[String] = ["res://Art/characters", "res://Art/enemies", "res://Art"]
			for dir_path in search_dirs:
				var dir := DirAccess.open(dir_path)
				if dir != null:
					dir.list_dir_begin()
					var fname: String = dir.get_next()
					while fname != "":
						if not dir.current_is_dir():
							var lower := fname.to_lower()
							if lower.contains(slug):
								var cand_path := "%s/%s" % [dir_path, fname]
								if ResourceLoader.exists(cand_path):
									tex = load(cand_path)
									break
						if tex != null:
							break
						fname = dir.get_next()
					dir.list_dir_end()
				if tex != null:
					break
		# Assign the icon to the button if found
		if tex != null:
			btn.icon = tex
		# Set the button text to include name, HP, and intent
		btn.text = "%s   HP %d  %s" % [name, hp, extra]
		# Add to container and connect click to target selection
		enemies_box.add_child(btn)
		btn.pressed.connect(Callable(self, "_on_target_chosen").bind(i))

func _refresh_hand() -> void:
	if hand_box == null:
		return
	_clear_box(hand_box)

	var cards: Array[Dictionary] = _get_hand_cards()
	_last_hand = cards.duplicate()

	for i in range(cards.size()):
		var c: Dictionary = cards[i] as Dictionary

		var inst: Node = null
		if CARD_SCENE:
			inst = CARD_SCENE.instantiate()
			if inst.has_method("setup"):
				inst.call("setup", c, i)  # CardView optional API
		else:
			# Fallback: create a button displaying the card name and cost
			var fb: Button = Button.new()
			var nm: String = String(c.get("name", "Card"))
			var cost: int = 0
			var cost_v: Variant = c.get("cost", 0)
			if typeof(cost_v) == TYPE_INT:
				cost = int(cost_v)
			fb.text = "%s (%d)" % [nm, cost]
			inst = fb

		hand_box.add_child(inst)

		# Connect the click:
		var callback: Callable = Callable(self, "_on_card_pressed").bind(i)
		if inst is BaseButton:
			(inst as BaseButton).pressed.connect(callback)
		else:
			var catcher: BaseButton = inst.get_node_or_null("ClickCatcher") as BaseButton
			if catcher:
				catcher.pressed.connect(callback)


# ========================================================================
# Interaction
# ========================================================================

func _on_card_pressed(card_index: int) -> void:
	if card_index < 0 or card_index >= _last_hand.size():
		return
	var card: Dictionary = _last_hand[card_index] as Dictionary
	var needs_target := bool(card.get("needs_target", false))

	if needs_target:
		_pending_card_index = card_index
		_highlight_target_mode(true)
	else:
		_play_card(card_index, card, -1)

func _on_target_chosen(target_index: int) -> void:
	if _pending_card_index >= 0:
		var card: Dictionary = _last_hand[_pending_card_index] as Dictionary
		_play_card(_pending_card_index, card, target_index)
		_pending_card_index = -1
		_highlight_target_mode(false)

func _play_card(idx: int, card: Dictionary, target_index: int) -> void:
	var cs := _cs()
	if cs and cs.has_method("play_card"):
		cs.call("play_card", idx, card, target_index)

	# Refresh UI after any play attempt
	_refresh_header()
	_refresh_enemies()
	_refresh_hand()

func _on_end_turn_pressed() -> void:
	var gc := _gc()
	if gc and gc.has_method("end_player_turn"):
		gc.call("end_player_turn")
	
	# Refresh UI to reflect turn change
	_refresh_header()
	_refresh_enemies()

func _highlight_target_mode(active: bool) -> void:
	if active:
		print("Select a target…")
	else:
		print("Target mode off")

# ========================================================================
# Signal handlers
# ========================================================================

func _on_hand_changed(new_hand: Array[Dictionary]) -> void:
	# Called when the DeckManager emits hand_changed.  Update the stored
	# reference to the hand and refresh the header and hand display.  The
	# enemies display is not updated here because enemy intent does not
	# change when the hand changes.
	_last_hand = []
	for v in new_hand:
		if v is Dictionary:
			_last_hand.append((v as Dictionary))
	_refresh_header()
	_refresh_hand()

func _on_energy_changed(_current: int) -> void:
	# Called when the DeckManager emits energy_changed.  Refresh the header
	# to reflect the new energy value.  The hand is not refreshed here because
	# the hand contents do not change when energy changes.
	_refresh_header()

func _on_player_turn_started() -> void:
	# Called when GameController starts a player turn
	_refresh_header()
	_refresh_enemies()
	_refresh_hand()

func _on_enemy_turn_started() -> void:
	# Called when GameController starts an enemy turn
	_refresh_header()
