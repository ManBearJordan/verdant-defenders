extends "res://addons/gut/test.gd"

var infusion_system: Node
var data_layer_mock
var game_controller_mock
var combat_system_mock

func before_each():
	# Load data layer stub or rely on real one if present
	# We'll use the real script but manually populate dictionary for isolation if needed
	# But actually, DataLayer is an Autoload. Integration test is easier.
	
	infusion_system = load("res://scripts/InfusionSystem.gd").new()
	add_child(infusion_system)

func after_each():
	infusion_system.queue_free()

func test_add_infusion():
	# We rely on DataLayer being present. If not, this test might fail or skip.
	# We can stub the call to DataLayer if we mock the get_node_or_null logic,
	# but `get_node_or_null` is global.
	# Alternative: We can manually inject inventory for "use" tests.
	# For "add", we need DataLayer.
	
	var data_layer = get_node_or_null("/root/DataLayer")
	if not data_layer:
		pending("DataLayer autoload not found (Unit Test environment)")
		return

	# Assuming 'vitality_extract' exists in infusions.json and is loaded
	# If DataLayer isn't initialized in test runner, we might need to call _ready or load_infusions manually.
	if data_layer.has_method("load_infusions"):
		data_layer.call("load_infusions")

	var success = infusion_system.add_infusion("vitality_extract")
	assert_true(success, "Should add vitality_extract")
	assert_eq(infusion_system.inventory.size(), 1)
	assert_eq(infusion_system.inventory[0].get("id"), "vitality_extract")

func test_inventory_limit():
	var data_layer = get_node_or_null("/root/DataLayer")
	if not data_layer: return
	if data_layer.has_method("load_infusions"): data_layer.call("load_infusions")
	
	infusion_system.add_infusion("vitality_extract")
	infusion_system.add_infusion("vitality_extract")
	infusion_system.add_infusion("vitality_extract")
	
	var success = infusion_system.add_infusion("vitality_extract")
	assert_false(success, "Should fail to add 4th item")
	assert_eq(infusion_system.inventory.size(), 3)
