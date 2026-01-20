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
	"COMBAT": 7 # Total 14 cards
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
	discard_pile.clear()
	
	# 1. Create Base Cards
	var temp_deck = []
	for i in range(DECK_COMPOSITION.SHOP): temp_deck.append(_create_card("SHOP"))
	for i in range(DECK_COMPOSITION.EVENT): temp_deck.append(_create_card("EVENT"))
	for i in range(DECK_COMPOSITION.TREASURE): temp_deck.append(_create_card("TREASURE"))
	for i in range(DECK_COMPOSITION.COMBAT): temp_deck.append(_create_card("COMBAT"))
	
	# 2. Shuffle initially
	temp_deck.shuffle()
	
	# 3. Enforce R1 = Combat Only (First 3 cards must be COMBAT)
	# We swap non-combats out of 0,1,2
	for i in range(3):
		if temp_deck[i].type != "COMBAT":
			# Find a combat later in the deck
			for j in range(3, temp_deck.size()):
				if temp_deck[j].type == "COMBAT":
					var t = temp_deck[i]
					temp_deck[i] = temp_deck[j]
					temp_deck[j] = t
					break
	
	# 4. Enforce Spacing Rules (simplified "fix" passes)
	# - Shops spaced 4-5? (Hard to strictly guarantee in 14 cards with refill logic, 
	#   but we can try to separate them).
	# - Events not adjacent to Treasure.
	# - Treasure not adjacent to Treasure (implied by "cannot appear twice in same draw" roughly).
	
	temp_deck = _fix_deck_constraints(temp_deck)
	
	room_deck = []
	room_deck.append_array(temp_deck)
	print("MapController: Deck Built (Size: %d)" % room_deck.size())

func _fix_deck_constraints(deck: Array) -> Array:
	# Iterative swaps to resolve conflicts
	var max_passes = 10
	
	for pass_idx in range(max_passes):
		var conflict = false
		
		for i in range(deck.size() - 1):
			var c1 = deck[i]
			var c2 = deck[i+1]
			
			# Rule: No Event <-> Treasure
			if (c1.type == "EVENT" and c2.type == "TREASURE") or \
			   (c1.type == "TREASURE" and c2.type == "EVENT"):
				_swap_away(deck, i+1)
				conflict = true
				break
				
			# Rule: No Shop <-> Shop (Enforce spacing)
			if c1.type == "SHOP" and c2.type == "SHOP":
				_swap_away(deck, i+1)
				conflict = true
				break
				
			# Rule: No Treasure <-> Treasure (Reduce chance of double draw)
			if c1.type == "TREASURE" and c2.type == "TREASURE":
				_swap_away(deck, i+1)
				conflict = true
				break
				
		if not conflict:
			break
			
	return deck

func _swap_away(deck: Array, idx: int) -> void:
	# Swap card at idx with a random card elsewhere (avoiding 0-2 if possible)
	# Prefer swapping with COMBAT
	var candidates = []
	for j in range(3, deck.size()):
		if j != idx and deck[j].type == "COMBAT":
			candidates.append(j)
			
	if not candidates.is_empty():
		var target = candidates.pick_random()
		var temp = deck[idx]
		deck[idx] = deck[target]
		deck[target] = temp

func next_room() -> void:
	# Check if we are done with Boss (Index 14) and trying to advance?
	# If we are at 14, we shouldn't be calling next_room unless we defeated the boss?
	# RunController calls next_room() after battle.
	if current_room_index == 14:
		# Boss defeated?
		# Actually, next_room() is usually called *after* resolution.
		# If we just finished 14, we should advance LAYER.
		next_layer()
	elif current_room_index < ROOMS_PER_LAYER: # Max 15
		draw_choices()

func next_layer() -> void:
	current_layer_index += 1
	if current_layer_index >= LAYERS.size():
		emit_signal("run_completed")
		return
		
	# Reset for new layer
	current_room_index = 0
	_build_layer_deck(current_layer_index)
	_emit_layer_info()
	draw_choices()
	# Reset Ribbon? Ribbon renders based on current_room_index 0 so it resets automatically.

