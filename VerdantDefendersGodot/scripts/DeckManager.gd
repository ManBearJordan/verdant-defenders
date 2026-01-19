extends Node

# --- config ---
# Default number of cards to draw at the start of each turn
const HAND_SIZE: int = 5

# --- signals ---
# Emitted whenever the contents of the player's hand changes.  Hand changes
# occur when the deck is reset, when drawing cards at the start of the turn,
# and when cards are removed from the hand.  The current hand (a duplicated
# array of dictionaries) is passed to listeners.
signal hand_changed(hand: Array[Dictionary])
# Emitted whenever the player's current energy value changes.  Energy changes
# occur at the start of the turn and when energy is spent by playing a card.
signal energy_changed(current: int)

# --- piles / state ---
var draw_pile: Array[Dictionary] = []
var discard_pile: Array[Dictionary] = []
var hand: Array[Dictionary] = []
var exhaust: Array[Dictionary] = []
var energy: int = 0
var max_energy: int = 3

# Internal random number generator used to shuffle the deck.  Can be seeded
# externally via set_rng() to support deterministic runs.
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

# Set the RNG used by the deck manager.  This should be called by
# GameController during run initialization so that all random operations
# (e.g. shuffling the deck) use the same seed.
func set_rng(rng: RandomNumberGenerator) -> void:
	_rng = rng

func _ready() -> void:
	# Do not build a starting deck automatically on boot.  The GameController
	# will call build_starting_deck() when a new run begins.
	pass

# Build starting deck from array of card dictionaries
func build_starting_deck(deck: Array[Dictionary]) -> void:
	draw_pile.clear()
	discard_pile.clear()
	hand.clear()
	exhaust.clear()
	
	# Copy deck into draw pile
	for card in deck:
		if card is Dictionary:
			draw_pile.append(card.duplicate(true))
	
	# Shuffle the draw pile
	_shuffle_draw_pile()
	
	# Reset energy
	energy = 0
	hand_changed.emit(hand.duplicate())
	energy_changed.emit(energy)

# Reset the draw/discard/hand/exhaust piles from the given class's starting
# deck.  This method calls into DataLayer to fetch a 30‑card starting deck.
func reset_with_starting_deck(class_id: String) -> void:
	draw_pile.clear()
	discard_pile.clear()
	hand.clear()
	exhaust.clear()

	# Try to get starting deck from DataLayer
	var deck_def: Array = []
	var dl: Node = get_node_or_null("/root/DataLayer")
	if dl != null and dl.has_method("load_all"):
		dl.call("load_all")
	
	# Obtain the starting deck definition; ensure it is an array
	if dl != null and dl.has_method("get_starting_deck"):
		var tmp: Variant = dl.call("get_starting_deck", class_id)
		if tmp is Array:
			deck_def = tmp as Array
	
	# If no starting deck found, create a minimal one
	if deck_def.is_empty():
		deck_def = _create_minimal_starting_deck()
	
	# Build the deck
	build_starting_deck(deck_def)
	
	# Set max energy from economy config or default to 3
	max_energy = 3
	var eco: Dictionary = {}
	if dl != null:
		if dl.has_method("get_economy_config"):
			eco = dl.call("get_economy_config") as Dictionary
		elif dl.has("economy_config"):
			var ecovar: Variant = dl.get("economy_config")
			if ecovar is Dictionary:
				eco = ecovar as Dictionary
		if eco.has("base_energy"):
			max_energy = int(eco["base_energy"])

	# Reset energy to zero; start_turn() will assign the correct value and
	# notify listeners.
	energy = 0
	# Emit initial hand_changed to indicate the hand is empty
	hand_changed.emit(hand.duplicate())
	energy_changed.emit(energy)

# Called by GameController at the start of each player turn.
# Per TURN_LOOP.md: energy := max_energy, draw 5 cards
func start_turn() -> void:
	# Set energy to max_energy
	energy = max_energy
	
	# Draw up to HAND_SIZE cards
	_draw_up_to(HAND_SIZE)
	
	# Notify listeners of the updated state
	hand_changed.emit(hand.duplicate())
	energy_changed.emit(energy)

