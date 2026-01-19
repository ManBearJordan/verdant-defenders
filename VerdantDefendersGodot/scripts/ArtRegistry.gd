extends Node

# ArtRegistry - maps art_id to texture paths using png_filenames.md + Dynamic Rules

const BASE_PATH = "res://Art/cards/"
const POOL_FOLDERS = {
	"growth": "Growth Cards",
	"decay": "Decay Cards",
	"elemental": "Elemental Cards",
	"neutral": "Neutral Cards"
}

# Legacy/Hardcoded mapping (still used as fallback or for specific overrides)
const ART_MAPPING = {
	"card_back": "res://Art/cards/card_back.png",
	"icon_block": "res://Art/cards/icon_block.png",
	"icon_damage": "res://Art/cards/icon_damage.png",
	# ... (Add critical functional UI textures here)
	"button_end_turn": "res://Art/ui/button_end_turn.9.png",
	"button_buy": "res://Art/ui/button_buy.9.png",
	"button_skip": "res://Art/ui/button_skip.9.png",
	"cost_orb": "res://Art/cards/cost_orb.png",
	"frame_common": "res://Art/cards/frame_common.png",
	"frame_uncommon": "res://Art/cards/frame_uncommon.png",
	# Map Nodes (Organic)
	"node_fight": "res://Art/map/node_mushroom.png",   # Was node_combat.png
	"node_elite": "res://Art/map/node_carnivore.png", # Was node_elite.png
	"node_boss": "res://Art/map/node_tree.png",       # Was node_boss.png
	"node_shop": "res://Art/map/node_log.png",        # Was node_shop.png
	"node_rest": "res://Art/map/node_fire.png",       # Was node_event.png
	"node_event": "res://Art/map/node_firefly.png",   # Was node_event.png
	"node_treasure": "res://Art/map/node_chest.png",
	"frame_rare": "res://Art/cards/frame_rare.png",
	"gold": "res://Art/ui/gold.png",
	"modal": "res://Art/ui/modal.9.png",
	"panel_dark": "res://Art/ui/panel_dark.9.png",
	"tooltip": "res://Art/ui/tooltip.9.png",
	# Targeting
	"target_ring": "res://Art/ui/target_ring.png",
	"target_ring_enemy": "res://Art/ui/target_ring_enemy.png",
	"target_ring_boss": "res://Art/ui/target_ring_boss.png",
	"target_ring_friendly": "res://Art/ui/target_ring_friendly.png",
	"target_ring_hover": "res://Art/ui/target_ring_hover.png",
	"target_ring_pressed": "res://Art/ui/target_ring_pressed.png",
}

func _ready() -> void:
	pass

# --- Dynamic Resolution ---

func get_card_texture(card_id: String, pool: String) -> Texture2D:
	# 1. Try Dynamic Path
	# Rule: art_<stripped_id>.png in <Pool Folder>
	
	var folder = POOL_FOLDERS.get(pool.to_lower(), "Neutral Cards")
	
	# Strip prefix
	var clean_id = card_id
	if clean_id.begins_with("g_") or clean_id.begins_with("d_") or clean_id.begins_with("e_"):
		clean_id = clean_id.substr(2)
		
	var dynamic_path = "%s%s/art_%s.png" % [BASE_PATH, folder, clean_id]
	
	if ResourceLoader.exists(dynamic_path):
		return load(dynamic_path)
		
	# 2. Fallback: Check Legacy Mapping via "art_<id>"
	var legacy_key = "art_" + card_id
	if ART_MAPPING.has(legacy_key):
		var path = ART_MAPPING[legacy_key]
		if ResourceLoader.exists(path):
			return load(path)
			
	# 3. Fallback: Check Legacy Mapping via "art_<clean_id>"?
	legacy_key = "art_" + clean_id
	if ART_MAPPING.has(legacy_key):
		var path = ART_MAPPING[legacy_key]
		if ResourceLoader.exists(path):
			return load(path)

	# 4. Fallback: Card Back
	print("ArtRegistry: Missing art for %s (pool %s). Expected at: %s" % [card_id, pool, dynamic_path])
	return get_texture("card_back")


# --- Legacy API (for non-card lookups) ---

func get_texture(art_id: String) -> Texture2D:
	if ART_MAPPING.has(art_id):
		var path = ART_MAPPING[art_id]
		if ResourceLoader.exists(path):
			return load(path)
	
	# Emergency fallback
	if art_id == "card_back": return null # Prevent infinite loop
	return get_texture("card_back")

func get_art_path(art_id: String) -> String:
	if ART_MAPPING.has(art_id):
		return ART_MAPPING[art_id]
	return ART_MAPPING.get("card_back", "")
