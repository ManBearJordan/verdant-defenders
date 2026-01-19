extends Node

# ---------- Public data ----------
# Mapping of card ID to the underlying card dictionary.  Cards are stored once
# here and duplicated when returned via getters to avoid accidental mutation.
var cards_by_id: Dictionary = {}          # id -> card (Dictionary)
# Mapping of class_id to an array of cards belonging to that class.  Populated
# when the card database is loaded; keys come from the top‑level keys in
# `card_data.json` when that file is a dictionary of arrays.
var cards_by_class: Dictionary = {}       # class_id -> Array[Dictionary]
# Flat list of all cards in the database.  This is recomputed on load and
# returned directly by get_cards_all() for efficiency.
var cards_all: Array[Dictionary] = []
# Starting deck definitions loaded from `starting_decks.json`.  Each value
# should be an array of objects (or strings) describing how to assemble the
# starting deck for a class.
var starting_decks: Dictionary = {}       # class_id -> Array
# Optional economy configuration loaded from `economy.json`.  May contain
# values such as `base_energy`.
var economy_config: Dictionary = {}       # optional

const CARD_DB_PATH := "res://Data/card_data.json"
const STARTERS_PATH := "res://Data/starting_decks.json"
const ECONOMY_PATH := "res://Data/economy.json"

func _ready() -> void:
	load_all()

func load_all() -> void:
	# Reset all caches before loading.  This ensures stale values are discarded
	# if load_all() is called more than once in a session.
	cards_by_id.clear()
	cards_by_class.clear()
	cards_all.clear()

	# ---- Card DB (supports three shapes) ----
	var card_raw: Variant = _read_json(CARD_DB_PATH)

	# Shape 1: { "cards": [ {id:...}, ... ] }
	if card_raw is Dictionary and (card_raw as Dictionary).has("cards") and (card_raw["cards"] is Array):
		var list_var: Variant = card_raw["cards"]
		var arr: Array = []
		if list_var is Array:
			arr = list_var as Array
		# treat all cards as belonging to an unknown class "*"
		var class_cards: Array[Dictionary] = []
		for c_v in arr:
			if c_v is Dictionary:
				var c: Dictionary = c_v as Dictionary
				# Determine a unique identifier; fall back to name
				var cid: String = String(c.get("id", c.get("name", "")))
				if cid != "":
					var copy: Dictionary = c.duplicate(true)
					cards_by_id[cid] = copy
					class_cards.append(copy)
					cards_all.append(copy)
		cards_by_class["*"] = class_cards

	# Shape 2: [ {id:...}, ... ]
	elif card_raw is Array:
		var arr2: Array = card_raw as Array
		var class_cards2: Array[Dictionary] = []
		for c_v in arr2:
			if c_v is Dictionary:
				var c: Dictionary = c_v as Dictionary
				var cid2: String = String(c.get("id", c.get("name", "")))
				if cid2 != "":
					var copy2: Dictionary = c.duplicate(true)
					cards_by_id[cid2] = copy2
					class_cards2.append(copy2)
					cards_all.append(copy2)
		cards_by_class["*"] = class_cards2

	# Shape 3: { "Growth":[{...}], "Cunning":[{...}], ... }  (flatten)
	elif card_raw is Dictionary:
		var d: Dictionary = card_raw as Dictionary
		for k_v in d.keys():
			var class_id: String = String(k_v)
			var arr_v: Variant = d[k_v]
			if arr_v is Array:
				var arr3: Array = arr_v as Array
				var class_list: Array[Dictionary] = []
				for c_v in arr3:
					if c_v is Dictionary:
						var c3: Dictionary = c_v as Dictionary
						var cid3: String = String(c3.get("id", c3.get("name", "")))
						if cid3 != "":
							# Copy the card before storing; also annotate with its class for convenience
							var copy3: Dictionary = c3.duplicate(true)
							copy3["class"] = class_id
							cards_by_id[cid3] = copy3
							class_list.append(copy3)
							cards_all.append(copy3)
				# store even if empty so lookups don't raise errors
				cards_by_class[class_id] = class_list

	# ---- Starter decks (optional file) ----
	starting_decks.clear()
	var sd_v: Variant = _read_json(STARTERS_PATH)
	if sd_v is Dictionary:
		var sd_dict: Dictionary = sd_v as Dictionary
		# duplicate to avoid downstream modification
		starting_decks = sd_dict.duplicate(true)

	# ---- Economy config (optional) ----
	economy_config.clear()
	var eco_v: Variant = _read_json(ECONOMY_PATH)
	if eco_v is Dictionary:
		economy_config = (eco_v as Dictionary).duplicate(true)

