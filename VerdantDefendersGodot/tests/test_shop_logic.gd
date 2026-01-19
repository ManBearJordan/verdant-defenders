extends SceneTree

# Test Shop Logic (Unit-like)

const LOG_PATH = "user://test_shop.log"

func _log(msg: String) -> void:
	print(msg)
	var f = FileAccess.open(LOG_PATH, FileAccess.READ_WRITE)
	if not f: f = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if f:
		f.seek_end()
		f.store_line(msg)

func _init():
	var f = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if f: f.store_line("Starting Shop Logic Test")
	
	print("Test: Shop Logic")
	
	# Load AutoLoads
	var rc = get_root().get_node("/root/RunController")
	var ss = get_root().get_node("/root/ShopSystem")
	var dm = get_root().get_node("/root/DeckManager") # For remove_card
	
	if not rc or not ss or not dm:
		_log("FAIL: Systems missing")
		quit()
		return
		
	# Setup State
	rc.start_new_run("growth")
	await create_timer(0.5).timeout
	
	rc.shards = 200
	rc.player_hp = 30
	rc.max_hp = 100
	
	# 1. Generate Inventory
	_log("Action: Generate Inventory")
	ss.generate_inventory(5, "growth")
	if ss.current_inventory.size() != 5:
		_log("FAIL: Inventory size mismatch")
		quit()
		return
		
	# 2. Test Purchase
	var card = ss.current_inventory[0]
	var cost = ss.price_for_card(card)
	_log("Action: Purchase Card (Cost: %d)" % cost)
	
	if ss.purchase(0):
		_log("Purchase SUCCESS")
		if rc.shards != (200 - cost):
			_log("FAIL: Shards not deducted correctly. Expected %d, Got %d" % [200-cost, rc.shards])
		if ss.current_inventory.size() != 4:
			_log("FAIL: Card not removed from shop")
	else:
		_log("FAIL: Purchase returned false")
		
	# 3. Test Heal
	var heal_cost = ss.heal_cost_for(20)
	_log("Action: Heal (+20 HP) (Cost: %d)" % heal_cost)
	rc.shards = 100 # Ensure funds
	var start_hp = rc.player_hp
	
	if ss.heal_player(20):
		_log("Heal SUCCESS")
		if rc.player_hp != start_hp + 20: 
			_log("FAIL: HP not updated. Got %d" % rc.player_hp)
		if rc.shards != (100 - heal_cost):
			_log("FAIL: Shards not deducted for heal")
	else:
		_log("FAIL: Heal returned false")

	# 4. Test Remove Card
	var rem_cost = ss.remove_price()
	_log("Action: Remove Card (Cost: %d)" % rem_cost)
	rc.shards = 100
	
	# Manually add a dummy card to deck (if deck is huge)
	# Just pick first available
	var victim = dm.deck[0] if dm.deck.size() > 0 else null
	if not victim:
		_log("FAIL: No cards to remove")
		
	# DeckManager.remove_card takes resource?
	# deck contains IDs or resources? 
	# DM refactor logic: deck is Array[CardResource].
	# But initialization might use IDs.
	# Let's hope start_new_run populates resources.
	# Actually rc.start_new_run -> _get_starter_deck returns IDs.
	# DeckManager probably hydrates them?
	# No, RunController just sets `deck` array.
	# Oh, `RunController` variable `deck` vs `DeckManager` `deck`.
	# `RunController` line 25: `var deck: Array = []`
	# `RunController` line 61: `deck = _get_starter_deck(...)` (Strings).
	
	# `ShopSystem` calls `deck_manager.remove_card(card)`.
	# `ShopSystem` expects `card` to be passed.
	# `DeckManager` deals with `deck` property.
	# Wait, `DeckManager` should be managing the source of truth for the deck in memory?
	# `RunController` says "Manage Run State (HP, Deck..)".
	# If `RunController` holds the deck, does `DeckManager` sync with it?
	# Currently `DeckManager` might be holding its own logic.
	# `RunController` doesn't seem to sync deck to `DeckManager` in this test setup.
	
	# Let's check DeckManager usage in ShopSystem.
	# `dm.remove_card(card)`.
	# If `DeckManager` was not initialized with a deck, it might be empty.
	# RC initializes `deck` (Strings).
	# DM might need `initialize_deck(list)`.
	
	# For this test, let's inject a card into DM directly.
	# Assuming DM.deck is accessible.
	if dm.deck.is_empty():
		# Create fake resource
		var res = load("res://Data/Cards/growth/vine_whip.tres")
		dm.deck.append(res)
		victim = res
		
	if ss.remove_card_from_deck(victim):
		_log("Remove SUCCESS")
		if rc.shards != (100 - rem_cost):
			_log("FAIL: Shards not deducted for remove")
		if victim in dm.deck:
			_log("FAIL: Card still in deck")
	else:
		_log("FAIL: Remove returned false")

	_log("TEST COMPLETE: Shop Logic Verified")
	quit()
