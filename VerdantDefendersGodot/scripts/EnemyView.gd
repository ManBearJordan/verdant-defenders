extends Control
class_name EnemyView

@onready var _name: Label        = %NameLabel
@onready var _hp_bar: ProgressBar = %HPBar
@onready var _hp_label: Label    = %HPLabel
@onready var _intent_icon: TextureRect = %IntentIcon
@onready var _intent_label: Label      = %IntentLabel
@onready var _sprite: TextureRect      = %Sprite
@onready var _highlight: ColorRect     = %Highlight
@onready var _status_container: HBoxContainer = %StatusContainer

# Dynamic UX
var _meter = null
var _passive_row = null
var _intent_badge_label = null # If we add it back

var unit: EnemyUnit = null

const ENEMY_TEX_MAP := {
	"sproutling": "res://Art/characters/sproutling.png",
	"spore_puffer": "res://Art/characters/spore_puffer.png",
	"vine_shooter": "res://Art/characters/vine_shooter.png",
	"bark_shield": "res://Art/characters/bark_shield.png",
	"sap_warden": "res://Art/characters/sap_warden.png",
}

func _ready() -> void:
	if self is Control:
		mouse_filter = Control.MOUSE_FILTER_STOP
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	custom_minimum_size = Vector2(160, 220)

func setup(e: EnemyUnit) -> void:
	unit = e
	
	# Connect Signals
	if not unit.hp_changed.is_connected(_on_hp_changed):
		unit.hp_changed.connect(_on_hp_changed)
	if not unit.intent_updated.is_connected(_on_intent_updated):
		unit.intent_updated.connect(_on_intent_updated)
		
	if not unit.status_changed.is_connected(_on_status_changed):
		unit.status_changed.connect(_on_status_changed)
		
	_name.text = e.display_name
	_update_hp(e.current_hp, e.max_hp)
	_update_intent()
	
	_update_visuals()
	_update_ux_components(e)  # Boss meters etc

func _update_hp(current: int, max_hp: int) -> void:
	if _hp_bar:
		_hp_bar.max_value = max_hp
		_hp_bar.value = current
	if _hp_label:
		_hp_label.text = "%d/%d" % [current, max_hp]

func _on_hp_changed(current: int, max_hp: int) -> void:
	_update_hp(current, max_hp)

func _update_intent() -> void:
	var intent = unit.intent
	if intent.is_empty(): 
		_intent_label.text = ""
		_intent_icon.texture = null
		return
		
	var type = intent.get("type", "unknown")
	var val = int(intent.get("value", 0))
	
	# Icon Resolution
	var icon_path = "res://Art/ui/icon_intent_unknown.png"
	match type:
		"attack": icon_path = "res://Art/ui/icon_intent_attack.png"
		"block": icon_path = "res://Art/cards/icon_block.png" # reuse
		"buff": icon_path = "res://Art/ui/icon_intent_buff.png"
		"debuff": icon_path = "res://Art/ui/icon_intent_debuff.png"
		
	# Fallback if UI icons missing -> use simple color/shape or generic?
	# We'll rely on ArtRegistry or simple placeholders?
	# Reuse provided assets if valid.
	
	if ResourceLoader.exists(icon_path):
		_intent_icon.texture = load(icon_path)
	else:
		_intent_icon.texture = null # Placeholder visual logic?
		
	# Label
	if val > 0:
		_intent_label.text = str(val)
	else:
		_intent_label.text = "" # type icon handles explanation usually

func _on_intent_updated() -> void:
	_update_intent()

func _process(delta: float) -> void:
	if not unit or unit.is_dead(): return
	
	# Poll Statuses (Cheap) - REMOVED, now signal based
	# _update_statuses()
	
	
	# Boss Meters update logic (moved from old code)
	_update_boss_logic()

func _on_status_changed() -> void:
	_update_statuses()

func _update_statuses() -> void:
	if not _status_container: return
	
	for c in _status_container.get_children():
		c.queue_free()
		
	var status_map = {
		"poison": "☠️", "burn": "🔥", "weak": "💔", 
		"vulnerable": "🛡️❌", "shock": "⚡", "chill": "❄️",
		"seeded": "🌱"
	}
	
	for s_name in unit.statuses:
		var val = unit.statuses[s_name]
		if val <= 0: continue
		
		var lbl = Label.new()
		var icon = status_map.get(s_name, "❓")
		lbl.text = "%s %d" % [icon, val]
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.mouse_filter = Control.MOUSE_FILTER_PASS
		lbl.tooltip_text = "%s: %d stacks" % [s_name.capitalize(), val]
		_status_container.add_child(lbl)

func set_highlight(visible_state: bool) -> void:
	if _highlight:
		_highlight.visible = visible_state

# --- Legacy Visuals/UX ---
func _update_visuals() -> void:
	var id = unit.id
	var path = unit.resource.texture_path
	if path == "": 
		path = ENEMY_TEX_MAP.get(id, "res://Art/characters/%s.png" % id)
	var tex = _safe_load_tex(path)
	if tex: _sprite.texture = tex
	else: _sprite.texture = load("res://icon.svg")

func _safe_load_tex(path: String) -> Texture2D:
	if path != "" and ResourceLoader.exists(path):
		return load(path)
	return null

func _update_ux_components(_e: EnemyUnit) -> void:
	# Keep existing logic for boss meters if needed
	pass

func _update_boss_logic() -> void:
	# Keep existing logic
	pass
