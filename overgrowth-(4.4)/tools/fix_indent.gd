extends SceneTree

func _init():
	print("Fixing Indentation in CombatSystem.gd compatibility...")
	var path = "res://scripts/CombatSystem.gd"
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		print("Error opening file")
		quit()
		return
		
	var content = file.get_as_text()
	file.close()
	
	# Naive strategy: Identify if file uses tabs. If so, replace 4-spaces with tab at start of lines.
	# Or blindly replace "    " with "\t" at start?
	# Safer: checks lines.
	
	var lines = content.split("\n")
	var new_lines = []
	var tab_count = 0
	var space_vote = 0
	
	for line in lines:
		if line.begins_with("\t"): tab_count += 1
		elif line.begins_with("    "): space_vote += 1
		
	print("Tabs: %d, Spaces: %d" % [tab_count, space_vote])
	
	var use_tabs = true
	if space_vote > tab_count and tab_count == 0:
		use_tabs = false
		print("Detected SPACES.")
	else:
		print("Detected TABS (or mixed). Enforcing TABS.")
		
	for line in lines:
		if use_tabs:
			# Replace leading spaces with tabs
			var s = line
			while s.begins_with("    "):
				s = "\t" + s.substr(4)
			new_lines.append(s)
		else:
			new_lines.append(line) # Keep as is if spaces are dominant? or convert tabs to spaces?
			# Assuming resolving mixed to TABS is safer for Godot defaults.
			
	var out = FileAccess.open(path, FileAccess.WRITE)
	out.store_string("\n".join(new_lines))
	print("Fixed Indentation.")
	quit()
