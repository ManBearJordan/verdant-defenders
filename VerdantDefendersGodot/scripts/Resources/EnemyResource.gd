extends Resource
class_name EnemyResource

@export_group("Identity")
@export var id: String = ""
@export var display_name: String = ""
@export var texture_path: String = "" 

@export_group("Stats")
@export var max_hp: int = 20
@export var defense: int = 0
# Metadata for spawning
@export var tier: String = "normal" # normal, elite, boss
@export var pool: String = "core"   # growth, decay, elemental
@export var archetype_counter: String = ""

@export_group("AI")
@export var intents: Array[String] = [] # "Attack 5", "Block 5", etc.
@export var special_ability: String = "" # Descriptive text for UI

# Logic hooks could be script-based later, for now storage driven
@export var logic_meta: Dictionary = {}
