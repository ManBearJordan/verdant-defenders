extends Node

# --- config ---
const HAND_SIZE: int = 5

# --- signals ---
signal hand_changed(hand: Array[CardResource])
signal energy_changed(current: int)
signal piles_changed()

# --- piles / state ---
# All piles hold unique CardResource instances (duplicated from templates)
var draw_pile: Array[CardResource] = []
var discard_pile: Array[CardResource] = []
var hand: Array[CardResource] = []
var exhaust: Array[CardResource] = []
var energy: int = 0
var max_energy: int = 3
var turn_draws: int = 0
var turn_energy_gained: int = 0
const MAX_TURN_DRAWS = 50
const MAX_TURN_ENERGY_GAIN = 20

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func set_rng(rng: RandomNumberGenerator) -> void:
	_rng = rng

func _ready() -> void:
	pass

# --- Core Pile Management ---

func build_starting_deck(deck: Array[CardResource]) -> void:
	draw_pile.clear()
	discard_pile.clear()
	hand.clear()
	exhaust.clear()
	
	for card in deck:
		# Ensure we are storing unique instances
		draw_pile.append(card.duplicate())
	
	_shuffle_draw_pile()
	energy = 0
	hand_changed.emit(hand.duplicate())
	energy_changed.emit(energy)

	energy_changed.emit(energy)

func reset() -> void:
	draw_pile.clear()
	discard_pile.clear()
	hand.clear()
	exhaust.clear()
	energy = 0
	hand_changed.emit(hand.duplicate())
	energy_changed.emit(energy)

func reset_with_starting_deck(class_id: String) -> void:
	# Clean slate
	draw_pile.clear()
	discard_pile.clear()
	hand.clear()
	exhaust.clear()

	var dl = get_node_or_null("/root/DataLayer")
	if not dl:
		print("DeckManager: DataLayer not found!")
		return

	# --- HARD ARCHETYPE LOCK: CONFIGURATION ---
	# Rule: 8 Archetype Cards + 5 Filler (Neutral) Cards
	var deck: Array[CardResource] = []
	var archetype_count = 8
	var neutral_count = 5
	
	print("DeckManager: Generating Deck for Archetype '%s' (8/5 Split)" % class_id)
	
	# 1. Fetch Archetype Cards (Prefer Basic, Fallback Common)
	var arch_pool = dl.get_cards_by_criteria(class_id, "basic")
	if arch_pool.size() < archetype_count:
		print("DeckManager: Not enough Basic cards for %s, falling back to Common" % class_id)
		arch_pool.append_array(dl.get_cards_by_criteria(class_id, "common"))
		
	# 2. Fetch Neutral/Filler Cards
	var neutral_pool = dl.get_cards_by_criteria("neutral", "basic")
	if neutral_pool.size() < neutral_count:
		neutral_pool.append_array(dl.get_cards_by_criteria("neutral", "common"))
	
	# 3. Construct Deck
	if arch_pool.is_empty() or neutral_pool.is_empty():
		push_error("CRITICAL: Unable to generate valid deck for %s. Missing card definitions." % class_id)
		deck = _create_minimal_starting_deck() # Emergency Fallback
	else:
		# Archetype Picks
		for i in range(archetype_count):
			deck.append(arch_pool.pick_random()) # Allow duplicates? Yes, basic decks have dupes.
			
		# Neutral Picks
		for i in range(neutral_count):
			deck.append(neutral_pool.pick_random())
	
	build_starting_deck(deck)
	
	# Economy / Energy
	max_energy = 3
	var eco = dl.get_economy_config()
	if eco.has("base_energy"):
		max_energy = int(eco["base_energy"])

	energy = 0
	energy_changed.emit(energy)

# --- Turn Logic ---

func get_max_hand_size() -> int:
	var size = HAND_SIZE
	var ss = get_node_or_null("/root/SigilSystem")
	if ss and ss.has_method("get_hand_size_modifier"):
		size += ss.get_hand_size_modifier()
	return max(0, size)

func start_turn() -> void:
	turn_draws = 0
	turn_energy_gained = 0
	energy = max_energy
	_draw_up_to(get_max_hand_size())
	hand_changed.emit(hand.duplicate())
	_draw_up_to(get_max_hand_size())
	hand_changed.emit(hand.duplicate())
	energy_changed.emit(energy)
	piles_changed.emit()

func discard_hand() -> void:
	for card in hand:
		discard_pile.append(card)
	hand.clear()
	hand_changed.emit(hand.duplicate())
	piles_changed.emit()

func end_turn_discard() -> void:
	discard_hand()

func get_hand() -> Array[CardResource]:
	return hand.duplicate()

