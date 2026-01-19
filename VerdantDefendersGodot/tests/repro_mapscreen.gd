extends SceneTree

func _init():
	print("Test: Isolated MapScreen Instantiation")
	
	var path = "res://Scenes/MapScreen.tscn"
	if not FileAccess.file_exists(path):
		print("FAIL: File not found: %s" % path)
		quit()
		return
		
	var ps = load(path)
	if not ps:
		print("FAIL: Failed to load PackedScene")
		quit()
		return
		
	var instance = ps.instantiate()
	if not instance:
		print("FAIL: Failed to instantiate")
		quit()
		return
		
	print("Instance Name: %s" % instance.name)
	
	if instance.get_script():
		print("Script Attached: YES - %s" % instance.get_script().resource_path)
	else:
		print("Script Attached: NO")
		
	if instance.has_method("_on_node_click"):
		print("Method _on_node_click: FOUND")
	else:
		print("Method _on_node_click: MISSING")
		
	quit()
