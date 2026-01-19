extends Node

# ---------- Data Storage ----------
var cards_by_id: Dictionary = {}          # id -> CardResource
var cards_by_tag: Dictionary = {}         # tag -> Array[CardResource]
var cards_by_pool: Dictionary = {}        # pool -> Array[CardResource]
var cards_all: Array[CardResource] = []

var enemies_by_id: Dictionary = {}        # id -> EnemyResource
var enemies_by_tier: Dictionary = {}      # tier -> Array[EnemyResource]
var enemies_by_pool: Dictionary = {}      # pool -> Array[EnemyResource]

# Legacy / Other Data
var relics_by_id: Dictionary = {}
var infusions_by_id: Dictionary = {}
var starting_decks_config: Dictionary = {}
var economy_config: Dictionary = {}
var effects_map: Dictionary = {}

const CARD_RES_PATH := "res://Resources/Cards/"
const ENEMY_RES_PATH := "res://Resources/Enemies/"

const STARTERS_PATH := "res://Data/starting_decks.json"
const ECONOMY_PATH := "res://Data/economy.json"
const EFFECTS_PATH := "res://Data/effects.json"
const RELICS_PATH := "res://Data/relics.json"
const INFUSIONS_PATH := "res://Data/infusions.json"
const SIGILS_PATH := "res://Data/sigils.json"

var sigils_by_id: Dictionary = {}

func _ready() -> void:
	load_all()

func load_all() -> void:
	cards_by_id.clear()
	cards_by_pool.clear()
	cards_all.clear()
	enemies_by_id.clear()
	enemies_by_tier.clear()
	enemies_by_pool.clear()
	
	_load_cards_from_resources()
	_load_enemies_from_resources()
	_load_legacy_data()
	_load_unlocks()

var unlocks_config: Dictionary = {}

func _load_unlocks() -> void:
	var path = "res://Data/unlocks.json"
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			unlocks_config = json.data
	else:
		print("DataLayer: No unlocks.json found")

func get_unlocks_for_level(lvl: int) -> Array:
	var out = []
	var key = str(lvl)
	if unlocks_config.has(key):
		var entry = unlocks_config[key]
		out.append_array(entry.get("cards", []))
	return out

func is_card_locked(id: String) -> bool:
	# 1. Is it in unlocks config at all?
	var is_locked_content = false
	for lvl in unlocks_config:
		var entry = unlocks_config[lvl]
		if id in entry.get("cards", []):
			is_locked_content = true
			break
	
	if not is_locked_content:
		return false # Core content
		
	# 2. Check MetaPersistence
	var mp = get_node_or_null("/root/MetaPersistence")
	if mp:
		return not mp.is_unlocked(id)
	
	return true # Default to locked if MP missing but content is locked

func _load_cards_from_resources() -> void:
	var dir = DirAccess.open(CARD_RES_PATH)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tres"):
				var full_path = CARD_RES_PATH + file_name
				var res = load(full_path)
				if res and res is CardResource:
					_register_card(res)
			file_name = dir.get_next()
	else:
		print("DataLayer: Failed to open Card Resource path: ", CARD_RES_PATH)

func _register_card(c: CardResource) -> void:
	cards_by_id[c.id] = c
	cards_all.append(c)
	
	var p = c.pool if c.pool != "" else "neutral"
	if not cards_by_pool.has(p):
		cards_by_pool[p] = []
	cards_by_pool[p].append(c)
	
	for t in c.tags:
		if not cards_by_tag.has(t):
			cards_by_tag[t] = []
		cards_by_tag[t].append(c)

func _load_enemies_from_resources() -> void:
	var dir = DirAccess.open(ENEMY_RES_PATH)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tres"):
				var full_path = ENEMY_RES_PATH + file_name
				var res = load(full_path)
				if res and res is EnemyResource:
					_register_enemy(res)
			file_name = dir.get_next()

func _register_enemy(e: EnemyResource) -> void:
	enemies_by_id[e.id] = e
	
	# Tier
	var t = e.tier if e.tier != "" else "normal"
	if not enemies_by_tier.has(t): 
		var arr: Array[EnemyResource] = []
		enemies_by_tier[t] = arr
	enemies_by_tier[t].append(e)
	
	# Pool
	var p = e.pool if e.pool != "" else "core"
	if not enemies_by_pool.has(p): 
		var arr: Array[EnemyResource] = []
		enemies_by_pool[p] = arr
	enemies_by_pool[p].append(e)

