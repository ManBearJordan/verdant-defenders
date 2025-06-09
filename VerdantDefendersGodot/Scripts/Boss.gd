extends Enemy
class_name Boss

signal boss_defeated

var phases := []
var phase := 0
var turn_counter := 0

func _ready():
    _load_phases()

func _load_phases():
    var file = FileAccess.open("res://Data/boss_phases.json", FileAccess.READ)
    if file:
        var data = JSON.parse_string(file.get_as_text())
        if data.has(name):
            phases = data[name]

func _on_turn_start():
    turn_counter += 1
    if phase >= phases.size():
        return
    var current = phases[phase]
    if turn_counter % int(current.turn_interval) == 0:
        run_phase_ability(current.ability)
    if hp <= int(current.threshold_hp):
        _enter_phase(phase + 1)

func run_phase_ability(ability:String):
    print("Boss %s uses %s" % [name, ability])

func _enter_phase(new_phase:int):
    phase = new_phase
    if phase >= phases.size():
        emit_signal("boss_defeated", self)

func next_phase():
    _enter_phase(phase + 1)
