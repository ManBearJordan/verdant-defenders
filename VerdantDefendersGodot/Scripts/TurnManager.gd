extends Node2D

# Manages turn flow: player turn → enemy turn → next room
class_name TurnManager

signal turn_started(turn_name)
signal turn_ended(turn_name)

var current_turn := "Player"
var energy := 3

func _ready():
    start_player_turn()

func start_player_turn():
    current_turn = "Player"
    energy = 3
    emit_signal("turn_started", current_turn)
    print("Player Turn started. Energy:", energy)

func end_player_turn():
    emit_signal("turn_ended", current_turn)
    start_enemy_turn()

func start_enemy_turn():
    current_turn = "Enemy"
    emit_signal("turn_started", current_turn)
    print("Enemy Turn started.")
    # TODO: call enemy AI routines here
    yield(get_tree().create_timer(1.0), "timeout")
    end_enemy_turn()

func end_enemy_turn():
    emit_signal("turn_ended", current_turn)
    print("Enemy Turn ended.")
    # Proceed to next room or next player turn
    start_player_turn()
