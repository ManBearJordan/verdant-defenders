extends SceneTree

func _init():
	print("Testing MapScreen Load...")
	var scene = load("res://Scenes/UI/Map/MapScreen.tscn")
	if not scene:
		print("FAIL: Could not load MapScreen.tscn")
		quit()
		return
	
	print("MapScreen PacketScene loaded. Instantiating...")
	var instance = scene.instantiate()
	if not instance:
		print("FAIL: Could not instantiate MapScreen")
		quit()
		return
		
	print("SUCCESS: MapScreen Instantiated")
	instance.free()
	quit()
