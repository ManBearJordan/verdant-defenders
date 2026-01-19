extends Node

# FlowController (Autoload Proxy)
# Forwards calls to Main.tscn (GameFlowController) to maintain API compatibility.

enum GameState {
	MAIN_MENU,
	MAP,
	COMBAT,
	REWARD,
	SHOP,
	EVENT,
	REST,
	GAME_OVER,
	VICTORY
}

var current_state: GameState = GameState.MAIN_MENU
var transition_data: Dictionary = {}

func goto(state: GameState, params: Dictionary = {}) -> void:
	print("FlowController: Proxying transition to %s" % GameState.keys()[state])
	current_state = state
	transition_data = params
	
	# Find Main
	var main = get_node_or_null("/root/Main")
	if main and main.has_method("change_state"):
		main.call("change_state", GameState.keys()[state], params)
	else:
		push_error("FlowController: Critical - Main scene not found or invalid! Is Main.tscn the root?")
		# Fallback for dev testing if running isolated scenes? 
		# But this arch demands Main.
		
func resolve_node(node_type: String) -> void:
	print("FlowController: Resolving node type '%s'" % node_type)
	var t = node_type.to_lower()
	match t:
		"fight", "enemy", "skirmish", "start":
			goto(GameState.COMBAT)
		"elite", "miniboss_gate", "miniboss_opt":
			goto(GameState.COMBAT, {"type": "elite"})
		"boss":
			goto(GameState.COMBAT, {"type": "boss"})
		"shop":
			goto(GameState.SHOP)
		"event":
			goto(GameState.EVENT)
		"rest":
			goto(GameState.REST)
		"treasure":
			goto(GameState.REWARD)
		_:
			push_warning("FlowController: Unknown node type %s" % node_type)
			goto(GameState.MAP)

func return_to_map() -> void:
	goto(GameState.MAP)
