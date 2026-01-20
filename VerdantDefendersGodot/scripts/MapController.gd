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
var elite_defeated_in_layer: bool = false
var mini_boss_defeated_in_layer: bool = false

func _ready() -> void:
	print("MapController: Initialized")

func start_run() -> void:
    # ... (existing)

func _build_layer_deck(layer_idx: int) -> void:
	active_layer_name = LAYERS[min(layer_idx, LAYERS.size()-1)]
	print("MapController: Building deck for ", active_layer_name)
	
	elite_defeated_in_layer = false
	mini_boss_defeated_in_layer = false
	room_deck.clear()
    # ... (rest of function)

# ...

func draw_choices() -> void:
	# ... (Boss check)

	# ... (Deck refill loop)
	
	# Inject Optional Elite/MiniBoss Logic (Rooms 7-11)
	# "1 Mini-Boss or Elite... Only appears if player chooses it".
	if current_room_index >= 7 and current_room_index <= 11:
		if not elite_defeated_in_layer and not mini_boss_defeated_in_layer:
			# Decide type: 70% Elite, 30% Mini-Boss
			var type_to_inject = "ELITE"
			if randf() > 0.7:
				type_to_inject = "MINI_BOSS"
				
			# Replace choice
			if active_choices.size() >= 2:
				active_choices[1] = _create_card(type_to_inject)
			elif active_choices.size() > 0:
				active_choices[0] = _create_card(type_to_inject)
		
	emit_signal("choices_ready", active_choices)

# ...

func select_card(card: RoomCard) -> void:
	# ...
	# Update index handled by next_room()...
	
	if card.type == "ELITE":
		elite_defeated_in_layer = true
	elif card.type == "MINI_BOSS":
		mini_boss_defeated_in_layer = true
		
	emit_signal("room_selected", card)

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
	discard_pile.clear()
	
	# 1. Create Pool using Template (Fixed Spacing)
	# User Spec: Shops [3, 7, 11], Events [4, 10], Treasures [6, 13], Combat [Rest]
	# Total 14 rooms (Indices 0-13)
	
	# Initialize with Empty/Null
	var temp_deck: Array = []
	temp_deck.resize(14)
	
	# Fixed Assignments
	var shops = [3, 7, 11]
	var events = [4, 10]
	var treasures = [6, 13]
	
	for idx in shops:
		if idx < 14: temp_deck[idx] = _create_card("SHOP")
		
	for idx in events:
		if idx < 14: temp_deck[idx] = _create_card("EVENT")
		
	for idx in treasures:
		if idx < 14: temp_deck[idx] = _create_card("TREASURE")
		
	# Fill Rest with Combat
	for i in range(14):
		if temp_deck[i] == null:
			temp_deck[i] = _create_card("COMBAT")
			
	room_deck = [] # Type casting
	for card in temp_deck:
		room_deck.append(card)
		
	# Note: No shuffle used for fixed template currently, but validation is applied below.
	fix_adjacency(room_deck)

func fix_adjacency(deck: Array) -> void:
	# Rule: No Event next to Treasure.
	# We iterate and swap if we find a violation.
	var conflict_found = true
	var attempts = 0
	
	while conflict_found and attempts < 5:
		conflict_found = false
		attempts += 1
		
		for i in range(deck.size() - 1):
			var c1 = deck[i]
			var c2 = deck[i+1]
			
			if (c1.type == "EVENT" and c2.type == "TREASURE") or \
			   (c1.type == "TREASURE" and c2.type == "EVENT"):
				
				# Found conflict at i, i+1.
				# Try to find a swappable card (COMBAT) later in the deck
				var swap_idx = -1
				for j in range(i + 2, deck.size()):
					if deck[j].type == "COMBAT":
						swap_idx = j
						break
				
				# If no forward swap, try backward (0 to i-1)
				if swap_idx == -1:
					for j in range(0, i):
						if deck[j].type == "COMBAT":
							# Ensure swapping here doesn't create new conflict
							# Simplified: Just swap
							swap_idx = j
							break
							
				if swap_idx != -1:
					# Swap deck[i+1] (the second card) with deck[swap_idx]
					var temp = deck[i+1]
					deck[i+1] = deck[swap_idx]
					deck[swap_idx] = temp
					
					print("MapController: Adjacency Fix! Swapped %s(%d) with %s(%d)" % 
						[temp.type, i+1, deck[i+1].type, swap_idx])
						
					conflict_found = true # Restart loop to verify
					break # Break inner for loop
	
	if conflict_found:
		push_warning("MapController: Could not fully resolve adjacency rules after 5 passes.")

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
	# "1 Mini-Boss or Elite... Only appears if player chooses it".
	if current_room_index >= 7 and current_room_index <= 11:
		# Check Elite
		if not elite_defeated_in_layer:
			# Ensure we have enough cards to replace
			if active_choices.size() >= 2:
				active_choices[1] = _create_card("ELITE")
				
		# Check Mini-Boss (Independent check, can have both Elite and MB in choices? Maybe overload?)
		# User said "in place of one combat card".
		# If we replaced [1] with Elite, let's use [0] or [2] for Mini-Boss?
		# Or just overwrite Elite if RNG says so?
		# Better: Inject in slot 0 if not elite injected there.
		if not mini_boss_defeated_in_layer:
			if randf() < 0.4: # 40% Chance appearance per step in range
				if active_choices.size() > 0:
					# Avoid overwriting Elite at [1] if possible, or overwrite Combat at [0]
					if active_choices[0].type == "COMBAT":
						active_choices[0] = _create_card("MINI_BOSS")
					elif active_choices.size() > 2 and active_choices[2].type == "COMBAT":
						active_choices[2] = _create_card("MINI_BOSS")
	
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
	
	if card.type == "ELITE":
		elite_defeated_in_layer = true
		
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
		"MINI_BOSS":
			# Use elite icon or specific if available. Re-using elite for now.
			c.icon_path = "res://Art/map/icons/node_elite.png" 
			c.title = "Mini-Boss"
	return c
