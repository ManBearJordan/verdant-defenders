extends Node2D
class_name RoomController

signal room_cleared

const EnemyScene = preload("res://Scenes/Enemy.tscn")
var enemy_data := {}
var templates := []

func _ready():
    _load_data()

func _load_data():
    var file = FileAccess.open("res://Data/enemy_data.json", FileAccess.READ)
    if file:
        enemy_data = JSON.parse_string(file.get_as_text())
    file = FileAccess.open("res://Data/room_templates.json", FileAccess.READ)
    if file:
        templates = JSON.parse_string(file.get_as_text())

func spawn_room(index:int):
    var template = templates[index % templates.size()]
    var container = $EnemyContainer
    for c in container.get_children():
        c.queue_free()
    if template.type != "combat":
        emit_signal("room_cleared")
        return
    for entry in template.enemies:
        for i in range(entry.count):
            var name = enemy_data.keys()[0]
            var e = EnemyScene.instantiate()
            e.setup(name, enemy_data[name])
            container.add_child(e)
            e.connect("enemy_died", Callable(self, "_on_enemy_died"))

func _on_enemy_died(enemy):
    if $EnemyContainer.get_child_count() == 0:
        emit_signal("room_cleared")
