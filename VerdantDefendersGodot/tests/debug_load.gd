extends SceneTree

func _init():
	print("DEBUG: Loading Scripts...")
	
	print("1. Loading CardResource...")
	var cr_sc = load("res://scripts/Resources/CardResource.gd")
	if not cr_sc: print("FAIL CardResource")
	else: print("OK CardResource")

	print("2. Loading EnemyResource...")
	var er_sc = load("res://scripts/Resources/EnemyResource.gd")
	if not er_sc: print("FAIL EnemyResource")
	else: print("OK EnemyResource")

	print("3. Loading EnemyUnit...")
	var eu_sc = load("res://scripts/EnemyUnit.gd")
	if not eu_sc: print("FAIL EnemyUnit")
	else: print("OK EnemyUnit")

	print("4. Loading DataLayer...")
	var dl_sc = load("res://scripts/DataLayer.gd")
	if not dl_sc: print("FAIL DataLayer")
	else: print("OK DataLayer")

	print("5. Loading DeckManager...")
	var dm_sc = load("res://scripts/DeckManager.gd")
	if not dm_sc: print("FAIL DeckManager")
	else: print("OK DeckManager")

	print("6. Loading CombatSystem...")
	var cs_sc = load("res://scripts/CombatSystem.gd")
	if not cs_sc: print("FAIL CombatSystem")
	else: print("OK CombatSystem")
	
	quit()
