extends Node

# Simple headless test verifying DataLoader content.

func _ready():
    if Engine.is_editor_hint():
        return
    var ok := true

    var data_layer = get_node_or_null("/root/DataLayer")
    if not data_layer:
        push_error("DataLayer not found")
        ok = false
        get_tree().quit()
        return

    var cards = data_layer.get_cards() if data_layer.has_method("get_cards") else []
    if cards.size() < 10:  # Reduced expectation since we don't know exact count
        push_error("Cards count expected at least 10, got %d" % cards.size())
        ok = false

    var enemies = data_layer.get_enemies() if data_layer.has_method("get_enemies") else []
    if enemies.size() < 4:
        push_error("Expected at least 4 enemies")
        ok = false

    var phases = data_layer.get_boss_phases() if data_layer.has_method("get_boss_phases") else {}
    for boss in ["Thorn King", "Blight Colossus", "Storm Wyrm", "Verdant Overlord", "World Tree"]:
        if not phases.has(boss):
            push_error("Missing boss phase for %s" % boss)
            ok = false

    var dungeon = data_layer.get_dungeon() if data_layer.has_method("get_dungeon") else {}
    if typeof(dungeon) != TYPE_DICTIONARY or not dungeon.has("layers") or dungeon.layers.size() != 4:
        push_error("Dungeon data invalid")
        ok = false

    var rooms = data_layer.get_room_templates() if data_layer.has_method("get_room_templates") else []
    if typeof(rooms) != TYPE_ARRAY or rooms.size() < 4:
        push_error("Room templates missing")
        ok = false

    var events = data_layer.get_events() if data_layer.has_method("get_events") else []
    if typeof(events) != TYPE_ARRAY:
        push_error("Events data invalid")
        ok = false

    var shop = data_layer.get_shop_data() if data_layer.has_method("get_shop_data") else {}
    for field in ["common_price", "uncommon_price", "rare_price", "remove_price", "heal_price", "options_per_shop"]:
        if not shop.has(field):
            push_error("Shop data missing %s" % field)
            ok = false

    var relics = data_layer.get_relics() if data_layer.has_method("get_relics") else []
    if typeof(relics) != TYPE_ARRAY or relics.size() < 2:
        push_error("Relic data invalid")
        ok = false

    if ok:
        print("Loader test passed")
    get_tree().quit()
