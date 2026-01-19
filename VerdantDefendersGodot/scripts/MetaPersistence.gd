extends Node

# MetaPersistence - Handles global user profile (XP, Level, Unlocks)
# Saves to user://profile.json

signal xp_gained(amount, total, level)
signal level_up(new_level)

const SAVE_PATH = "user://profile.json"
const XP_PER_LEVEL_BASE = 100
const XP_SCALING = 1.5 # Level 2 = 100, Level 3 = 150, etc.

var current_xp: int = 0
var current_level: int = 1
var unlocked_ids: Array = [] # IDs of unlocked cards/relics

func _ready() -> void:
	load_profile()

func add_xp(amount: int) -> void:
	current_xp += amount
	var xp_needed = get_xp_for_next_level()
	
	print("MetaPersistence: Gained %d XP. Total: %d. Needed: %d" % [amount, current_xp, xp_needed])
	xp_gained.emit(amount, current_xp, current_level)
	
	while current_xp >= xp_needed:
		current_xp -= xp_needed
		current_level += 1
		print("MetaPersistence: LEVEL UP! Now Level %d" % current_level)
		level_up.emit(current_level)
		_check_unlocks()
		xp_needed = get_xp_for_next_level()
	
	save_profile()

func get_xp_for_next_level() -> int:
	# Simple geometric scaling
	# L1->L2: 100
	# L2->L3: 150
	# L3->L4: 225
	return int(XP_PER_LEVEL_BASE * pow(XP_SCALING, current_level - 1))

func is_unlocked(id: String) -> bool:
	# Keep logic simple: if it's in unlocks.json, check if we have it in unlocked_ids.
	# If NOT in unlocks.json (core content), return true.
	# But checking unlocks.json requires loading it here or in DataLayer.
	# Design decision: DataLayer asks "Is this ID locked?"
	# MetaPersistence knows what it HAS unlocked.
	# DataLayer knows what IS lockable.
	# So: DataLayer checks "Is this ID in lock_config?"
	# If yes: DataLayer asks Meta "Do you have this ID?"
	# If no: It's core.
	
	# However, for simplicity here, we just return if we have it.
	# The caller handles the "Core vs Locked" distinction.
	return id in unlocked_ids

func save_profile() -> void:
	var data = {
		"xp": current_xp,
		"level": current_level,
		"unlocks": unlocked_ids
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))

func load_profile() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
		
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var text = file.get_as_text()
	var json = JSON.new()
	if json.parse(text) == OK:
		var data = json.data
		current_xp = int(data.get("xp", 0))
		current_level = int(data.get("level", 1))
		unlocked_ids = data.get("unlocks", [])

func _check_unlocks() -> void:
	# This requires knowing what unlocks at the new level.
	# We can load Data/unlocks.json here or have DataLayer handle it.
	# Let's load it here to keep persistence logic self-contained.
	var dl = get_node_or_null("/root/DataLayer")
	if dl and dl.has_method("get_unlocks_for_level"):
		var new_unlocks = dl.get_unlocks_for_level(current_level)
		for id in new_unlocks:
			if not id in unlocked_ids:
				unlocked_ids.append(id)
				print("MetaPersistence: Unlocked %s" % id)
