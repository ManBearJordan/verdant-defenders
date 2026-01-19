extends SceneTree

func _init():
	print("--- Starting Codebase Audit ---")
	var scripts_dir = "res://scripts/"
	var tests_dir = "res://tests/"
	var errors = 0
	
	errors += audit_directory(scripts_dir)
	errors += audit_directory(tests_dir)
	
	if errors == 0:
		print("--- Audit Complete: SUCCESS (No Parse Errors) ---")
		quit(0)
	else:
		print("--- Audit Complete: FAILED (%d Errors) ---" % errors)
		quit(1)

func audit_directory(path: String) -> int:
	var err_count = 0
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".gd"):
				var full_path = path + file_name
				# Try to load
				var scr = load(full_path)
				if scr == null:
					print("ERROR: Failed to load script: %s" % full_path)
					err_count += 1
				else:
					# print("OK: %s" % file_name)
					pass
			file_name = dir.get_next()
	else:
		print("WARNING: Directory not found: %s" % path)
	return err_count
