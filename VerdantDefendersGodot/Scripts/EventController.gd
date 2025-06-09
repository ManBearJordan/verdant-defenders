extends Control
class_name EventController

var events := []
signal choice_selected(effect)

func _ready():
    randomize()
    var file = FileAccess.open("res://Data/event_data.json", FileAccess.READ)
    if file:
        events = JSON.parse_string(file.get_as_text())
    _show_random_event()

func _show_random_event():
    if events.size() == 0:
        return
    var entry = events[randi() % events.size()]
    $Description.text = entry.text
    for c in entry.choices:
        var b = Button.new()
        b.text = c.text
        $ChoiceContainer.add_child(b)
        b.connect("pressed", Callable(self, "_on_choice").bind(c.effect))

func _on_choice(effect:String):
    emit_signal("choice_selected", effect)
