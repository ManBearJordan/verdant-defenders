extends Enemy
class_name Boss

signal boss_defeated

var phases := []
var phase := 0
var turn_counter := 0
var boss_abilities := {
	"whip_vines": {"damage": 12, "description": "Lashes with thorned vines"},
	"sacrifice_bloom": {"damage": 8, "effect": "heal", "heal": 10, "description": "Sacrifices minions to heal"},
	"corrosive_smash": {"damage": 15, "effect": "poison", "description": "Poisonous slam attack"},
	"plague_aura": {"damage": 6, "effect": "aoe", "description": "Damages all"},
	"fire_breath": {"damage": 20, "description": "Devastating fire attack"},
	"frost_storm": {"damage": 10, "effect": "freeze", "description": "Freezing storm"},
	"summon_vine_guards": {"effect": "summon", "description": "Calls reinforcements"},
	"natures_reckoning": {"damage": 25, "description": "Ultimate nature attack"},
	"root_blast": {"damage": 18, "description": "Explosive root attack"},
	"sap_storm": {"damage": 12, "effect": "slow", "description": "Slowing sap attack"},
	"worlds_end": {"damage": 30, "description": "Apocalyptic final attack"}
}

func _ready():
    super._ready()  # Call parent _ready
    _load_phases()

func _load_phases():
    var file = FileAccess.open("res://Data/boss_phases.json", FileAccess.READ)
    if file:
        var data = JSON.parse_string(file.get_as_text())
        if data.has(enemy_name):
            phases = data[enemy_name]

func setup(_name:String, data:Dictionary):
    super.setup(_name, data)  # Call parent setup
    # Bosses are much stronger
    max_hp = data.get("max_hp", 100)
    hp = max_hp
    damage = data.get("damage", 15)
    _update_label()

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
    var ability_data = boss_abilities.get(ability, {"damage": 10, "description": "Unknown ability"})
    print("Boss %s uses %s: %s" % [enemy_name, ability, ability_data.description])
    
    # Apply ability effects
    var game_controller = get_tree().get_nodes_in_group("game_controller")[0] if get_tree().get_nodes_in_group("game_controller").size() > 0 else null
    if game_controller and game_controller.has_method("take_damage"):
        var damage_amount = ability_data.get("damage", 0)
        if damage_amount > 0:
            game_controller.take_damage(damage_amount)
    
    # Special effects
    match ability_data.get("effect", ""):
        "heal":
            var heal_amount = ability_data.get("heal", 5)
            hp = min(max_hp, hp + heal_amount)
            print("Boss heals for ", heal_amount)
            _update_label()
        "aoe":
            print("Area of effect damage!")
        "summon":
            print("Boss summons reinforcements!")

func _enter_phase(new_phase:int):
    phase = new_phase
    print("Boss %s enters phase %d!" % [enemy_name, phase])
    if phase >= phases.size():
        print("Boss %s defeated!" % enemy_name)
        emit_signal("boss_defeated", self)

func next_phase():
    _enter_phase(phase + 1)

func _update_label():
    var phase_text = ""
    if phase < phases.size():
        phase_text = " (Phase %d)" % (phase + 1)
    
    var intent_text = ""
    if phases.size() > phase:
        var current_phase = phases[phase]
        var ability = current_phase.ability
        var ability_data = boss_abilities.get(ability, {})
        intent_text = "🔥 " + ability_data.get("description", ability)
    
    label.text = "%s%s\nHP: %d/%d\n%s" % [enemy_name, phase_text, hp, max_hp, intent_text]
