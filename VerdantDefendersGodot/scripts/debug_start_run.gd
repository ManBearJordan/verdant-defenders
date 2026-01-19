extends SceneTree

func _init():
	print("Debug: Initialising Autoloads...")
	
	# Manually load Autoloads as the SceneTree script doesn't auto-load them in --script mode
	# Order matters!
	var autoloads = [
		["DataLayer", "res://scripts/DataLayer.gd"],
		["DeckManager", "res://scripts/DeckManager.gd"],
		["CombatSystem", "res://scripts/CombatSystem.gd"],
		["RelicSystem", "res://scripts/RelicSystem.gd"],
		["SigilSystem", "res://scripts/SigilSystem.gd"],
		["AscensionController", "res://scripts/AscensionController.gd"],
		["GameController", "res://scripts/GameController.gd"],
		["FlowController", "res://scripts/FlowController.gd"],
		["SoundManager", "res://scripts/SoundManager.gd"]
	]
	
	for entry in autoloads:
		var name = entry[0]
		var path = entry[1]
		var node = load(path).new()
		node.name = name
		root.add_child(node)
		print("Loaded %s" % name)
		
	# Now simulate Start Run
	var gc = root.get_node("GameController")
	print("Debug: Calling GameController.start_run...")
	
	# Needed for GameUI interaction? 
	# GameController.start_run usually changes scene. 
	# In headless mode, change_scene_to_file might fail or do nothing, 
	# but we want to see if the logic CRASHES before that.
	
	# Mock the scene change if possible or just let it try
	
	if gc.has_method("start_run"):
		# Using a valid class_id from previous context
		gc.start_run("ironclad") 
		print("Debug: start_run returned successfully (Logic OK).")
	else:
		print("Debug: CRITICAL - start_run method missing!")
		
	quit()
