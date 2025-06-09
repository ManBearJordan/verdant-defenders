extends Resource
class_name Card

# Data structure for a single card
@export var name: String
@export var description: String
@export var type: String      # "Strike", "Tactic", or "Ritual"
@export var cost: int
@export var power: int        # Generic power value you can use in effects

func _init(_name: String = "", _desc: String = "", _type: String = "", _cost: int = 0, _power: int = 0):
    name = _name
    description = _desc
    type = _type
    cost = _cost
    power = _power

func play():
    # Placeholder: apply the card’s effect
    print("Played card:", name, "Type:", type, "Cost:", cost, "Power:", power)
