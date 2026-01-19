extends SceneTree

func _init():
	print("--- Starting Resource System Verification ---")
	var root = get_root()
	
	# 1. Load DataLayer
	var DL = load("res://scripts/DataLayer.gd").new()
	DL.load_all()
	
	# Verify Cards
	var cards = DL.get_all_cards()
	print("Cards Loaded: %d" % cards.size())
	if cards.size() == 0:
		print("FAIL: No cards loaded.")
		quit(1)
		return
		
	var c0 = cards[0]
	if not (c0 is CardResource):
		print("FAIL: Loaded card is not CardResource.")
		quit(1)
		return
	print("Card[0]: %s (Cost: %d, Dmg: %d)" % [c0.display_name, c0.cost, c0.damage])
	
	# Verify Enemies
	var normal_enemies = DL.get_enemies_by_tier("normal")
	print("Normal Enemies Loaded: %d" % normal_enemies.size())
	if normal_enemies.size() == 0:
		print("FAIL: No normal enemies loaded.")
		quit(1)
		return
		
	var e0 = normal_enemies[0]
	if not (e0 is EnemyResource):
		print("FAIL: Loaded enemy is not EnemyResource.")
		quit(1)
		return
	print("Enemy[0]: %s (HP: %d)" % [e0.display_name, e0.max_hp])
	
	# 2. Simulate DeckManager Build
	print("--- Testing DeckManager ---")
	var DM = load("res://scripts/DeckManager.gd").new()
	DM.name = "DeckManager"
	root.add_child(DM)
	
	# Inject DataLayer logic mockup or assume DL is global? 
	# Scripts use get_node("/root/DataLayer").
	# In this headless test, we need to add DL to root.
	DM.get_parent().remove_child(DM) # Clean up first
	
	root.add_child(DL)
	DL.name = "DataLayer"
	
	root.add_child(DM)
	DM.name = "DeckManager"
	
	# Build deck
	DM.build_starting_deck([c0, c0, c0])
	if DM.draw_pile.size() != 3:
		print("FAIL: Deck build failed. Size: %d" % DM.draw_pile.size())
		quit(1)
		return
	print("Deck Built. Hand Size: %d" % DM.hand.size())
	
	# 3. Simulate CombatSystem
	print("--- Testing CombatSystem ---")
	var CS = load("res://scripts/CombatSystem.gd").new()
	root.add_child(CS)
	CS.name = "CombatSystem"
	
	# Begin Encounter
	CS.begin_encounter([e0])
	print("Encounter Started. Enemies: %d" % CS.enemies.size())
	
	if CS.enemies.size() != 1:
		print("FAIL: Encounter start failed.")
		quit(1)
		return
		
	var unit = CS.enemies[0]
	if not (unit is EnemyUnit):
		print("FAIL: Enemy is not EnemyUnit.")
		quit(1)
		return
	
	print("EnemyUnit: %s (HP: %d)" % [unit.display_name, unit.current_hp])
	
	# Simulate Turn
	CS.enemy_turn()
	print("Enemy Turn Simulated. Turn: %d" % CS.turn)
	
	print("--- VERIFICATION SUCCESSFUL ---")
	quit()
