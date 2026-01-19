extends SceneTree

const BANDS = {
	0: {"dmg": 4, "block": 4},
	1: {"dmg": 9, "block": 10}, 
	2: {"dmg": 16, "block": 16},
	3: {"dmg": 99, "block": 99} 
}

func _init():
	print("Running Auto-Balance Patcher...")
	var dir = DirAccess.open("res://resources/Cards")
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	var fixed_count = 0
	
	while file_name != "":
		if !dir.current_is_dir() and file_name.ends_with(".tres"):
			_process_card("res://resources/Cards/" + file_name)
		file_name = dir.get_next()
		
	print("Auto-Balance Complete. Fixed %d cards." % fixed_count)
	quit()

func _process_card(path: String):
	var res = load(path)
	if not res: return
	
	var cost = res.cost
	var limit = BANDS.get(cost)
	if not limit: limit = BANDS[3]
	
	var changed = false
	var log_msg = "%s (Cost %d): " % [res.id, cost]
	
	# Clamp Damage
	if res.damage > limit.dmg:
		log_msg += "Dmg %d -> %d " % [res.damage, limit.dmg]
		res.damage = limit.dmg
		changed = true
		
	# Clamp Block
	if res.block > limit.block:
		log_msg += "Blk %d -> %d " % [res.block, limit.block]
		res.block = limit.block
		changed = true
		
	# Infinite Guard (0-cost draw checks)
	if cost == 0:
		# Very naive check: if text mentions 'draw' and not 'exhaust'
		# A proper check parses effects. For now, we trust Manual Audit for complex logic.
		# This script focuses on numeric bands.
		pass
		
	if changed:
		print("FIX: " + log_msg)
		ResourceSaver.save(res, path)
