@tool
extends SceneTree

# Usage:
# Run via command line:
# ./godot.cmd --headless --script scripts/Tools/ResourceGenerator.gd

func _init():
	print("ResourceGenerator: Starting Migration...")
	
	# Explicitly load resource scripts to avoid class_name resolution issues in CLI
	var CardResScript = load("res://scripts/Resources/CardResource.gd")
	var EnemyResScript = load("res://scripts/Resources/EnemyResource.gd")
	
	if not CardResScript or not EnemyResScript:
		print("ERROR: Could not load Resource scripts!")
		return
	
	# Create directories if they don't exist
	var dir = DirAccess.open("res://")
	if not dir.dir_exists("Resources"):
		dir.make_dir("Resources")
	if not dir.dir_exists("Resources/Cards"):
		dir.make_dir("Resources/Cards")
	if not dir.dir_exists("Resources/Enemies"):
		dir.make_dir("Resources/Enemies")
	
	migrate_cards(CardResScript)
	migrate_enemies(EnemyResScript)
	
	print("ResourceGenerator: Migration Complete.")
	quit()

func migrate_cards(ScriptRef) -> void:
	print("ResourceGenerator: Migrating Cards...")
	var file = FileAccess.open("res://Data/card_data.json", FileAccess.READ)
	if not file:
		print("ERROR: Could not find card_data.json")
		return
		
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	if error != OK:
		print("ERROR: Failed to parse card_data.json")
		return
		
	var data = json.data
	# Structure is { "growth": [...], "decay": [...] }
	
	var count = 0
	for pool_name in data.keys():
		var cards = data[pool_name]
		for c_dict in cards:
			if not c_dict is Dictionary: continue
			
			var res = ScriptRef.new()
			# Determine ID safely
			var name = c_dict.get("name", "Unknown")
			var id = c_dict.get("id", "")
			if id == "":
				id = name.to_lower().replace(" ", "_")
			
			res.id = id
			res.display_name = name
			res.type = c_dict.get("type", "Strike")
			res.cost = int(c_dict.get("cost", 1))
			res.damage = int(c_dict.get("damage", 0))
			res.block = int(c_dict.get("block", 0))
			res.effect_text = c_dict.get("effect", "")
			res.rarity = c_dict.get("rarity", "common")
			res.pool = pool_name
			
			# Handle Tags
			var tags_raw = c_dict.get("tags", [])
			var tags_typed: Array[String] = []
			for t in tags_raw:
				tags_typed.append(str(t))
			res.tags = tags_typed
			
			res.art_id = c_dict.get("art_id", id)
			
			# Capture complex logic (Arrays/Dictionaries) into logic_meta
			var meta = {}
			if c_dict.has("effects"): meta["effects"] = c_dict["effects"]
			if c_dict.has("apply"): meta["apply"] = c_dict["apply"]
			if c_dict.has("draw"): meta["draw"] = c_dict["draw"]
			if c_dict.has("energy_gain"): meta["energy_gain"] = c_dict["energy_gain"]
			if c_dict.has("exhaust"): meta["exhaust"] = c_dict["exhaust"]
			if c_dict.has("enrichment"): meta["enrichment"] = c_dict["enrichment"]
			
			res.logic_meta = meta
			
			# Save
			var path = "res://Resources/Cards/%s.tres" % id
			var err = ResourceSaver.save(res, path)
			if err == OK:
				count += 1
			else:
				print("ERROR: Failed to save card %s: %d" % [id, err])
				
	print("ResourceGenerator: Saved %d cards." % count)

func migrate_enemies(ScriptRef) -> void:
	print("ResourceGenerator: Migrating Enemies...")
	var file = FileAccess.open("res://Data/enemy_data.json", FileAccess.READ)
	if not file:
		print("ERROR: Could not find enemy_data.json")
		return
		
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	if error != OK:
		print("ERROR: Failed to parse enemy_data.json")
		return
		
	var data = json.data
	# Structure is { "growth_layer": [...] }
	
	var count = 0
	for layer_name in data.keys():
		var enemies = data[layer_name]
		for e_dict in enemies:
			if not e_dict is Dictionary: continue
			
			var res = ScriptRef.new()
			var name = e_dict.get("name", "Unknown")
			var id = e_dict.get("id", "")
			if id == "":
				id = name.to_lower().replace(" ", "_")
			
			res.id = id
			res.display_name = name
			res.max_hp = int(e_dict.get("hp", 10))
			res.special_ability = e_dict.get("special", "")
			
			# Intents
			var intents_raw = e_dict.get("intents", [])
			var intents_typed: Array[String] = []
			for i in intents_raw:
				intents_typed.append(str(i))
			res.intents = intents_typed
			
			# Map Tier/Pool
			if "growth" in layer_name:
				res.pool = "growth"
				res.tier = "normal"
			elif "decay" in layer_name:
				res.pool = "decay"
				res.tier = "normal"
			elif "elemental" in layer_name:
				res.pool = "elemental"
				res.tier = "normal"
			
			# Tier Overrides and Act Specifics
			if "elite" in layer_name:
				res.tier = "elite"
				if "act2" in layer_name: res.pool = "decay"
				elif "act3" in layer_name: res.pool = "elemental"
				else: res.pool = "growth" # Default/Legacy "elite" maps to Act 1/Growth? Or Any?
				# Existing "elite" array had Ent (Growth) and Rot Knight (Decay?). 
				# Let's default to "any" for legacy "elite", but new ones use specific pools.
				if layer_name == "elite": res.pool = "any"
				
			if "boss" in layer_name:
				res.tier = "boss"
				if "act2" in layer_name: res.pool = "decay"
				elif "act3" in layer_name: res.pool = "elemental"
				else: res.pool = "growth" # Default "boss" maps to Growth (Act 1)
			
			# Save
			var path = "res://Resources/Enemies/%s.tres" % id
			var err = ResourceSaver.save(res, path)
			if err == OK:
				count += 1
			else:
				print("ERROR: Failed to save enemy %s: %d" % [id, err])
				
	print("ResourceGenerator: Saved %d enemies." % count)
