extends Node
class_name CardData

var name : String
var type : String
var cost : int
var effect : String
var damage : int
var block : int

func _init(_name:String, _type:String, _cost:int, _effect:String, _damage:int=0, _block:int=0):
    name = _name
    type = _type
    cost = _cost
    effect = _effect
    damage = _damage
    block = _block
