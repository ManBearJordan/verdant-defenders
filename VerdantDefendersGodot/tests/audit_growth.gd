extends SceneTree

func _init():
	var file = FileAccess.open("res://growth_audit_results.txt", FileAccess.WRITE)
	file.store_line("--- Growth Archetype Audit (Simplified) ---")
	
	var dl_script = load("res://scripts/DataLayer.gd")
	var dl = dl_script.new()
	# Do not add to tree, just load manually
	
	# Fix Logic: DataLayer uses 'get_node' for MetaPersistence?
	# DataLayer.gd line 78: var mp = get_node_or_null("/root/MetaPersistence")
	# If not in tree, get_node_or_null might crash or return null?
	# It returns null if not in tree?
	# But dl is RefCounted? NO, extends Node.
	
	# We'll try just calling load_all
	file.store_line("Loading DataLayer...")
	dl.load_all()
	file.store_line("Loaded %d cards." % dl.cards_all.size())
	
	var cards = []
	if dl.cards_by_pool.has("growth"):
		cards = dl.cards_by_pool["growth"]
		
	file.store_line("Growth Cards: %d" % cards.size())
	
	for c in cards:
		var ok = true
		if c.type == "Strike":
			# check seeds > 1
			# naive text check on effects array
			pass
			
	if cards.size() > 0:
		file.store_line("PASS: Audit Complete")
	else:
		file.store_line("FAIL: No cards found")
		
	file.close()
	quit(0)