# ---------- Queries ----------
func get_card(id: String) -> Dictionary:
	return (cards_by_id.get(id, {}) as Dictionary).duplicate(true)

func get_cards_all() -> Array[Dictionary]:
	# Return a duplicated list of all cards.  Use the cached array to avoid
	# repeatedly iterating over the dictionary.  Each element is duplicated
	# to prevent callers from mutating the stored data.
	var out: Array[Dictionary] = []
	for c in cards_all:
		if c is Dictionary:
			out.append((c as Dictionary).duplicate(true))
	return out

func get_starting_deck(class_id: String) -> Array[Dictionary]:
	# Build the starting deck for the given class.  Each entry in the
	# definition can be a String (card id) or a Dictionary containing
	# "id"/"name" and optional "count".  This method will expand counts,
	# verify that each referenced card exists in cards_by_id, and ensure
	# the returned deck contains exactly 30 cards by repeating cards if
	# necessary.  If the starting deck definition is missing or empty,
	# it will fall back to the global card pool to assemble a 30‑card list.
	var result: Array[Dictionary] = []
	# fetch the raw definition
	var def_raw: Variant = starting_decks.get(class_id, [])
	if def_raw is Array:
		var def_arr: Array = def_raw as Array
		for entry in def_arr:
			# Handle string identifiers directly
			if entry is String:
				var cid_str: String = entry as String
				if cards_by_id.has(cid_str):
					var card_def: Dictionary = cards_by_id[cid_str]
					result.append(card_def.duplicate(true))
			# Handle dictionaries with id/name and optional count
			elif entry is Dictionary:
				var entry_dict: Dictionary = entry as Dictionary
				var cid: String = ""
				if entry_dict.has("id"):
					cid = String(entry_dict["id"])
				elif entry_dict.has("name"):
					cid = String(entry_dict["name"])
				var cnt: int = 1
				if entry_dict.has("count"):
					# Only accept integer counts ≥ 1
					cnt = max(1, int(entry_dict["count"]))
				if cid != "" and cards_by_id.has(cid):
					var base_card: Dictionary = cards_by_id[cid]
					for i in range(cnt):
						result.append(base_card.duplicate(true))
	# If no cards were added from the definition, build a fallback deck from all cards
	if result.is_empty():
		var all_cards: Array[Dictionary] = get_cards_all()
		var idx: int = 0
		# Add up to 30 cards, cycling through the pool if necessary
		while result.size() < 30 and all_cards.size() > 0:
			var card: Dictionary = all_cards[idx % all_cards.size()] as Dictionary
			result.append(card.duplicate(true))
			idx += 1
		return result
	# Trim or pad the deck to exactly 30 entries
	# Trim if too many
	if result.size() > 30:
		result = result.slice(0, 30)
	# Pad by cycling through the existing result if too few
	var pad_index: int = 0
	while result.size() < 30:
		var pad_card: Dictionary = result[pad_index % result.size()] as Dictionary
		result.append(pad_card.duplicate(true))
		pad_index += 1
	return result

func get_economy_config() -> Dictionary:
	return economy_config.duplicate(true)

# ---------- JSON helpers (tolerant) ----------
func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var txt: String = f.get_as_text()
	f.close()

	# allow comments and trailing commas common in design docs
	txt = _strip_json_comments(txt).strip_edges()
	if txt == "":
		return {}

	var p: Variant = JSON.parse_string(txt)
	if typeof(p) != TYPE_NIL:
		return p

	# last-ditch: remove some trailing commas that break strict JSON
	txt = txt.replace(",\n]", "\n]").replace(",\r\n]", "\r\n]").replace(", ]", " ]")
	txt = txt.replace(",\n}", "\n}").replace(",\r\n}", "\r\n}").replace(", }", " }")
	p = JSON.parse_string(txt)
	return p if typeof(p) != TYPE_NIL else {}

func _strip_json_comments(t: String) -> String:
	var out := ""
	var in_block := false
	for line in t.split("\n"):
		var s: String = String(line)
		if in_block:
			var end := s.find("*/")
			if end == -1:
				continue
			in_block = false
			s = s.substr(end + 2)
		var start := s.find("/*")
		if start != -1:
			in_block = true
			s = s.substr(0, start)
		var sl := s.find("//")
		if sl != -1:
			s = s.substr(0, sl)
		out += s + "\n"
	return out
