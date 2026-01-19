extends SceneTree

func _init():
	var file = FileAccess.open("res://Data/decay_update_v2.json", FileAccess.READ)
	if not file:
		print("File not found")
		quit()
		return
		
	var text = file.get_as_text()
	var json = JSON.new()
	var err = json.parse(text)
	if err != OK:
		print("JSON Error: %d" % err)
		print("Line: %d" % json.get_error_line())
		print("Message: %s" % json.get_error_message())
		
		var lines = text.split("\n")
		var l = json.get_error_line()
		if l >= 0 and l < lines.size():
			print("Context: %s" % lines[l])
			if l > 0: print("Prev: %s" % lines[l-1])
	else:
		print("JSON is Valid")
	quit()
