extends SceneTree

func _init():
	print("--- Testing Persistence Helpers ---")
	
	# Setup
	var root = get_root()
	var dl = load("res://scripts/DataLayer.gd").new()
	dl.name = "DataLayer"
	root.add_child(dl)
	
	# Load cards
	dl.load_all()
	var all_cards = dl.get_all_cards()
	if all_cards.size() == 0:
		print("FAIL: No cards loaded in DataLayer")
		quit(1)
		return
		
	var c1 = all_cards[0]
	var c2 = all_cards[1]
	var original_list: Array[CardResource] = [c1, c2, c1]
	
	print("Original: %s, %s, %s" % [c1.id, c2.id, c1.id])
	
	# Create Instance of RunPersistence (Mocking wrappers)
	var rp = load("res://scripts/RunPersistence.gd").new()
	root.add_child(rp)
	
	# Test _cards_to_ids
	var ids = rp._cards_to_ids(original_list)
	print("IDs: %s" % str(ids))
	
	if ids.size() != 3:
		print("FAIL: ID count mismatch")
		quit(1)
		return
		
	if ids[0] != c1.id or ids[1] != c2.id:
		print("FAIL: ID mismatch")
		quit(1)
		return
		
	# Test _ids_to_cards
	var restored = rp._ids_to_cards(ids)
	print("Restored Count: %d" % restored.size())
	
	if restored.size() != 3:
		print("FAIL: Restored count mismatch")
		quit(1)
		return
		
	if restored[0].id != c1.id:
		print("FAIL: Restored card ID mismatch. Expected %s, Got %s" % [c1.id, restored[0].id])
		quit(1)
		return
		
	print("PASS: Persistence Helpers Verified.")
	quit(0)
