extends Node

# RunPersistence - Handles saving and loading run state
# Saves to user://savegame.json

const SAVE_PATH = "user://savegame.json"

func save_game() -> void:
	var data = {}
	
	# 1. GameController State
	var gc = get_node_or_null("/root/GameController")
	if gc:
		data["player_hp"] = gc.player_hp
		data["max_hp"] = gc.max_hp
		data["verdant_shards"] = gc.verdant_shards
		data["current_turn"] = gc.current_turn
		data["current_class"] = gc.current_class
		data["seeds"] = gc.player_state.get("seeds", 0)
	
	# 2. DeckManager State
	var dm = get_node_or_null("/root/DeckManager")
	if dm:
		# Convert CardResources to IDs
		data["draw_pile"] = _cards_to_ids(dm.draw_pile)
		data["discard_pile"] = _cards_to_ids(dm.discard_pile)
		data["hand"] = _cards_to_ids(dm.hand)
		data["exhaust"] = _cards_to_ids(dm.exhaust)
	
	# 3. DungeonController State
	var dc = get_node_or_null("/root/DungeonController")
	if dc:
		data["current_map"] = dc.current_map
		data["current_layer"] = dc.current_layer
		data["current_node_index"] = dc.current_node_index
	
	# 4. RelicSystem State
	var rs = get_node_or_null("/root/RelicSystem")
	if rs:
		data["relics"] = rs.active_relics
	
	# 5. InfusionSystem State
	var isys = get_node_or_null("/root/InfusionSystem")
	if isys:
		data["infusions"] = isys.inventory

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		print("RunPersistence: Game Saved.")
	else:
		print("RunPersistence: Failed to save game.")

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var text = file.get_as_text()
	var json = JSON.new()
	if json.parse(text) != OK:
		print("RunPersistence: Corrupt save file.")
		return false
	
	var data: Dictionary = json.data
	
	# Restore State
	
	# GameController
	var gc = get_node_or_null("/root/GameController")
	if gc:
		gc.player_hp = int(data.get("player_hp", 80))
		gc.max_hp = int(data.get("max_hp", 80))
		gc.verdant_shards = int(data.get("verdant_shards", 0))
		gc.current_turn = int(data.get("current_turn", 0))
		gc.current_class = str(data.get("current_class", "growth"))
		if "seeds" in data:
			gc.player_state["seeds"] = int(data["seeds"])
		# Force RNG re-seed?
	
	# DeckManager
	var dm = get_node_or_null("/root/DeckManager")
	if dm:
		dm.draw_pile.clear()
		dm.discard_pile.clear()
		dm.hand.clear()
		dm.exhaust.clear()
		
		# Restore cards from IDs
		dm.draw_pile = _ids_to_cards(data.get("draw_pile", []))
		dm.discard_pile = _ids_to_cards(data.get("discard_pile", []))
		dm.hand = _ids_to_cards(data.get("hand", []))
		dm.exhaust = _ids_to_cards(data.get("exhaust", []))
	
	# DungeonController
	var dc = get_node_or_null("/root/DungeonController")
	if dc:
		dc.current_map = data.get("current_map", {})
		dc.current_layer = int(data.get("current_layer", 0))
		dc.current_node_index = int(data.get("current_node_index", -1))
		# Don't regenerate map!
	
	# RelicSystem
	var rs = get_node_or_null("/root/RelicSystem")
	if rs:
		rs.active_relics.clear()
		for r in data.get("relics", []): rs.active_relics.append(r)
	
	# InfusionSystem
	var isys = get_node_or_null("/root/InfusionSystem")
	if isys:
		isys.inventory.clear()
		for i in data.get("infusions", []): isys.inventory.append(i)
		
	print("RunPersistence: Game Loaded.")
	return true

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
		print("RunPersistence: Save deleted.")

# --- Helpers ---

func _cards_to_ids(cards: Array[CardResource]) -> Array[String]:
	var out: Array[String] = []
	for c in cards:
		if c: out.append(c.id)
	return out

func _ids_to_cards(ids: Array) -> Array[CardResource]:
	var out: Array[CardResource] = []
	var dl = get_node_or_null("/root/DataLayer")
	if not dl: return out
	
	for id in ids:
		var c = dl.get_card(str(id))
		if c:
			# Duplicate to ensure runtime mutability if needed (e.g. temporary buffs)
			# though Resources are usually shared. 
			# DeckManager logic usually duplicates on add. 
			# To be safe, we duplicate here too, consistent with 'build_starting_deck'.
			out.append(c.duplicate()) 
	return out