func _load_legacy_data() -> void:
	var sd_v = _read_json(STARTERS_PATH)
	if sd_v is Dictionary:
		starting_decks_config = sd_v
		
	var eco_v = _read_json(ECONOMY_PATH)
	if eco_v is Dictionary:
		economy_config = eco_v
		
	var fx_v = _read_json(EFFECTS_PATH)
	if fx_v is Dictionary and fx_v.has("by_name"):
		effects_map = fx_v["by_name"]

	relics_by_id.clear()
	var r_raw = _read_json(RELICS_PATH)
	if r_raw is Array:
		for r in r_raw:
			if r is Dictionary:
				relics_by_id[String(r.get("id", ""))] = r
	
	infusions_by_id.clear()
	var i_raw = _read_json(INFUSIONS_PATH)
	if i_raw is Array:
		for i in i_raw:
			if i is Dictionary:
				infusions_by_id[String(i.get("id", ""))] = i

	sigils_by_id.clear()
	var s_raw = _read_json(SIGILS_PATH)
	if s_raw is Dictionary and s_raw.has("sigils"):
		for s in s_raw["sigils"]:
			sigils_by_id[String(s.get("id", ""))] = s

# ---------- Getters ----------

func get_card(id: String) -> CardResource:
	return cards_by_id.get(id, null)

func get_all_cards(include_locked: bool = false) -> Array[CardResource]:
	var out: Array[CardResource] = []
	for id in cards_by_id:
		if include_locked or not is_card_locked(id):
			out.append(cards_by_id[id])
	return out

func get_enemy(id: String) -> EnemyResource:
	return enemies_by_id.get(id, null)

func get_enemies_by_tier(tier: String) -> Array[EnemyResource]:
	if enemies_by_tier.has(tier):
		return enemies_by_tier[tier]
	return []

func get_enemies_by_pool(pool: String) -> Array[EnemyResource]:
	if enemies_by_pool.has(pool):
		return enemies_by_pool[pool]
	return []

func get_starting_deck(class_id: String) -> Array[CardResource]:
	var deck: Array[CardResource] = []
	var config = starting_decks_config.get(class_id, [])
	
	if config is Array:
		for entry in config:
			if entry is String:
				var c = get_card(entry)
				if c: deck.append(c)
			elif entry is Dictionary:
				var id = entry.get("id", entry.get("name", ""))
				var count = int(entry.get("count", 1))
				var c = get_card(id)
				if c:
					for i in range(count):
						deck.append(c)
	
	if deck.is_empty() and not cards_all.is_empty():
		for i in range(10):
			deck.append(cards_all.pick_random())

	return deck

func get_relic_def(id: String) -> Dictionary:
	return relics_by_id.get(id, {}).duplicate(true)

func get_infusion_def(id: String) -> Dictionary:
	return infusions_by_id.get(id, {}).duplicate(true)

func get_sigil_def(id: String) -> Dictionary:
	return sigils_by_id.get(id, {}).duplicate(true)	
func get_all_relics() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for val in relics_by_id.values():
		out.append(val.duplicate(true))
	return out

# Strict Filtering
func get_cards_by_criteria(pool: String, rarity: String = "", include_locked: bool = false) -> Array[CardResource]:
	var out: Array[CardResource] = []
	var source_list: Array = []
	
	# Primary Source: Pool
	if pool == "any":
		source_list = cards_all
	elif cards_by_pool.has(pool):
		source_list = cards_by_pool[pool]
	else:
		return []
		
	for c in source_list:
		# 1. Unlock Check
		if not include_locked and is_card_locked(c.id):
			continue
			
		# 2. Rarity Check
		if rarity != "" and c.rarity.to_lower() != rarity.to_lower():
			continue
			
		out.append(c)
		
	return out

func get_economy_config() -> Dictionary:
	return economy_config.duplicate(true)

# ---------- Private Helpers ----------

func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path): return {}
	var f = FileAccess.open(path, FileAccess.READ)
	if not f: return {}
	var txt = f.get_as_text()
	var json = JSON.new()
	if json.parse(txt) == OK:
		return json.data
	return {}