func play_card(idx: int) -> CardResource:
	if idx >= 0 and idx < hand.size():
		var card = hand[idx]
		hand.remove_at(idx)
		discard_pile.append(card)
		
		hand_changed.emit(hand.duplicate())
		piles_changed.emit()
		
		# Audio Hook
		var sm = get_node_or_null("/root/SoundManager")
		if sm: sm.play_card_draw() # Using draw sound as placeholder or specific play sound
		
		return card
	return null
	return null

func remove_from_hand(idx: int) -> CardResource:
	if idx >= 0 and idx < hand.size():
		var c = hand[idx]
		hand.remove_at(idx)
		hand_changed.emit(hand.duplicate())
		return c
	return null

func discard_card(card: CardResource) -> void:
	discard_pile.append(card)

# --- Energy ---

func spend_energy(cost: int) -> bool:
	if energy < cost: return false
	energy -= cost
	energy_changed.emit(energy)
	return true

func gain_energy(amount: int) -> void:
	if turn_energy_gained >= MAX_TURN_ENERGY_GAIN:
		print("SafetyNet: Energy Gain Cap Reached")
		return
		
	var allowed = amount
	if turn_energy_gained + amount > MAX_TURN_ENERGY_GAIN:
		allowed = MAX_TURN_ENERGY_GAIN - turn_energy_gained
		
	turn_energy_gained += allowed
	energy = max(0, energy + allowed)
	energy_changed.emit(energy)

func draw_cards(n: int) -> void:
	if n <= 0: return
	
	# SafetyNet Draw Cap
	if turn_draws >= MAX_TURN_DRAWS:
		print("SafetyNet: Draw Cap Reached")
		return
		
	var allowed = n
	if turn_draws + n > MAX_TURN_DRAWS:
		allowed = MAX_TURN_DRAWS - turn_draws
		
	turn_draws += allowed
	_draw_up_to(hand.size() + allowed)
	hand_changed.emit(hand.duplicate())

# --- Mechanics ---

func enrich_card(card: CardResource) -> bool:
	# Implementation of upgrading a card.
	# Since 'card' is an instance in our deck, we can modify it directly.
	
	# Logic: Usually enrichment via Anvil adds specialized stats.
	# For simplicity reuse the 'enrichment' concept via logic_meta or just hardcode for now for robustness.
	# Or check if card has an 'upgraded' tag?
	
	# Simple generic upgrade: +damage/block
	if card.logic_meta.has("upgraded"):
		return false
		
	card.display_name += "+"
	if card.damage > 0: card.damage += 3
	if card.block > 0: card.block += 3
	
	card.logic_meta["upgraded"] = true
	
	# If in hand, notify
	if hand.has(card):
		hand_changed.emit(hand.duplicate())
		
	return true

func get_all_cards() -> Array[CardResource]:
	var all: Array[CardResource] = []
	all.append_array(draw_pile)
	all.append_array(hand)
	all.append_array(discard_pile)
	all.append_array(exhaust)
	return all

func get_deck_list() -> Array:
	var list = []
	for c in get_all_cards():
		list.append(c.id)
	return list

func remove_card(card: CardResource) -> bool:
	if hand.has(card):
		hand.erase(card)
		hand_changed.emit(hand.duplicate())
		return true
	if discard_pile.has(card):
		discard_pile.erase(card)
		return true
	if draw_pile.has(card):
		draw_pile.erase(card)
		return true
	return false

# --- Internals ---

func _draw_up_to(n: int) -> void:
	while hand.size() < n:
		if draw_pile.is_empty():
			_reshuffle()
			if draw_pile.is_empty(): break
		
		var c = draw_pile.pop_back()
		hand.append(c)

func _reshuffle() -> void:
	if discard_pile.is_empty(): return
	for c in discard_pile:
		draw_pile.append(c)
	discard_pile.clear()
	_shuffle_draw_pile()

func _shuffle_draw_pile() -> void:
	for i in range(draw_pile.size()):
		var j = _rng.randi_range(0, draw_pile.size() - 1)
		var tmp = draw_pile[i]
		draw_pile[i] = draw_pile[j]
		draw_pile[j] = tmp

func _create_minimal_starting_deck() -> Array[CardResource]:
	var deck: Array[CardResource] = []
	# Create some debug cards
	for i in range(5):
		var c = CardResource.new()
		c.id = "debug_strike"
		c.display_name = "Debug Strike"
		c.type = "Strike"
		c.damage = 6
		c.cost = 1
		deck.append(c)
		
	for i in range(5):
		var c = CardResource.new()
		c.id = "debug_defend"
		c.display_name = "Debug Defend"
		c.type = "Skill"
		c.block = 5
		c.cost = 1
		deck.append(c)
		
	return deck

func build_starting_deck_from_data(class_id: String) -> void:
	# Legacy support wrapper?
	reset_with_starting_deck(class_id)
