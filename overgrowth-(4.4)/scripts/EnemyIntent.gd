extends Node

var enemy_data := {}
var intent := {}

func setup(data: Dictionary):
	enemy_data = data
	choose_next_intent()

func choose_next_intent():
	var moves = enemy_data.get("moves", [])
	if moves.size() == 0:
		intent = {"type": "none", "text": "Idle"}
		return
	
	intent = moves.pick_random()

func apply_intent():
	match intent.type:
		"attack":
			CombatSystem.on_player_damaged(intent.amount)
		"block":
			print("Enemy blocks for %d" % intent.amount)
		"status":
			print("Enemy applies status: %s" % intent.status)
		_:
			print("Enemy does nothing.")