# Discard all cards in hand to discard pile
func discard_hand() -> void:
	for card in hand:
		discard_pile.append(card)
	hand.clear()
	hand_changed.emit(hand.duplicate())

# End turn discard - alias for discard_hand
func end_turn_discard() -> void:
	discard_hand()

func get_hand() -> Array[Dictionary]:
	return hand

# Play card at index - returns the card dictionary
func play_card(idx: int) -> Dictionary:
	if idx >= 0 and idx < hand.size():
		var card: Dictionary = hand[idx]
		hand.remove_at(idx)
		# Move to discard pile
		discard_pile.append(card)
		# Notify listeners
		hand_changed.emit(hand.duplicate())
		return card
	return {}

func remove_from_hand(idx: int) -> Dictionary:
	# Remove the card at the specified index from the hand.  Returns the
	# removed card or an empty dictionary if the index is out of range.
	if idx >= 0 and idx < hand.size():
		var c: Dictionary = hand[idx]
		hand.remove_at(idx)
		# Notify listeners
		hand_changed.emit(hand.duplicate())
		return c
	return {}

func discard_card(card: Dictionary) -> void:
	discard_pile.append(card)

func spend_energy(cost: int) -> bool:
	# Spend the specified amount of energy if available.  Returns true on
	# success; false if there is insufficient energy.  Always emits the
	# energy_changed signal on a successful spend.
	if energy < cost:
		return false
	energy -= cost
	energy_changed.emit(energy)
	return true

# Draw a specified number of cards on demand.  This does not reset energy
# or enforce hand size limits beyond those implicit in the draw logic.  After
# drawing, the `hand_changed` signal is emitted.
func draw_cards(n: int) -> void:
	if n <= 0:
		return
	var target: int = hand.size() + n
	_draw_up_to(target)
	hand_changed.emit(hand.duplicate())

# Gain a specified amount of energy.  Negative values reduce energy but will
# not drop below zero.  Emits the `energy_changed` signal after updating.
func gain_energy(amount: int) -> void:
	energy = max(0, energy + amount)
	energy_changed.emit(energy)

# Create a minimal starting deck for testing
func _create_minimal_starting_deck() -> Array[Dictionary]:
	var deck: Array[Dictionary] = []
	
	# Create 10 cards as specified in the requirements
	# Growth strikes/tactics
	for i in range(5):
		deck.append({
			"id": "growth_sap_shot",
			"name": "Sap Shot",
			"type": "attack",
			"cost": 1,
			"effects": [{"type": "deal_damage", "amount": 7}],
			"art_id": "art_sap_shot"
		})
	
	for i in range(5):
		deck.append({
			"id": "seed_shield",
			"name": "Seed Shield", 
			"type": "skill",
			"cost": 1,
			"effects": [{"type": "gain_block", "amount": 6}],
			"art_id": "art_seed_shield"
		})
	
	return deck

# ---------------- internal helpers ----------------

func _draw_up_to(n: int) -> void:
	# Draw cards into the hand until it contains n cards or the draw pile is
	# exhausted.  If the draw pile is empty but the discard pile contains
	# cards, reshuffle the discard pile into the draw pile.
	while hand.size() < n:
		if draw_pile.is_empty():
			_reshuffle()
			if draw_pile.is_empty():
				break
		var c_any: Variant = draw_pile.pop_back()
		if c_any is Dictionary:
			hand.append((c_any as Dictionary))

func _reshuffle() -> void:
	# Move all cards from the discard pile back into the draw pile and
	# randomize their order.  This does nothing if the discard pile is empty.
	if discard_pile.is_empty():
		return
	
	# Move cards from discard to draw pile
	for card in discard_pile:
		draw_pile.append(card)
	discard_pile.clear()
	
	# Shuffle the draw pile
	_shuffle_draw_pile()

func _shuffle_draw_pile() -> void:
	# Simple Fisher–Yates shuffle on the draw pile
	for i in range(draw_pile.size()):
		var j: int = _rng.randi_range(0, draw_pile.size() - 1)
		var tmp: Dictionary = draw_pile[i]
		draw_pile[i] = draw_pile[j]
		draw_pile[j] = tmp
