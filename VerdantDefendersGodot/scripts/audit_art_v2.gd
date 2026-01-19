extends SceneTree

func _init():
	var file = FileAccess.open("res://audit_results.txt", FileAccess.WRITE)
	if not file:
		print("Error: Could not open output file.")
		quit()
		return

	file.store_line("Starting Art Audit...")
	
	# Load ArtRegistry directly
	var art_reg_script = load("res://scripts/ArtRegistry.gd")
	if not art_reg_script:
		file.store_line("Error: Could not load ArtRegistry.gd")
		file.close()
		quit()
		return
		
	var art_reg = art_reg_script.new()
	
	file.store_line("\n--- Checking ArtRegistry Paths ---")
	var mapping = art_reg.ART_MAPPING
	var missing_files = []
	var found_count = 0
	
	for key in mapping:
		var path = mapping[key]
		if not FileAccess.file_exists(path):
			missing_files.append("%s -> %s" % [key, path])
		else:
			found_count += 1
			
	file.store_line("Found %d valid assets." % found_count)
	
	if missing_files.is_empty():
		file.store_line("All registered art paths are VALID.")
	else:
		file.store_line("MISSING FILES defined in Registry (%d):" % missing_files.size())
		for m in missing_files:
			file.store_line("- " + m)

	# 2. Check Specific Map Assets
	file.store_line("\n--- Checking Map Assets ---")
	var required_map = [
		"res://Art/map/decor/vine_path.png",
		"res://Art/map/decor/parallax_front.png",
		"res://Art/map/decor/parallax_back.png",
		"res://Art/ui/panel_runestone.png"
	]
	
	for p in required_map:
		if not FileAccess.file_exists(p):
			file.store_line("- MISSING: " + p)
		else:
			file.store_line("- FOUND: " + p)
	
	file.close()
	quit()
