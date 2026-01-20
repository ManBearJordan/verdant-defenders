extends Resource
class_name CardResource

@export_group("Identity")
@export var id: String = ""
@export var display_name: String = ""
@export var art_id: String = ""

@export_group("Gameplay")
@export var type: String = "Strike" # Strike, Skill, Power, Tactic
@export var cost: int = 1
@export var damage: int = 0
@export var block: int = 0
@export var effect_text: String = ""

@export_group("Meta")
@export var rarity: String = "common" # common, uncommon, rare
@export var pool: String = "growth"   # growth, decay, elemental
@export var tags: Array[String] = []
@export var upgrade_id: String = "" # ID of the upgraded version (e.g. "strike_plus")

# Optional: properties for logic not covered by standard damage/block
@export var logic_meta: Dictionary = {} 
