extends SceneTree

# Audit Rules: Cost vs Effect Ranges (User Defined)
const RULES = {
	0: {"dmg": 5, "block": 5},    # 0-cost should be weak
	1: {"dmg": 9, "block": 10},   # 1-cost upper bound
	2: {"dmg": 16, "block": 16},  # 2-cost upper bound
	3: {"dmg": 25, "block": 25}   # 3-cost generous
}

func _init():
	print("Running Card Balance Audit (Resources)...")
	
	var dir = DirAccess.open("res://resources/Cards")
	if not dir:
		print("ERROR: Could not open resources/Cards")
		quit()
		return
		
	dir.list_dir_begin()
	var file_name = dir.get_next()
	var cards = []
	
	while file_name != "":
		if !dir.current_is_dir() and file_name.ends_with(".tres"):
			cards.append(file_name)
		file_name = dir.get_next()
		
	# Write results to file
	var out_path = "res://audit_results.txt"
	var f = FileAccess.open(out_path, FileAccess.WRITE)
	if f:
		f.store_string("Audit Verification Results\n")
		f.store_string("==========================\n")
		f.store_string("Scanned %d cards.\n" % cards.size())
	
	var warnings_count = 0
	
	for file in cards:
		var path = "res://resources/Cards/" + file
		var res = load(path)
		if not res: continue
		
		# Assuming CardResource structure properties are accessible
		var name = res.id
		var cost = res.cost
		var dmg = res.damage
		var block = res.block
		
		# Check Cost Band
		var limits = RULES.get(cost)
		if not limits:
			if cost > 3: limits = RULES[3]
			else: limits = RULES[0]
			
		if dmg > limits.dmg:
			var msg = "WARNING: [%s] Cost %d Damage %d exceeds limit %d" % [name, cost, dmg, limits.dmg]
			print(msg)
			if f: f.store_string(msg + "\n")
			warnings_count += 1
			
		if block > limits.block:
			var msg = "WARNING: [%s] Cost %d Block %d exceeds limit %d" % [name, cost, block, limits.block]
			print(msg)
			if f: f.store_string(msg + "\n")
			warnings_count += 1
			
	if f:
		f.close()
		print("Audit saved to %s" % out_path)

	print("\nAudit Complete. %d potential balance issues found." % warnings_count)
	quit()
