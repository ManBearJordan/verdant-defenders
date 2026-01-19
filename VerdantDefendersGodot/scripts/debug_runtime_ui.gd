extends SceneTree

func _init():
	print("Debug: Initialising Autoloads...")
	var autoloads = [
		["DataLayer", "res://scripts/DataLayer.gd"],
		["DeckManager", "res://scripts/DeckManager.gd"],
		["CombatSystem", "res://scripts/CombatSystem.gd"],
		["RelicSystem", "res://scripts/RelicSystem.gd"],
		["SigilSystem", "res://scripts/SigilSystem.gd"],
		["AscensionController", "res://scripts/AscensionController.gd"],
		["GameController", "res://scripts/GameController.gd"],
		["SoundManager", "res://scripts/SoundManager.gd"]
	]
	
	for entry in autoloads:
		var name = entry[0]
		var path = entry[1]
		var node = load(path).new()
		node.name = name
		root.add_child(node)
		
	print("Debug: Instantiating GameUI.tscn...")
	var scene = load("res://Scenes/GameUI.tscn")
	var instance = scene.instantiate()
	root.add_child(instance)
	print("Debug: GameUI Added to Tree. Waiting 2 frames...")
	
	await process_frame
	await process_frame
	
	print("Debug: GameUI survived initialization.")
	quit()
