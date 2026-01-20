extends Node

# MapController.gd
# Manages the "Room Deck" navigation system.
# Layers: Growth, Decay, Elemental, Final (4 Total)
# 15 Rooms per layer (Boss at 15)

signal choices_ready(cards: Array)
signal room_selected(card: RoomCard)
signal layer_changed(layer_index: int, layer_name: String)
signal boss_reached
signal run_completed

const LAYERS = ["Growth", "Decay", "Elemental", "Final"]
const ROOMS_PER_LAYER = 15

# Configuration
# Targets for deck composition (excluding Boss) -> 14 rooms
# 3 Shops, 2 Events, 2 Treasures, Rest Combat.
const DECK_COMPOSITION = {
	"SHOP": 3,
	"EVENT": 2,
	"TREASURE": 2,
	"COMBAT": 7 # 14 - 3 - 2 - 2 = 7
}

var current_layer_index: int = 0
var current_room_index: int = 0 # 0 to 14

var room_deck: Array[RoomCard] = []
var discard_pile: Array[RoomCard] = []
var active_choices: Array[RoomCard] = []

var active_layer_name: String = "Growth"
var elite_defeated_in_layer: bool = false
var mini_boss_defeated_in_layer: bool = false

func _ready() -> void:
	print("MapController: Initialized")


func start_run() -> void:
	current_layer_index = 0
	current_room_index = 0
	_build_layer_deck(current_layer_index)
	_emit_layer_info()
	draw_choices()

func _build_layer_deck(layer_idx: int) -> void:
	active_layer_name = LAYERS[min(layer_idx, LAYERS.size()-1)]
	print("MapController: Building deck for ", active_layer_name)
	
	elite_defeated_in_layer = false
	mini_boss_defeated_in_layer = false
	room_deck.clear()
	# discard_pile.clear() # Should we clear discard? "Reset... Call _build". Rebuilding usually implies fresh start for layer?
	# "Populate room_deck with 14 room cards...". 
	# User Spec: "Recreate _build_layer_deck... Clear room_deck."
	
	var deck_composition = [
		"SHOP", "SHOP", "SHOP", 
		"EVENT", "EVENT", 
		"TREASURE", "TREASURE",
		"COMBAT", "COMBAT", "COMBAT", "COMBAT", "COMBAT", "COMBAT", "COMBAT"
	] # 3+2+2+7 = 14
	
	room_deck = []
	for type in deck_composition:
		room_deck.append(_create_card(type))
		
	# Shuffle Combats optionally? Or full shuffle?
	# "Optionally shuffle combat cards while maintaining spacing rules."
	# Usually we shuffle EVERYTHING then fix.
	room_deck.shuffle()
	
	# Enforce Rules
	# 1. First draw (top 3, so indices 0, 1, 2) never contains Shop.
	# We iterate and swap away shops from 0,1,2.
	for i in range(3):
		if i < room_deck.size() and room_deck[i].type == "SHOP":
			# Swap with something later
			for j in range(3, room_deck.size()):
				if room_deck[j].type != "SHOP":
					var temp = room_deck[i]
					room_deck[i] = room_deck[j]
					room_deck[j] = temp
					break
					
	# 2. Events and Treasures aren't adjacent.
	fix_adjacency(room_deck)
	
	print("MapController: Deck Built (Size: %d)" % room_deck.size())

func fix_adjacency(deck: Array) -> void:
	# Rule: No Event next to Treasure.
	var conflict_found = true
	var attempts = 0
	
	while conflict_found and attempts < 10:
		conflict_found = false
		attempts += 1
		
		for i in range(deck.size() - 1):
			var c1 = deck[i]
			var c2 = deck[i+1]
			
			if (c1.type == "EVENT" and c2.type == "TREASURE") or \
			   (c1.type == "TREASURE" and c2.type == "EVENT"):
				
				# Swap c2 with a random candidate that isn't problematic
				var swap_idx = -1
				var candidates = []
				for j in range(deck.size()):
					if j == i or j == i+1: continue
					candidates.append(j)
				
				candidates.shuffle()
				for j in candidates:
					var cand = deck[j]
					# Check if swapping cand into i+1 causes issues at i or i+2
					# Also check if moving c2 to j causes issues at j-1 or j+1
					# For simplicity, just swap with COMBAT if found?
					if cand.type == "COMBAT":
						swap_idx = j
						break
				
				if swap_idx != -1:
					var temp = deck[i+1]
					deck[i+1] = deck[swap_idx]
					deck[swap_idx] = temp
					conflict_found = true # Re-check
					break

