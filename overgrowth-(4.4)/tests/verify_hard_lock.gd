extends SceneTree

func _init():
	var file = FileAccess.open("res://verification_results.txt", FileAccess.WRITE)
	file.store_line("--- Hard Lock Verification ---")
	
	# Setup Environment
	var root = get_root()
	var dl = load("res://scripts/DataLayer.gd").new()
	dl.name = "DataLayer"
	root.add_child(dl)
	
	var gc = load("res://scripts/GameController.gd").new()
	gc.name = "GameController"
	root.add_child(gc)
	
	var dm = load("res://scripts/DeckManager.gd").new()
	dm.name = "DeckManager"
	root.add_child(dm)
	
	var rs_sys = load("res://scripts/RewardSystem.gd").new()
	rs_sys.name = "RewardSystem"
	root.add_child(rs_sys)
	
	var shop = load("res://scripts/ShopSystem.gd").new()
	shop.name = "ShopSystem"
	root.add_child(shop)
	
	# 1. Test Deck Construction (8+5)
	file.store_line("\n[Test 1] Deck Construction")
	dm.reset_with_starting_deck("growth")
	var deck = dm.draw_pile
	file.store_line("Deck Size: %d" % deck.size())
	
	var arch_count = 0
	var neutral_count = 0
	for c in deck:
		if c.pool == "growth": arch_count += 1
		elif c.pool == "neutral" or c.pool == "": neutral_count += 1
		else: file.store_line("FAIL: Found illegal card: %s (Pool: %s)" % [c.id, c.pool])
	
	file.store_line("Stats: Arch=%d, Neutral=%d" % [arch_count, neutral_count])
	
	if deck.size() != 13:
		file.store_line("FAIL: Expected 13 cards.")
		
	# 2. Test Reward Distribution
	file.store_line("\n[Test 2] Rewards (Normal)")
	var rewards = rs_sys.offer_mixed_rewards(2, 1, "growth")
	file.store_line("Rewards: %s" % str_cards(rewards))
	if rewards.size() != 3:
		file.store_line("FAIL: Expected 3 rewards.")
	
	# 3. Test Shop Distribution
	file.store_line("\n[Test 3] Shop Inventory (n=10)")
	var inv = shop.generate_inventory(10, "growth")
	file.store_line("Shop Size: %d" % inv.size())
	
	var s_arch = 0
	var s_neutral = 0
	for c in inv:
		if c.pool == "growth": s_arch += 1
		else: s_neutral += 1
		
	file.store_line("Shop Stats: Arch=%d, Neutral/Other=%d" % [s_arch, s_neutral])
	
	if s_arch < 5:
		file.store_line("WARNING: Shop Archetype count seems low.")

	file.store_line("\n--- DONE ---")
	file.close()
	quit(0)

func str_cards(arr: Array) -> String:
	var s = "["
	for c in arr: s += "%s (%s), " % [c.id, c.pool]
	return s + "]"
