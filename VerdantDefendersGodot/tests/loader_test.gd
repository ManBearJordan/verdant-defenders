extends Node

# Simple headless test verifying DataLoader content.

func _ready():
    if Engine.is_editor_hint():
        return
    var ok := true

    var cards = DataLoader.get_cards()
    if cards.size() != 140:
        push_error("Cards count expected 140, got %d" % cards.size())
        ok = false

    var enemies = DataLoader.get_enemies()
    if enemies.size() < 4:
        push_error("Expected at least 4 enemies")
        ok = false

    var phases = DataLoader.get_boss_phases()
    for boss in ["Thorn King", "Blight Colossus", "Storm Wyrm", "Verdant Overlord", "World Tree"]:
        if not phases.has(boss):
            push_error("Missing boss phase for %s" % boss)
            ok = false

    var dungeon = DataLoader.get_dungeon()
    if typeof(dungeon) != TYPE_DICTIONARY or not dungeon.has("layers") or dungeon.layers.size() != 4:
        push_error("Dungeon data invalid")
        ok = false

    var rooms = DataLoader.get_room_templates()
    if typeof(rooms) != TYPE_ARRAY or rooms.size() < 4:
        push_error("Room templates missing")
        ok = false

    var events = DataLoader.get_events()
    if typeof(events) != TYPE_ARRAY:
        push_error("Events data invalid")
        ok = false

    var shop = DataLoader.get_shop_data()
    for field in ["common_price", "uncommon_price", "rare_price", "remove_price", "heal_price", "options_per_shop"]:
        if not shop.has(field):
            push_error("Shop data missing %s" % field)
            ok = false

    var relics = DataLoader.get_relics()
    if typeof(relics) != TYPE_ARRAY or relics.size() < 2:
        push_error("Relic data invalid")
        ok = false

    if ok:
        print("Loader test passed")
    get_tree().quit()
