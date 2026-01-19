extends SceneTree

func _init():
	print("Loading CombatSystem...")
	var cs_script = load("res://scripts/CombatSystem.gd")
	if cs_script:
		print("Loaded CombatSystem Script")
		var cs = cs_script.new()
		print("Instantiated CombatSystem")
	else:
		print("Failed to load")
	quit()
