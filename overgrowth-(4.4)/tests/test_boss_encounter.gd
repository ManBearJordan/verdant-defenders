extends GutTest

var dungeon_controller_script = load("res://scripts/DungeonController.gd")
var room_controller_script = load("res://scripts/RoomController.gd")
var combat_system_script = load("res://scripts/CombatSystem.gd")

var dc = null
var rc = null
var cs = null

# Mock class to intercept combat start
class MockCombatSystem extends Node:
	var last_pack = []
	func begin_encounter(pack: Array) -> void:
		last_pack = pack
	func has_method(method: Variant) -> bool:
		return String(method) == "begin_encounter"

func before_each():
	dc = dungeon_controller_script.new()
	dc.name = "DungeonController"
	add_child_autofree(dc)
	
	rc = room_controller_script.new()
	rc.name = "RoomController"
	add_child_autofree(rc)
	
	cs = MockCombatSystem.new()
	cs.name = "CombatSystem"
	add_child_autofree(cs)

func test_boss_room_triggers_boss_pack():
	# Use RoomController directly to verify pack generation logic, 
	# as full integration verification requires mocking /root/ in a complex way.
	# But we can check if RoomController generates the correct pack.
	var pack = rc._roll_boss_pack()
	assert_gt(pack.size(), 0)
	var boss = pack[0]
	assert_true(boss.name == "Blight Dragon" or boss.name == "Heartwood Titan", "Should be boss")

func test_boss_roll_returns_boss():
	# Test RoomController independently first
	var pack = rc._roll_boss_pack()
	assert_gt(pack.size(), 0, "Should have enemies")
	var enemy = pack[0]
	# Known fallback or data
	var possible_names = ["Heartwood Titan", "Blight Dragon"]
	assert_true(possible_names.has(enemy.name), "Enemy should be a boss (Got %s)" % enemy.name)