func draw_choices() -> void:
	# Check Boss (Index 14 = 15th room)
	if current_room_index == 14:
		print("MapController: Boss Room Reached")
		active_choices.clear()
		
		# Single Boss Choice
		# We'll represent this as a special card or just handle in UI?
		# Request: "Show a single 'Enter Boss' card or button"
		# Let's create a BOSS card so UI can render it easily
		var boss_card = _create_card("BOSS")
		active_choices.append(boss_card)
		
		emit_signal("boss_reached") # Keeping signal for legacy, but ensuring choices are set
		emit_signal("choices_ready", active_choices)
		return

	# Normal Draw
	# Refill Logic
	if room_deck.size() < 3:
		# If we run out, shuffled restart? 
		# "When deck is empty, reshuffle discard"
		# But we need 3. If we have 1 left, we draw 1 then refill?
		# Or refill first?
		_reshuffle_discard()
		
	# Safety check if still empty (shouldn't happen with 14 cards + discard)
	if room_deck.size() < 3:
		# Emergency rebuild if discard was empty too?
		_build_layer_deck(current_layer_index)

	active_choices.clear()
	for i in range(3):
		if not room_deck.is_empty():
			active_choices.append(room_deck.pop_front())
			
	# Update: "Treasure cannot appear twice in the same draw"
	# _fix_deck_constraints tries to prevent adjacency.
	# But if we draw index 0, 1, 2, adjacency matters.
	# Checks are done.

	# Elite / Mini-Boss Injection
	# "Eligible rooms: 7–11 only"
	# "20% chance per eligible draw"
	# "Replaces a combat card only"
	# "Only one elite OR mini-boss per layer"
	
	if current_room_index >= 6 and current_room_index <= 10: # Rooms 7-11 (Indices 6-10)
		if not elite_defeated_in_layer and not mini_boss_defeated_in_layer:
			if randf() < 0.2: # 20% Chance
				# Find a combat card to replace
				var combat_indices = []
				for k in range(active_choices.size()):
					if active_choices[k].type == "COMBAT":
						combat_indices.append(k)
				
				if not combat_indices.is_empty():
					var target_idx = combat_indices.pick_random()
					# Replace
					# Elite or MiniBoss? Request says "Elite / Mini-Boss Injection".
					# Let's say 50/50 split or logic?
					# "Elite / mini-boss replaces... If elite..."
					# I'll stick to ELITE mostly as per "Elite cards must..." section.
					# Or use MiniBoss if defined. 
					# Earlier spec said "70% Elite / 30% Mini". Keeping that distribution.
					var type = "ELITE"
					if randf() < 0.3: type = "MINI_BOSS"
					
					active_choices[target_idx] = _create_card(type)
					print("MapController: Injected %s at index %d" % [type, target_idx])

	emit_signal("choices_ready", active_choices)

func _reshuffle_discard() -> void:
	print("MapController: Reshuffling discard...")
	room_deck.append_array(discard_pile)
	discard_pile.clear()
	room_deck.shuffle()
	# Apply constraints again? Maybe essential ones?
	# "Reshuffle discard (except boss)".
	# Adjacency might break here. Let's run a quick fix.
	room_deck = _fix_deck_constraints(room_deck)

func select_card(card: RoomCard) -> void:
	# Determine if we advance NOW or LATER
	# "Updates immediately when returning... after a room"
	# So we don't increment yet?
	# Wait, `next_room` is called by RunController `return_to_map`.
	# So here we DO NOT increment current_room_index.
	# We just mark selection and emit.
	
	# Handle specific logic
	if card.type == "ELITE": elite_defeated_in_layer = true
	if card.type == "MINI_BOSS": mini_boss_defeated_in_layer = true
	
	if card.type == "BOSS":
		# Boss entered.
		# Note: Index 14.
		pass
		
	# Consume card logic:
	# "Chosen card is resolved -> discarded"
	# "Remaining cards stay" -> This contradicts "Refills to 3" if we don't remove them?
	# No, "Draw 3, Choose 1". The drawn 3 are removed from deck.
	# The unchosen 2 are... in `active_choices`.
	# If we discard the chosen one, what happens to the unchosen?
	# "Remaining cards stay -> deck refills to 3".
	# This implies unchosen cards return to the front of the deck? Or stay in "Hand"?
	# Standard: Put unchosen back on top of deck? Or keep `active_choices` persistent?
	# "Refills to 3".
	# If I have [A, B, C]. I pick A.
	# B and C remain.
	# I need 3. So I draw D.
	# Next hand [B, C, D].
	# So unchosen cards STAY.
	# Implementation: Push unchosen back to front of `room_deck`?
	# Yes.
	
	active_choices.erase(card) # Remove chosen
	
	# Push remaining back to front of deck (in order)
	# To preserve order [B, C], we push C then B?
	# pop_front took them.
	# If choices were [0, 1, 2].
	# We want next draw to be [1, 2, 3].
	# So we just prepend them.
	
	# Reverse iterate to prepend correctly
	for i in range(active_choices.size()-1, -1, -1):
		room_deck.push_front(active_choices[i])
		
	active_choices.clear()
	discard_pile.append(card)
	
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
			c.icon_path = "res://Art/map/icons/node_elite.png" 
			c.title = "Mini-Boss"
		"BOSS":
			c.icon_path = "res://Art/map/icons/node_boss.png"
			c.title = "%s Boss" % active_layer_name
	return c
