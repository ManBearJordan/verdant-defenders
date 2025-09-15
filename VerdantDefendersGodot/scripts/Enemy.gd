extends Node2D
class_name Enemy

signal enemy_died(enemy)

var name : String
var max_hp : int
var hp : int
var damage : int

@onready var label = $Label

func setup(_name:String, data:Dictionary):
    name = _name
    max_hp = data.get("max_hp", 10)
    hp = max_hp
    damage = data.get("damage", 0)
    _update_label()

func apply_damage(amount:int):
    hp -= amount
    if hp <= 0:
        hp = 0
        _update_label()
        emit_signal("enemy_died", self)
        queue_free()
    else:
        _update_label()

func _update_label():
    label.text = "%s\nHP: %d" % [name, hp]
