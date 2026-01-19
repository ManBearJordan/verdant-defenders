extends SceneTree

func _init():
	var file = FileAccess.open("res://elemental_verification.txt", FileAccess.WRITE)
	file.store_line("--- Elemental Card Verification ---")
	
	var cards = [
		"e_flame_lash", "e_ember_shot", "e_sunbeam", "e_spark_jab", "e_arc_bolt"
	]
	
	for id in cards:
		var path = "res://resources/Cards/%s.tres" % id
		if not ResourceLoader.exists(path):
			file.store_line("FAIL: Missing %s" % path)
			continue
			
		var res = load(path)
		if not res:
			file.store_line("FAIL: Could not load %s" % path)
			continue
			
		file.store_line("[%s]" % res.display_name)
		file.store_line("  Cost: %d" % res.cost)
		file.store_line("  Damage: %d" % res.damage)
		file.store_line("  Text: %s" % res.effect_text)
		
		# specific checks
		if id == "e_flame_lash" and res.damage != 6: file.store_line("  FAIL: Flame Lash damage != 6")
		if id == "e_ember_shot" and res.damage != 5: file.store_line("  FAIL: Ember Shot damage != 5")
		if id == "e_sunbeam" and res.damage != 11: file.store_line("  FAIL: Sunbeam damage != 11")
		if id == "e_spark_jab" and res.damage != 3: file.store_line("  FAIL: Spark Jab damage != 3")
		if id == "e_arc_bolt" and res.damage != 9: file.store_line("  FAIL: Arc Bolt damage != 9")
		
	file.store_line("--- DONE ---")
	file.close()
	quit(0)
