extends Node2D
class_name Enemy

@onready var health_label: Label = $HealthLabel
@onready var intent_label: Label = $IntentLabel
@onready var intent_node: Node = $EnemyIntent

var enemy_name := "Enemy"
var max_hp := 30
var hp := 30
var block := 0
var intent := {"type":"attack","value":6}
var statuses := {}

# Optional: if your project has a StatusHandler autoload, we'll use it.
var status_handler: Node = null

func _ready() -> void:
	# Try to locate a StatusHandler autoload if it exists.
	if status_handler == null:
		status_handler = get_tree().root.get_node_or_null("StatusHandler")
	_update_ui()

func setup(enemy_data: Dictionary) -> void:
	# Normalize enemy to dict format: {name, max_hp, hp, block, statuses, intent}
	enemy_name = String(enemy_data.get("name", "Enemy"))
	max_hp = int(enemy_data.get("max_hp", enemy_data.get("hp", 30)))
	hp = int(enemy_data.get("hp", max_hp))
	block = int(enemy_data.get("block", 0))
	
	# Initialize statuses
	if enemy_data.has("statuses") and enemy_data["statuses"] is Dictionary:
		statuses = enemy_data["statuses"].duplicate()
	else:
		statuses = {}
	
	# Set up intent from enemy data
	if enemy_data.has("intent"):
		intent = enemy_data["intent"].duplicate()
	else:
		# Default intent
		intent = {"type": "attack", "value": 6}
	
	_update_ui()

func get_enemy_dict() -> Dictionary:
	"""Return normalized enemy dict"""
	return {
		"name": enemy_name,
		"max_hp": max_hp,
		"hp": hp,
		"block": block,
		"statuses": statuses.duplicate(),
		"intent": intent.duplicate()
	}

func set_intent(new_intent: Dictionary) -> void:
	intent = new_intent.duplicate()
	_update_ui()

func get_current_hp() -> int:
	return hp

func take_damage(amount: int) -> void:
	var remaining: int = amount
	if block > 0:
		var absorbed: int = min(block, remaining)
		block -= absorbed
		remaining -= absorbed
	if remaining > 0:
		hp = max(0, hp - remaining)
	_update_ui()
	if hp == 0:
		_die()

func add_block(amount: int) -> void:
	block += max(0, amount)
	_update_ui()

func apply_status(status_name: String, amount: int) -> void:
	var current: int = int(statuses.get(status_name, 0))
	statuses[status_name] = current + amount
	print("Enemy %s: Applied %d %s (total: %d)" % [enemy_name, amount, status_name, statuses[status_name]])

func apply_status_effects() -> void:
	var sh := status_handler
	if sh == null:
		sh = get_tree().root.get_node_or_null("StatusHandler")
	if sh and sh.has_method("tick_start_of_turn"):
		sh.call("tick_start_of_turn")

func _update_ui() -> void:
	if health_label:
		health_label.text = "%s %d/%d" % [enemy_name, hp, max_hp]
		if block > 0:
			health_label.text += " [%d]" % block
	
	if intent_label:
		intent_label.text = _intent_to_text(intent)

func _intent_to_text(i: Dictionary) -> String:
	if i.is_empty():
		return "Intent: None"
	
	var intent_type := String(i.get("type", ""))
	var intent_value := int(i.get("value", 0))
	
	match intent_type:
		"attack":
			return "Intent: Attack %d" % intent_value
		"defend":
			return "Intent: Defend %d" % intent_value
		_:
			return "Intent: %s" % intent_type

func execute_intent() -> void:
	"""Execute this enemy's current intent"""
	if intent.is_empty():
		return
	
	var intent_type: String = String(intent.get("type", ""))
	var intent_value: int = int(intent.get("value", 0))
	
	match intent_type:
		"attack":
			_execute_attack_intent(intent_value)
		"defend":
			_execute_defend_intent(intent_value)
		_:
			print("Unknown intent type: %s" % intent_type)
	
	# Roll new intent for next turn (alternate attack/defend)
	_roll_new_intent()

func _execute_attack_intent(damage: int) -> void:
	"""Execute an attack intent - damage the player (respects player block)"""
	var cs: Node = get_node_or_null("/root/CombatSystem")
	
	if cs == null:
		print("CombatSystem not found, cannot execute attack")
		return
	
	# Use CombatSystem to damage player (respects player block)
	if cs.has_method("damage_player"):
		cs.call("damage_player", damage)
		print("Enemy %s attacks for %d damage" % [enemy_name, damage])
	else:
		print("CombatSystem missing damage_player method")

func _execute_defend_intent(block_amount: int) -> void:
	"""Execute a defend intent - gain block"""
	add_block(block_amount)
	print("Enemy %s gains %d block" % [enemy_name, block_amount])

func _roll_new_intent() -> void:
	"""Roll a new intent for next turn - alternates between attack and defend"""
	var current_type: String = String(intent.get("type", "attack"))
	
	if current_type == "attack":
		# Switch to defend
		intent = {"type": "defend", "value": 5}
	else:
		# Switch to attack
		intent = {"type": "attack", "value": 6}
	
	_update_ui()

func _die() -> void:
	# Remove from combat system's enemy list
	var cs: Node = get_node_or_null("/root/CombatSystem")
	if cs and cs.has_method("remove_enemy"):
		cs.call("remove_enemy", self)
	
	queue_free()

func _on_clicked() -> void:
	"""Called when this enemy is clicked - sets as target"""
	var ts := get_tree().root.get_node_or_null("TargetingSystem")
	if ts and ts.has_method("set_target"):
		ts.call("set_target", self)

func _input_event(_vp: Viewport, event: InputEvent, _shape: int) -> void:
	# Handle mouse clicks on this enemy per task requirements
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var targeting_system: Node = get_node_or_null("/root/TargetingSystem")
		if targeting_system != null and targeting_system.has_method("set_target"):
			targeting_system.call("set_target", self)
