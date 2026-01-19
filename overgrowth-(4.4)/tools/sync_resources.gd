extends SceneTree

func _init():
	print("Syncing card_data.json to Resources...")
	
	var file = FileAccess.open("res://Data/card_data.json", FileAccess.READ)
	if not file:
		print("ERROR: Could not open card_data.json")
		quit()
		return
		
	var json = JSON.new()
	if json.parse(file.get_as_text()) != OK:
		print("ERROR: JSON Parse Error")
		quit()
		return
		
	var data = json.get_data()
	if not data.has("cards") and not data.has("growth"):
		# Check if it has categories directly
		pass
		
	var all_cards = []
	if data.has("neutral"): all_cards.append_array(data["neutral"])
	if data.has("growth"): all_cards.append_array(data["growth"])
	if data.has("decay"): all_cards.append_array(data["decay"])
	if data.has("elemental"): all_cards.append_array(data["elemental"])
	
	print("Found %d cards in JSON." % all_cards.size())
	
	for card_def in all_cards:
		var id = card_def.get("id")
		if not id: continue
		
		# Ensure directory exists
		if not DirAccess.dir_exists_absolute("res://resources/Cards"):
			DirAccess.make_dir_recursive_absolute("res://resources/Cards")
			
		var path = "res://resources/Cards/%s.tres" % id
		var res: CardResource
		if FileAccess.file_exists(path):
			res = load(path)
		else:
			res = CardResource.new()
			
		res.id = id
		res.card_name = card_def.get("name", "Unknown")
		res.cost = int(card_def.get("cost", 1))
		res.type = card_def.get("kind", "Skill").capitalize() # "strike" -> "Strike"
		res.rarity = card_def.get("rarity", "common")
		res.description = card_def.get("text", "")
		res.target_type = 1 if "enemy" in res.description.to_lower() else 0 # Simple heuristic
		if "all enemies" in res.description.to_lower(): res.target_type = 2
		
		# Extract damage/block from effects for preview
		var dmg = 0
		var blk = 0
		for eff in card_def.get("effects", []):
			if eff.get("type") == "deal_damage": dmg = int(eff.get("amount", 0))
			if eff.get("type") == "gain_block": blk = int(eff.get("amount", 0))
			
		res.damage = dmg
		res.block = blk
		
		ResourceSaver.save(res, path)
		
	print("Sync Complete.")
	quit()
