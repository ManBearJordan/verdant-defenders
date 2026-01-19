extends SceneTree

func _init():
	print("Test: UI Architecture Separation V2")
	
	# Mock GameController
	var gc = Node.new()
	gc.name = "GameController"
	root.add_child(gc)
	
	# Mock DungeonController
	var dc = load("res://tests/mock_dc.gd").new()
	dc.name = "DungeonController"
	root.add_child(dc)
	
	# Load GameUI
	var ui_scene = load("res://Scenes/GameUI.tscn")
	var ui = ui_scene.instantiate()
	root.add_child(ui)
	
	# Allow _ready to run
	await process_frame
	await process_frame
	
	# 1. Default State
	print("Initial Mode: ", ui.current_view_mode)
	
	# 2. Simulate Map Update
	print("Triggering Map Mode...")
	# Make current_map valid so check passes if pulled
	dc.current_map = {"layers": []}
	dc.emit_signal("map_updated", dc.current_map, 0, 0)
	await process_frame
	await process_frame
	
	if ui.current_view_mode != 0: # ViewMode.MAP
		print("FAIL: ViewMode is not MAP (Got %s)" % ui.current_view_mode)
	else:
		print("SUCCESS: ViewMode is MAP")
		
	# Check Visibility
	# Access via internal variables or paths
	var header = ui.header_box
	var enemies = ui.enemies_box
	var hand = ui.hand_box
	
	if not header:
		print("ERROR: Header box not found in UI instance")
	else:
		if header.visible: print("FAIL: Header is visible in Map Mode")
		else: print("SUCCESS: Header Hidden in Map Mode")
	
	if not enemies:
		print("ERROR: Enemies box not found")
	else:
		if enemies.visible: print("FAIL: Enemies visible in Map Mode")
		else: print("SUCCESS: Enemies Hidden in Map Mode")

	# 3. Simulate Combat Entry
	print("Triggering Combat Mode...")
	dc.emit_signal("room_entered", {"type": "fight"})
	await process_frame
	
	if ui.current_view_mode != 1: # ViewMode.COMBAT
		print("FAIL: ViewMode is not COMBAT")
	else:
		print("SUCCESS: ViewMode is COMBAT")
		
	if header and not header.visible: print("FAIL: Header hidden in Combat Mode")
	elif header: print("SUCCESS: Header Visible in Combat Mode")

	quit()
