extends Node

# AscensionController
# TASK 9: Ascension Scaling Rules (Final, Locked)
# Ascension increases pressure and decision-making, NOT raw HP sponginess.
# NO HP multipliers, NO flat damage multipliers, NO card number changes.

var ascension_level: int = 0

func set_level(lvl: int) -> void:
	ascension_level = clampi(lvl, 0, 10)
	print("Ascension Level Set: %d" % ascension_level)

# 1) DEPRECATED: Enemy HP/Damage Scaling - NO LONGER USED
# Kept for backward compatibility but returns 1.0 multipliers
func get_enemy_buffs(_tier: String = "") -> Dictionary:
	# TASK 9: Ascension does NOT scale HP or base damage
	return {"hp_mult": 1.0, "dmg_mult": 1.0}

# 2) Enemy Damage Roll Bias (+2% toward max per Ascension)
func get_damage_roll_bias() -> float:
	# Returns 0.0 to 0.20 (at A10)
	# Enemies roll higher-end damage values more often
	return ascension_level * 0.02

# 3) Enemy Intent Density
func get_strong_intent_chance_bonus() -> float:
	# +3% chance per Ascension that enemies choose their "strong" intent
	return ascension_level * 0.03

func get_multi_effect_intent_chance_bonus() -> float:
	# +1% chance per Ascension that enemies chain effects (attack + status)
	return ascension_level * 0.01

# 4) Enemy Status Application Reliability
func get_enemy_status_apply_bonus() -> float:
	# +2% per Ascension that enemy-applied statuses stick
	# Does NOT affect player-applied statuses
	return ascension_level * 0.02

# 5) Elite Modifier Count Rules
func get_elite_modifier_config() -> Dictionary:
	# A0-A3: 1 modifier
	# A4-A7: 2 modifiers
	# A8+: 2 modifiers + 25% chance of 3rd (max 3)
	var count = 1
	var allow_third = false
	
	if ascension_level >= 8:
		count = 2
		if randf() < 0.25:
			count = 3
	elif ascension_level >= 4:
		count = 2
	else:
		count = 1
		
	return {"count": count, "allow_act3_pool": ascension_level >= 6}

# 6) Healing Reduction (Still applies)
func get_healing_mult() -> float:
	if ascension_level >= 7:
		return 0.70 # -30%
	elif ascension_level >= 4:
		return 0.85 # -15%
	return 1.0

# 7) Boss Mastery Thresholds (Still applies)
func get_boss_threshold_deltas() -> Dictionary:
	var seed_delta = 0
	var poison_cap_delta = 0
	
	if ascension_level >= 4:
		seed_delta = -1
		
	if ascension_level >= 1: poison_cap_delta -= 2
	if ascension_level >= 4: poison_cap_delta -= 2
	if ascension_level >= 7: poison_cap_delta -= 2
	
	return {"seed_delta": seed_delta, "poison_cap_delta": poison_cap_delta}

# Utility: Apply damage roll bias to damage range
func apply_damage_bias(base_min: int, base_max: int) -> int:
	# Shifts roll toward max based on ascension
	var bias = get_damage_roll_bias()
	var range_val = base_max - base_min
	var biased_min = base_min + int(floor(range_val * bias))
	
	# Roll in biased range
	return biased_min + randi() % max(1, (base_max - biased_min + 1))
