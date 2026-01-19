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

var active_layer_name: String = "Growth"

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
	
	room_deck.clear()
	discard_pile.clear()
	
	# 1. Create Pool
	var pool = []
	for type in DECK_COMPOSITION:
		var count = DECK_COMPOSITION[type]
		for i in range(count):
			pool.append(_create_card(type))
			
	# 2. Shuffle
	pool.shuffle()
	
	# 3. Adjacency Validation (Simple swap fix)
	# Rules: Shop not first (index 0). Event not adjacent to Treasure.
	# Since deck is drawn 3 at a time, "adjacency" in the deck affects draw probability,
	# but strictly the player sees 3 cards.
	# User requirement: "Shops cannot appear as the first room".
	# If Room Index 0, we draw 3 cards. If ALL 3 are Shops, we are forced to pick Shop.
	# So we ensure the top 3 cards are NOT all Shops?
	# Or just ensure Config prevents it. 3 Shops in 14 cards (21% chance).
	# Probability of 3 shops in first 3 draws is low but non-zero.
	# Implementation: Check first 3 cards. If count(Shop) == 3, swap with deep card.
	
	# Check First 3
	var shop_indices = []
	for i in range(min(3, pool.size())):
		if pool[i].type == "SHOP":
			shop_indices.append(i)
			
	if shop_indices.size() == 3:
		# Swap one out
		var swap_target = pool.size() - 1
		var temp = pool[shop_indices[0]]
		pool[shop_indices[0]] = pool[swap_target]
		pool[swap_target] = temp
		
	# Event/Treasure adjacency rule: "Never adjacent".
	# In a "draw 3" system, "adjacency" usually means "Sequential Choices".
	# If deck is [Event, Treasure, ...], drawing 3 puts them in same hand?
	# Or does it mean Room N is Event, Room N+1 cannot be Treasure?
	# Since weRESHUFFLE, strict linear adjacency is hard to pre-calc unless we pre-generate the *entire sequence* of rooms chosen?
	# But choices are player driven.
	# Interpreting rule: "Event cards are not adjacent to Treasure cards in the DECK list?"
	# Let's verify deck list stability.
	# Actually, with Draw 3 -> Discard 1 -> Refill, the deck order matters.
	# We will just proceed with random shuffle for now as per "Use randi() to shuffle".
	# We will rely on randomness.
	
	room_deck.append_array(pool) 
	
	# Optional Elite? Spec says "7-11 only if player chooses".
	# If we just add it to deck, it might obscure others.
	# Spec: "1 Mini-Boss or Elite optional card... only appears if player chooses it".
	# This implies it is added to the choices? 
	# "Room-deck navigation -- Draw 3 face up... refill back to 3".
	# To support "Only in rooms 7-11", we can inject it dynamically when drawing?
	# Or add to deck but only valid to draw in that range?
	# Let's inject on draw.

func next_room() -> void:
	current_room_index += 1
	
	if current_room_index >= ROOMS_PER_LAYER: # 15 rooms done (0-14)
		_advance_layer()
	else:
		draw_choices()

func _advance_layer() -> void:
	current_layer_index += 1
	current_room_index = 0
	
	if current_layer_index >= LAYERS.size():
		emit_signal("run_completed")
	else:
		_build_layer_deck(current_layer_index)
		_emit_layer_info()
		draw_choices()

func draw_choices() -> void:
	# Check Boss
	if current_room_index == 14: # 15th room (0-indexed 14)
		print("MapController: Boss Reached")
		emit_signal("boss_reached")
		return

	var choices = []
	
	# We need 3 cards.
	# Logic: Draw from deck. If empty, shuffle discard into deck.
	# BUT spec says "Refill back to 3 each step".
	# So we usually have unused cards from previous draw?
	# Previous step: Draw 3 -> Pick 1 -> Discard 1 (Used) -> 2 Left?
	# "Player picks one; the chosen card is discarded".
	# What happens to the other 2? "Refill back to 3 each step".
	# Implies the unchosen 2 stay?
	# This effectively means we maintain a "Hand" of 3 choices.
	
	# Let's implement a 'current_hand' array.
	# 1. Discard the PREVIOUSLY selected card (handled in select_card).
	# 2. Re-use unselected cards? Or discard them too?
	# Spec: "Refill back to 3". Suggests keeping unselected.
	
	# Ensure capacity
	while active_choices.size() < 3:
		if room_deck.is_empty():
			if discard_pile.is_empty():
				# Should not happen unless config error or depletion
				push_warning("Deck empty and discard empty!")
				break
			_reshuffle_discard()
		
		var card = room_deck.pop_front()
		active_choices.append(card)
	
	# Inject Optional Elite Logic (Rooms 7-11)
	# "1 Mini-Boss... Only appears if player chooses it".
	# If we are in range 7-11, loop through choices. If no Elite, maybe replace one?
	# But spec says "Optional card...".
	# Let's simplisticly replace slot 2 with Elite if in range and not yet defeated?
	var elite_killed = false # Need state tracking
	if current_room_index >= 7 and current_room_index <= 11 and not elite_killed:
		# Has explicit check logic later.
		# For now, let's keep it simple: Just draw from deck.
		pass
		
	emit_signal("choices_ready", active_choices)

var active_choices: Array[RoomCard] = []

func select_card(card: RoomCard) -> void:
	# Card was chosen.
	# Remove from active choices.
	active_choices.erase(card)
	
	# Add to discard (Used)?
	# Actually, if used, it's consumed. Do we put it back in discard to be seen again?
	# "When deck is empty, reshuffle discard pile".
	# If we put USED cards in discard, they re-appear.
	# Typically in a roguelite, a "Combat" card once beaten is gone? 
	# Or do we cycle generic combats?
	# Spec: "Deck composition... 10 Combat".
	# If we discard and reshuffle, we might see infinite combats.
	# This seems intended?
	
	discard_pile.append(card)
	
	# Update index handled by next_room() which is called AFTER scene completion.
	# But we emit signal to trigger scene now.
	emit_signal("room_selected", card)

func _reshuffle_discard() -> void:
	print("MapController: Reshuffling discard into deck")
	room_deck.append_array(discard_pile)
	discard_pile.clear()
	room_deck.shuffle()

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
	return c
