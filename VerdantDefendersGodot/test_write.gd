extends SceneTree

func _init():
	var path = "res://write_test.txt"
	var f = FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string("Hello World")
		f.close()
		print("Wrote to " + path)
	else:
		print("Failed to open " + path)
	quit()
