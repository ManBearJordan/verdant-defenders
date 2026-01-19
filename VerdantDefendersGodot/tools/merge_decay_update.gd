extends SceneTree

func _init():
	print("Merging Decay V2 updates into card_data.json...")
	
	var json = JSON.new()
	
	# Load User Update
	var update_file = FileAccess.open("res://Data/decay_update_v2.json", FileAccess.READ)
	if not update_file:
		print("ERROR: Could not find decay_update_v2.json")
		quit()
		return
	if json.parse(update_file.get_as_text()) != OK:
		print("ERROR: Parse error in update file")
		quit()
		return
	var updates = json.get_data() # Array of card dictionaries
	
	# Load Original Data
	var current_file = FileAccess.open("res://Data/card_data.json", FileAccess.READ)
	if not current_file:
		print("ERROR: Could not find card_data.json")
		quit()
		return
	if json.parse(current_file.get_as_text()) != OK:
		print("ERROR: Parse error in card_data.json")
		quit()
		return
	var data = json.get_data()
	
	if not data.has("decay"):
		print("ERROR: No 'decay' pool in card_data.json")
		quit()
		return
		
	var decay_pool = data["decay"]
	var update_map = {}
	for card in updates:
		update_map[card["id"]] = card
		
	var patched_decay = []
	for card in decay_pool:
		var id = card["id"]
		if update_map.has(id):
			print("Updating %s" % id)
			patched_decay.append(update_map[id])
		else:
			patched_decay.append(card)
			
	# Update the pool
	data["decay"] = patched_decay
	
	# Save Back
	var out = FileAccess.open("res://Data/card_data.json", FileAccess.WRITE)
	out.store_string(JSON.stringify(data, "  "))
	print("Merge Complete.")
	quit()
