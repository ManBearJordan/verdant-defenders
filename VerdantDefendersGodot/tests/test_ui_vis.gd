extends SceneTree

func _init():
	print("Test: UI Architecture Separation")
	
	# Mock GameController
	var gc = Node.new()
	gc.name = "GameController"
	root.add_child(gc)
	
	# Mock DungeonController
	var dc = Node.new()
	dc.name = "DungeonController"
	dc.add_user_signal("map_updated", [{"name": "map", "type": TYPE_DICTIONARY}, {"name": "layer", "type": TYPE_INT}, {"name": "idx", "type": TYPE_INT}])
	dc.add_user_signal("room_entered", [{"name": "room", "type": TYPE_DICTIONARY}])
	root.add_child(dc)
	
	# Load GameUI
	var ui_scene = load("res://Scenes/GameUI.tscn")
	var ui = ui_scene.instantiate()
	root.add_child(ui)
	
	# Allow _ready to run
	await process_frame
	
	# 1. Default State (Should be NONE or whatever _ready left it)
	# Assuming no map update yet.
	print("Initial Mode: ", ui.current_view_mode)
	
	# 2. Simulate Map Update
	print("Triggering Map Mode...")
	dc.emit_signal("map_updated", {}, 0, 0)
	await process_frame
	
	if ui.current_view_mode != 0: # ViewMode.MAP
		print("FAIL: ViewMode is not MAP (Got %s)" % ui.current_view_mode)
	else:
		print("SUCCESS: ViewMode is MAP")
		
	# Check Visibility
	var header = ui.get_node("%Header") # Assuming Unique Name or path "RootVBox/Header"
	if not header: header = ui.get_node("RootVBox/Header")
	
	var enemies = ui.get_node("Enemies")
	var hand = ui.get_node("Hand")
	
	if header.visible: print("FAIL: Header is visible in Map Mode")
	else: print("SUCCESS: Header Hidden in Map Mode")
	
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
		
	if not header.visible: print("FAIL: Header hidden in Combat Mode")
	else: print("SUCCESS: Header Visible in Combat Mode")

	quit()
