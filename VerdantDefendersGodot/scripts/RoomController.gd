extends Node

const ENEMY_DATA_PATH: String = "res://Data/enemy_data.json"

func _ready() -> void:
	# Choose a basic pack on first enter (or drive this from a map)
	var pack: Array = _roll_basic_pack()
	_start_combat(pack)

func _start_combat(pack: Array) -> void:
	var cs: Node = get_node_or_null("/root/CombatSystem")
	if cs != null and cs.has_method("begin_encounter"):
		# Start a new run and seed the deck if the run has not begun yet.
		var gc: Node = _gc()
		if gc != null and gc.has_method("start_new_run"):
			# Use a default class (e.g. "Growth") for the initial run
			gc.call("start_new_run", "Growth")
		# Set a combat background.  Choose a default based on the first enemy or
		# environment; here we use "growth_combat" as a placeholder.
		var gui_path := "StartScreen/GameUI"
		var root_node := get_tree().get_root()
		if root_node != null and root_node.has_node(gui_path):
			var gui := root_node.get_node(gui_path)
			if gui != null and gui.has_method("set_background"):
				gui.call("set_background", "growth_combat")
		cs.call("begin_encounter", pack)
	else:
		push_warning("CombatSystem autoload not found at /root/CombatSystem.")

# Hook from CombatSystem when the fight ends.
func _on_combat_finished(victory: bool, is_mini_boss: bool = false) -> void:
	# Called when combat ends.  If the player wins, grant shards and offer
	# card rewards.
	if victory:
		var gc: Node = _gc()
		if gc != null and gc.has_method("add_seeds"):
			var reward: int = 25 if is_mini_boss else 15
			gc.call("add_seeds", reward)
		# Offer card rewards via RewardSystem
		var rs: Node = get_node_or_null("/root/RewardSystem")
		if rs != null and rs.has_method("offer_cards"):
			var offers: Array = rs.call("offer_cards", 3, "Growth") as Array
			# In a real UI, you would present these offers to the player.  For
			# now we print them to the console as a stub.
			for o in offers:
				if o is Dictionary:
					var nm: String = String((o as Dictionary).get("name", "Card"))
					print("Reward option: ", nm)

# ----- UI openings (stub scenes are optional) -----
func _open_shop() -> void:
	var p: PackedScene = load("res://Scenes/ShopUI.tscn")
	if p != null:
		var inst: Node = p.instantiate()
		add_child(inst)
	else:
		push_warning("ShopUI.tscn not found.")

func _open_event() -> void:
	var p: PackedScene = load("res://Scenes/EventUI.tscn")
	if p != null:
		var inst: Node = p.instantiate()
		add_child(inst)
	else:
		push_warning("EventUI.tscn not found.")

# ----- Packs -----
func _roll_basic_pack() -> Array:
	var out: Array = []
	var j: Dictionary = _read_json(ENEMY_DATA_PATH)
	if j.size() > 0 and j.has("basic"):
		var v: Variant = j.get("basic", [])
		if v is Array:
			out = (v as Array).duplicate(true)
	if out.is_empty():
		# Minimal fallback so you always get an encounter.  Use real enemy names
		# that correspond to available art assets (e.g. bark_shield, bone_husk).
		out = [
			{"name":"Bark Shield","hp":30,"intent":{"type":"attack","value":6}},
			{"name":"Bone Husk","hp":22,"intent":{"type":"defend","value":5}},
		]
	return out

func _roll_elite_pack() -> Array:
	var out: Array = []
	var j: Dictionary = _read_json(ENEMY_DATA_PATH)
	if j.size() > 0 and j.has("elite"):
		var v: Variant = j.get("elite", [])
		if v is Array:
			out = (v as Array).duplicate(true)
	if out.is_empty():
		out = [
			{"name":"Elder Treant","hp":60,"intent":{"type":"attack","value":12}},
			{"name":"Briar Warden","hp":48,"intent":{"type":"defend","value":10}},
		]
	return out

func _roll_boss_pack() -> Array:
	var out: Array = []
	var j: Dictionary = _read_json(ENEMY_DATA_PATH)
	if j.size() > 0 and j.has("boss"):
		var v: Variant = j.get("boss", [])
		if v is Array:
			out = (v as Array).duplicate(true)
	if out.is_empty():
		out = [{"name":"Heartwood Titan","hp":120,"intent":{"type":"attack","value":18}}]
	return out

# ----- Utils -----
func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var txt: String = f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(txt)
	return (parsed as Dictionary) if (parsed is Dictionary) else {}

func _gc() -> Node:
	return get_node_or_null("/root/GameController")
