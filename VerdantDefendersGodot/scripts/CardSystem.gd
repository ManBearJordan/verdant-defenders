extends Node

@onready var game := get_node("/root/GameController")
@onready var sigils := get_node("/root/SigilSystem")

var energy := 3
var max_energy := 3
var hand := []
var draw_size := 5

func start_turn():
	energy = max_energy
	hand = game.current_deck.pick_random(draw_size)

func end_turn():
	hand.clear()

func play_card(card_id: String, target: Node):
	var card = DataLayer.get_card(card_id)
	var cost = card.get("cost", 1)

	if cost > energy:
		print("Not enough energy to play card: %s" % card_id)
		return

	energy -= cost

	var damage := card.get("damage", 0)
	var block := card.get("block", 0)
	var heal := card.get("heal", 0)
	var status := card.get("status", "")
	var status_amount := card.get("status_amount", 1)
	var target_mode := card.get("target", "single")

	# Sigil system listens to card play
	sigils.on_card_played(card)

	# Track run stats
	CombatSystem.on_card_played(card_id, cost, status, damage)

	# Apply card effects
	if target_mode == "all":
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if damage > 0:
				enemy.apply_damage(damage)
			if status != "":
				enemy.apply_status(status, status_amount)

	elif target_mode == "self":
		if block > 0:
			CombatSystem.gain_block(block)
		if heal > 0:
			CombatSystem.heal_player(heal)

	elif target and target.is_inside_tree():
		if damage > 0:
			target.apply_damage(damage)
		if status != "":
			target.apply_status(status, status_amount)

	# Resource gain (Seed / Rune)
	if card.has("resource_gain"):
		var rtype = card["resource_gain"].get("type", "")
		var ramount = card["resource_gain"].get("amount", 1)
		match rtype:
			"seed":
				GameController.add_seeds(ramount)
			"decay_rune":
				GameController.add_decay_runes(ramount)
			"elemental_rune":
				GameController.add_elemental_runes(ramount)

	# Remove from hand
	hand.erase(card_id)
