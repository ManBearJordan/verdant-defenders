class_name EnemyUnit

var resource: EnemyResource
signal hp_changed(current: int, max: int)
signal intent_updated()
signal status_changed()

var id: String = ""
var display_name: String = ""
var current_hp: int = 0:
	set(value):
		current_hp = value
		hp_changed.emit(current_hp, max_hp)

var max_hp: int = 0
var block: int = 0
var intent: Dictionary = {}
var statuses: Dictionary = {}
var status_metadata: Dictionary = {}

# Boss / Phase Logic
var archetype_counter: String = ""
var hits_taken_this_turn: int = 0
var damage_scale: float = 1.0 # Act/Depth Scaling
var ascension_damage_scale: float = 1.0 # Ascension Scaling
var phases: Array = []
var phase_index: int = 0
var modifiers: Array[Dictionary] = [] # [{id, name, desc}]
var is_elite: bool = false

var custom_data: Dictionary = {}

func _init(res: Resource):
	resource = res
	id = res.id
	display_name = res.display_name
	
	current_hp = res.max_hp
	max_hp = res.max_hp
	# block = res.defense -- This line was removed based on the provided snippet
	
	if res.intents.size() > 0:
		intent = {"type": "attack", "value": 0} # Default
	archetype_counter = res.archetype_counter
	
	# Initial intent is empty, must be computed by AI
	# The above conditional assignment for intent might override this,
	# but keeping it as per the user's provided snippet structure.
	# If the intent should always be empty initially, the conditional assignment should be removed.
	# For now, following the snippet exactly.
	intent = {}
	statuses = {}

func apply_scaling(mult: float) -> void:
	damage_scale = mult
	max_hp = int(round(max_hp * mult))
	current_hp = max_hp
	print("EnemyUnit: Applied Scaling x%.2f -> HP: %d" % [mult, max_hp])

func apply_ascension_scaling(hp_mult: float, dmg_mult: float) -> void:
	ascension_damage_scale = dmg_mult
	max_hp = int(round(max_hp * hp_mult))
	current_hp = max_hp # Re-heal or just adj cap? Usually start combat full.
	print("EnemyUnit: Ascension x%.2f HP / x%.2f Dmg" % [hp_mult, dmg_mult])

func get_status(key: String) -> int:
	return int(statuses.get(key, 0))

func set_status(key: String, val: int) -> void:
	statuses[key] = val

func is_dead() -> bool:
	return current_hp <= 0

func update_intent(turn: int) -> void:
	if resource.intents.is_empty():
		# Fallback AI
		intent = {"type": "attack", "value": 5}
		return
		
	# Cycle intents
	var idx = (turn) % resource.intents.size()
	var raw = resource.intents[idx]
	intent = _parse_intent(raw)
	intent_updated.emit()

func _parse_intent(raw: String) -> Dictionary:
	# Format examples: "Attack 6", "Block 5", "Buff (+2 Block)", "Debuff (2 Poison)"
	# Simple regex-like parsing
	var parts = raw.split(" ")
	var type = parts[0].to_lower()
	var val = 0
	if parts.size() > 1:
		val = parts[1].to_int()
		

		
	# Apply Scaling if Attack
	if type == "attack" and val > 0:
		var total_mult = damage_scale * ascension_damage_scale
		val = int(round(val * total_mult))

	var dict = {"type": type, "value": val, "name": raw}
	
	if type == "buff" or type == "debuff":
		# Keep raw name for UI
		pass
		
	return dict
