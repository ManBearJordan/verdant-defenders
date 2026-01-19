extends HBoxContainer
class_name Enemy

@onready var sprite: TextureRect = get_node_or_null("Sprite")
@onready var name_label: Label = get_node_or_null("Info/NameLabel")
@onready var health_label: Label = get_node_or_null("Info/HealthLabel")
@onready var intent_label: Label = get_node_or_null("Info/IntentLabel")

var enemy_name := "Enemy"
var max_hp := 30
var hp := 30
var block := 0
var intent := {"type":"attack","value":6}
var statuses := {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = CURSOR_POINTING_HAND
	_update_ui()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		TargetingSystem.set_target(self)

func set_highlight(on: bool) -> void:
	if on:
		modulate = Color(1, 1, 1, 1)
		if name_label: name_label.add_theme_color_override("font_color", Color(0.95, 1.0, 0.4))
	else:
		modulate = Color(0.88, 0.88, 0.88, 1)
		if name_label: name_label.remove_theme_color_override("font_color")

func setup(enemy_data: Dictionary) -> void:
	enemy_name = String(enemy_data.get("name", "Enemy"))
	max_hp = int(enemy_data.get("max_hp", enemy_data.get("hp", 30)))
	hp = int(enemy_data.get("hp", max_hp))
	block = int(enemy_data.get("block", 0))
	statuses = enemy_data.get("statuses", {}) if enemy_data.get("statuses", {}) is Dictionary else {}
	intent = enemy_data.get("intent", {"type":"attack","value":6}).duplicate()
	_update_ui()

func get_current_hp() -> int:
	return hp

func take_damage(amount: int) -> void:
	var rem: int = amount
	if block > 0:
		var absorbed: int = min(block, rem)
		block -= absorbed
		rem -= absorbed
	if rem > 0:
		hp = max(0, hp - rem)
	_update_ui()
	if hp == 0:
		queue_free()

func add_block(amount: int) -> void:
	block += max(0, amount)
	_update_ui()

func set_intent(new_intent: Dictionary) -> void:
	intent = new_intent.duplicate()
	_update_ui()

func execute_intent() -> void:
	var t := String(intent.get("type",""))
	var v := int(intent.get("value",0))
	match t:
		"attack":
			var cs := get_node_or_null("/root/CombatSystem")
			if cs and cs.has_method("damage_player"):
				cs.call("damage_player", v)
		"defend":
			add_block(v)
	# Alternate A/D for the next turn
	if t == "attack":
		intent = {"type":"defend","value":5}
	else:
		intent = {"type":"attack","value":6}
	_update_ui()

func _update_ui() -> void:
	if name_label:
		name_label.text = enemy_name
	if health_label:
		var block_text = ""
		if block > 0:
			block_text = " [%d]" % block
		health_label.text = "HP %d/%d%s" % [hp, max_hp, block_text]
	if intent_label:
		var t := String(intent.get("type",""))
		var v := int(intent.get("value",0))
		match t:
			"attack":
				intent_label.text = "(Attack %d)" % v
			"defend":
				intent_label.text = "(Defend %d)" % v
			_:
				intent_label.text = "(%s)" % t
