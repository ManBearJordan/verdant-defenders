extends SceneTree

func _init():
	print("Attempting to load GameUI.gd...")
	var script = load("res://scripts/GameUI.gd")
	if script:
		print("Load Successful")
	else:
		print("Load Failed")
	quit()
