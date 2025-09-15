extends Node2D
class_name Enemy

signal enemy_died(enemy)

var enemy_name : String
var max_hp : int
var hp : int
var damage : int
var intent : String = "attack"  # What the enemy plans to do next turn
var block : int = 0

@onready var label = $Label

func setup(_name:String, data:Dictionary):
    enemy_name = _name
    max_hp = data.get("max_hp", 10)
    hp = max_hp
    damage = data.get("damage", 0)
    _update_label()
    _choose_intent()

func apply_damage(amount:int):
    var actual_damage = max(0, amount - block)
    hp -= actual_damage
    block = max(0, block - amount)  # Block absorbs damage
    print(enemy_name, " takes ", actual_damage, " damage")
    
    if hp <= 0:
        hp = 0
        _update_label()
        emit_signal("enemy_died", self)
        print(enemy_name, " defeated!")
        queue_free()
    else:
        _update_label()

func _update_label():
    var intent_text = ""
    match intent:
        "attack":
            intent_text = "⚔️ " + str(damage)
        "defend":
            intent_text = "🛡️ Block"
        "buff":
            intent_text = "✨ Buff"
    
    label.text = "%s\nHP: %d/%d\n%s" % [enemy_name, hp, max_hp, intent_text]

func _choose_intent():
    # Simple AI: mostly attack, sometimes defend
    var rand = randf()
    if rand < 0.8:
        intent = "attack"
    elif rand < 0.95:
        intent = "defend"
    else:
        intent = "buff"
    _update_label()

func take_turn():
    match intent:
        "attack":
            _attack_player()
        "defend":
            _defend()
        "buff":
            _buff_self()
    _choose_intent()  # Choose next turn's intent

func _attack_player():
    print(enemy_name, " attacks for ", damage, " damage!")
    # Get the game controller to apply damage to player
    var game_controller = get_tree().get_nodes_in_group("game_controller")[0] if get_tree().get_nodes_in_group("game_controller").size() > 0 else null
    if game_controller and game_controller.has_method("take_damage"):
        game_controller.take_damage(damage)

func _defend():
    block += 5
    print(enemy_name, " gains 5 block")
    _update_label()

func _buff_self():
    damage += 1
    print(enemy_name, " gains 1 damage permanently")
    _update_label()
