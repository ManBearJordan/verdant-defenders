extends SceneTree

func _init():
	print("Debug: Initialising Autoloads...")
	var autoloads = [
		["DataLayer", "res://scripts/DataLayer.gd"],
		["DeckManager", "res://scripts/DeckManager.gd"],
		["CombatSystem", "res://scripts/CombatSystem.gd"],
		["AscensionController", "res://scripts/AscensionController.gd"],
		["TelemetrySystem", "res://scripts/TelemetrySystem.gd"],
		["DungeonController", "res://scripts/DungeonController.gd"],
		["GameController", "res://scripts/GameController.gd"]
	]
	
	for entry in autoloads:
		var name = entry[0]
		var path = entry[1]
		var node = load(path).new()
		node.name = name
		root.add_child(node)
	
	var dc = root.get_node("DungeonController")
	dc.map_updated.connect(_on_map_updated)
	
	var gc = root.get_node("GameController")
	print("Debug: Calling GameController.start_run('growth')...")
	gc.start_run("growth")
	
	await process_frame
	await process_frame
	print("Debug: Finished waiting.")
	quit()

func _on_map_updated(map, layer, idx):
	print("SUCCESS: Map Updated Signal Received!")
	print("Map Layers: ", map.get("layers", []).size())
