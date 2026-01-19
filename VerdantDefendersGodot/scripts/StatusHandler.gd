extends Node
## Tracks lightweight status effects on an owning entity (enemy or player-like).
## Kept intentionally generic. All math is conservative and side-effect free
## (no HP changes here—owner code can query/consume results).

var statuses: Dictionary = {}  # name: String -> stacks: int

func clear() -> void:
	statuses.clear()

func apply_status(name: String, amount: int) -> void:
	var cur: int = int(statuses.get(name, 0))
	statuses[name] = max(0, cur + amount)

func get_status(name: String) -> int:
	# NOTE: replaces any use of the ternary operator.
	return int(statuses.get(name, 0))

func has_status(name: String) -> bool:
	return int(statuses.get(name, 0)) > 0

func tick_start_of_turn() -> void:
	# Simple decay for common buffs/debuffs
	var decaying := ["vulnerable", "weak"]
	for key in decaying:
		var v: int = int(statuses.get(key, 0))
		if v > 0:
			v -= 1
			if v <= 0:
				statuses.erase(key)
			else:
				statuses[key] = v

func trigger_on_hit() -> float:
	# Multiplier to apply when this entity is hit.
	# Example: Vulnerable increases damage taken by 50%.
	var mult: float = 1.0
	if int(statuses.get("vulnerable", 0)) > 0:
		mult = 1.5
	return mult
