extends Resource
class_name RoomCard

@export var type: String = "COMBAT" # COMBAT, SHOP, EVENT, TREASURE, ELITE, BOSS
@export var title: String = "Encounter"
@export var description: String = ""
@export var icon_path: String = ""
@export var difficulty: int = 1
@export var metadata: Dictionary = {}

func _init(p_type="COMBAT", p_title="Encounter"):
	type = p_type
	title = p_title
