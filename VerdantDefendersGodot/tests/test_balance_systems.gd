extends SceneTree

func _init():
	print("Test Balance Systems: Start")
	
	# 1. Setup Autoloads
	var gc_script = load("res://scripts/GameController.gd")
	var dm_script = load("res://scripts/DeckManager.gd")
	var cs_script = load("res://scripts/CombatSystem.gd")
	var dl_script = load("res://scripts/DataLayer.gd")
	var rs_script = load("res://scripts/RelicSystem.gd")
	var ss_script = load("res://scripts/SigilSystem.gd")
	
	var gc = gc_script.new()
	var dm = dm_script.new()
	var cs = cs_script.new()
	var dl = dl_script.new()
	var rs = rs_script.new()
	var ss = ss_script.new()
	
	# Naming is crucial for get_node_or_null("/root/Name")
	gc.name = "GameController"
	dm.name = "DeckManager"
	cs.name = "CombatSystem"
	dl.name = "DataLayer"
	rs.name = "RelicSystem"
	ss.name = "SigilSystem"
	
	get_root().add_child(gc)
	get_root().add_child(dm)
	get_root().add_child(cs)
	get_root().add_child(dl)
	get_root().add_child(rs)
	get_root().add_child(ss)
	
	# Inject Dependencies
	rs.override_datalayer = dl
	rs.override_game_controller = gc
	rs.override_combat_system = cs
	ss.override_game_controller = gc
	ss.override_combat_system = cs
	
	# Manually trigger DataLayer load if needed (it does it in _ready, which runs on add_child)
	# But let's verify data loaded
	if dl.relics_by_id.size() == 0:
		print("WARNING: DataLayer empty? retrying load_all")
		dl.load_all()
	
	# --- Test 1: Thorny Bark (Growth Tradeoff) ---
	print("-- Testing Thorny Bark --")
	# Mock GC state
	gc.player_state = {"seeds": 0, "statuses": {}}
	gc.max_hp = 80
	gc.player_hp = 80
	
	rs.add_relic("thorny_bark")
	if rs.has_relic("thorny_bark"):
		# Check Start Combat Seeds
		rs.apply_initial_seeds(gc)
		if gc.player_state["seeds"] == 3:
			print("PASS: Thorny Bark (+3 Seeds)")
		else:
			print("FAIL: Thorny Bark Seeds. Got: %d" % gc.player_state["seeds"])
			
		# Check Seed Spend Damage
		rs.on_seed_spent(2) # Spend 2
		# Should take 2 damage (1 dmg * 2)
		if gc.player_hp == 78:
			print("PASS: Thorny Bark Damage (-2 HP)")
		else:
			print("FAIL: Thorny Bark Damage. HP: %d (Expected 78)" % gc.player_hp)
	else:
		print("FAIL: Could not add Thorny Bark (ID not found?)")

	# --- Test 2: Ember Shard (Elemental Tradeoff) ---
	print("-- Testing Ember Shard --")
	ss.clear_all_sigils()
	
	# Get definition from DataLayer
	var ember_def = _find_sigil(dl, "ember_shard")
	if not ember_def.is_empty():
		ss.add_sigil(ember_def)
		
		# Check Hand Size Malus
		var malus = ss.get_hand_size_modifier()
		if malus == -2:
			print("PASS: Ember Shard Hand Size (-2)")
		else:
			print("FAIL: Ember Shard Malus. Got: %d" % malus)
			
		# Check Double Cast (Turn Start)
		ss.on_turn_start()
		if ss.should_double_cast() == true:
			print("PASS: Ember Shard Double Cast (First Card)")
		else:
			print("FAIL: Ember Shard Double Cast (Expected True)")
			
		# Play a card
		ss.on_card_played({})
		if ss.should_double_cast() == false:
			print("PASS: Ember Shard Single Cast (Second Card)")
		else:
			print("FAIL: Ember Shard Double Cast (Expected False for 2nd card)")
	else:
		print("FAIL: Ember Shard not found in DataLayer")

	# --- Test 3: Ancient Spark (Decay Tradeoff) ---
	print("-- Testing Ancient Spark (New) --")
	ss.clear_all_sigils()
	
	var spark_def = _find_sigil(dl, "ancient_spark")
	if not spark_def.is_empty():
		ss.add_sigil(spark_def)
		
		# Check Poison Bonus
		var bonus = ss.get_poison_bonus()
		if bonus == 2:
			print("PASS: Ancient Spark Poison Bonus (+2)")
		else:
			print("FAIL: Ancient Spark Bonus. Got: %d" % bonus)
			
		# Check Start Combat Self-Poison
		gc.player_state["statuses"] = {} # Reset
		ss.apply_start_combat_effects(cs)
		var p = gc.player_state["statuses"].get("poison", 0)
		if p == 5:
			print("PASS: Ancient Spark Self-Poison (5)")
		else:
			print("FAIL: Ancient Spark Self-Poison. Got: %d" % p)
	else:
		print("FAIL: Ancient Spark not found in DataLayer")

	print("Test Balance Systems Complete")
	quit()

func _find_sigil(dl, id) -> Dictionary:
	return dl.get_sigil_def(id)
