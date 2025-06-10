extends Node
class_name DataLoader

# Singleton responsible for loading and validating static game data.

var cards : Array = []
var enemies : Dictionary = {}
var boss_phases : Dictionary = {}
var dungeon : Dictionary = {}
var room_templates : Array = []
var events : Array = []
var shop_data : Dictionary = {}
var relics : Array = []

func _ready():
    _load_all()

# Load all data files in the Data directory.
func _load_all():
    cards = _load_array("res://Data/cards.json", ["id", "name", "type", "cost"])
    enemies = _load_dict("res://Data/enemy_data.json")
    boss_phases = _load_dict("res://Data/boss_phases.json")
    dungeon = _load_dict("res://Data/dungeon.json", ["layers"])
    room_templates = _load_array("res://Data/room_templates.json")
    events = _load_array("res://Data/event_data.json")
    shop_data = _load_dict("res://Data/shop_data.json")
    relics = _load_array("res://Data/relic_data.json")

# Helper to load a JSON file and return the parsed data.
func _load_json(path:String) -> Variant:
    var file = FileAccess.open(path, FileAccess.READ)
    if file == null:
        printerr("Missing data file: %s" % path)
        push_error("Missing data file: %s" % path)
        return null
    var text = file.get_as_text()
    var json = JSON.new()
    var err = json.parse(text)
    if err != OK:
        printerr("Failed to parse %s: %s" % [path, json.error_string])
        push_error("Failed to parse %s" % path)
        return null
    return json.data

# Load a JSON file expected to contain an Array.
func _load_array(path:String, required_fields:Array = []) -> Array:
    var data = _load_json(path)
    if data == null:
        return []
    if typeof(data) != TYPE_ARRAY:
        printerr("%s root must be an Array" % path)
        push_error("Malformed data: %s" % path)
        return []
    if required_fields.size() > 0:
        for entry in data:
            if typeof(entry) != TYPE_DICTIONARY:
                printerr("Entry in %s is not a Dictionary" % path)
                push_error("Malformed entry in %s" % path)
                continue
            for f in required_fields:
                if not entry.has(f):
                    printerr("%s missing field %s" % [path, f])
                    push_error("%s missing field %s" % [path, f])
    return data

# Load a JSON file expected to contain a Dictionary.
func _load_dict(path:String, required_fields:Array = []) -> Dictionary:
    var data = _load_json(path)
    if data == null:
        return {}
    if typeof(data) != TYPE_DICTIONARY:
        printerr("%s root must be a Dictionary" % path)
        push_error("Malformed data: %s" % path)
        return {}
    for f in required_fields:
        if not data.has(f):
            printerr("%s missing field %s" % [path, f])
            push_error("%s missing field %s" % [path, f])
    return data

# --- Getter methods -------------------------------------------------------

func get_cards() -> Array:
    return cards

func get_enemies() -> Dictionary:
    return enemies

func get_boss_phases() -> Dictionary:
    return boss_phases

func get_dungeon() -> Dictionary:
    return dungeon

func get_room_templates() -> Array:
    return room_templates

func get_events() -> Array:
    return events

func get_shop_data() -> Dictionary:
    return shop_data

func get_relics() -> Array:
    return relics