func next_room() -> void:
	# Call draw_choices AFTER previous room cleared.
	# But logic for scene switch (RunController) might handle timing.
	# User spec: "Call draw_choices() after the previous room is cleared."
	# If we just finished room index 0, we are now seeking room 1.
	if current_room_index < ROOMS_PER_LAYER:
		draw_choices()

func draw_choices() -> void:
	# Check Boss
	if current_room_index == 14:
		print("MapController: Boss Reached")
		emit_signal("boss_reached")
		return

	# Refill if empty (Cyclic deck)
	if room_deck.is_empty():
		_build_layer_deck(current_layer_index)
		
	# Draw 3
	# Ensure we have enough? 
	# If deck has < 3, we might need to partially fill then rebuild?
	# "If room_deck is empty, call _build". What if it has 1?
	# Simplest: If < 3, rebuild fully? Or append?
	# Spec says "If room_deck is empty...".
	# I will handle the "running out" edge case by forcing rebuild if < 3.
	if room_deck.size() < 3:
		# Preserve remaining? Or clear and rebuild?
		# Spec "Call _build_layer_deck". That function clears it.
		# So existing < 3 cards are lost? Or we should put them back?
		# I'll just clear and rebuild to keep it simple and robust.
		_build_layer_deck(current_layer_index)

	# Draw top 3
	active_choices.clear()
	for i in range(3):
		if not room_deck.is_empty():
			active_choices.append(room_deck.pop_front())

	# Inject Optional Elite/MiniBoss Logic (Rooms 7-11)
	if current_room_index >= 7 and current_room_index <= 11:
		if not elite_defeated_in_layer and not mini_boss_defeated_in_layer:
			# Replace middle choice (index 1)
			if active_choices.size() >= 2:
				var type_to_inject = "ELITE"
				if randf() > 0.7: # 30% Chance for MiniBoss (inverted logic: >0.7 is 30% of range 0-1)
					type_to_inject = "MINI_BOSS"
				
				active_choices[1] = _create_card(type_to_inject)

	emit_signal("choices_ready", active_choices)

func select_card(card: RoomCard) -> void:
	current_room_index += 1
	
	if card.type == "ELITE":
		elite_defeated_in_layer = true
	elif card.type == "MINI_BOSS":
		mini_boss_defeated_in_layer = true
		
	emit_signal("room_selected", card)

func _emit_layer_info() -> void:
	emit_signal("layer_changed", current_layer_index, active_layer_name)

# Factory
func _create_card(type: String) -> RoomCard:
	var c = RoomCard.new(type, type.capitalize())
	# Customize based on type
	match type:
		"COMBAT":
			c.icon_path = "res://Art/map/icons/node_combat.png"
			c.title = "Skirmish"
		"SHOP":
			c.icon_path = "res://Art/map/icons/node_shop.png"
			c.title = "Merchant"
		"EVENT":
			c.icon_path = "res://Art/map/icons/node_event.png"
			c.title = "Unknown"
		"TREASURE":
			c.icon_path = "res://Art/map/icons/node_chest.png"
			c.title = "Treasure"
		"ELITE":
			c.icon_path = "res://Art/map/icons/node_elite.png"
			c.title = "Elite Enemy"
		"MINI_BOSS":
			# Use elite icon or specific if available. Re-using elite for now.
			c.icon_path = "res://Art/map/icons/node_elite.png" 
			c.title = "Mini-Boss"
	return c
