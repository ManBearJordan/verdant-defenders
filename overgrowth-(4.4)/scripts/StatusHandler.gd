extends Node
## StatusHandler: Central logic for Status Effects (Stacks, Durations, Multipliers).
## Preserves 'statuses' dict as {name: stacks} for compatibility.
## Expects 'status_metadata' dict for tracking duration/expiry.

const CLEANSE_PRIORITY = ["burn", "poison", "shock", "chill", "sap", "fragile", "seed_mark"]

func apply_status(statuses: Dictionary, metadata: Dictionary, name: String, amount: int, duration_type: String = "turns", duration: int = 1) -> void:
	name = name.to_lower()
	var current = int(statuses.get(name, 0))
	
	# Stacking Logic
	if name in ["sap", "fragile"]: # Binary
		current = 1 # Always 1 if active
	elif name == "chill":
		current += amount # Add stacks
		# Cap happens in effect calc, but we can store high stacks
	elif name == "shock":
		current += amount # Add stacks
	else:
		current += amount
	
	statuses[name] = max(0, current)
	
	# Metadata / Duration Logic
	# If refreshing or new, set duration
	if current > 0:
		if not metadata.has(name): metadata[name] = {}
		metadata[name]["type"] = duration_type
		
		# Duration stacking
		# Check Defaults
		if name == "buffer" or name == "dodge" or name == "seed_mark":
			metadata[name]["type"] = "combat"
		elif name == "shock":
			metadata[name]["type"] = "next_turn_only"
		else:
			# Default turns
			metadata[name]["type"] = duration_type
			
		if duration_type != "turns":
			# Should we override above defaults if user specified something?
			# Function arg 'duration_type' defaults to 'turns'.
			# If user passed 'turns' (default), we use our internal defaults logic above.
			# If user passed explicit 'combat', we use that.
			if duration_type != "turns":
				metadata[name]["type"] = duration_type
				
		if metadata[name]["type"] == "turns":
			metadata[name]["duration"] = duration # Reset/Refresh duration


func get_outgoing_damage_mult(statuses: Dictionary, metadata: Dictionary) -> float:
	var mult = 1.0
	
	# SAP: -25%
	if int(statuses.get("sap", 0)) > 0:
		mult *= 0.75
		
	# CHILL: -10% per stack, cap -50% (mult 0.5)
	var chill = int(statuses.get("chill", 0))
	if chill > 0:
		# Spec: outgoing_damage_mult = max(0.50, 1.00 - 0.10 * chill_stacks)
		var chill_mod = max(0.50, 1.0 - (0.10 * chill))
		mult *= chill_mod

	return mult

func get_incoming_damage_mult(statuses: Dictionary, metadata: Dictionary) -> float:
	var mult = 1.0
	
	# FRAGILE: +50%
	if int(statuses.get("fragile", 0)) > 0:
		mult *= 1.50
		
	return mult

func calculate_miss_chance(statuses: Dictionary) -> float:
	# SHOCK: 20% per stack, cap 80%
	var shock = int(statuses.get("shock", 0))
	if shock > 0:
		return min(0.80, 0.20 * shock)
	return 0.0

func process_start_of_turn(statuses: Dictionary, metadata: Dictionary, entity: Object) -> Dictionary:
	# Pipeline B: DoT Damage
	# 1. Sum Ticks
	var poison = int(statuses.get("poison", 0))
	var burn = int(statuses.get("burn", 0))
	var burn_tick = burn * 2
	
	var total_dot = poison + burn_tick
	
	if total_dot <= 0:
		return {"events": [], "total_damage": 0}
	
	# 2. Check Fragile (Incoming Mult)
	# "DoTs apply Fragile multiplier"
	if int(statuses.get("fragile", 0)) > 0:
		total_dot = floor(float(total_dot) * 1.50)
		
	# Return aggregated event for HP reduction, but keep details for UI logging
	var events = []
	if total_dot > 0:
		events.append({"source": "dot", "amount": int(total_dot), "p_tick": poison, "b_tick": burn_tick})
		
	return {
		"events": events,
		"total_damage": int(total_dot),
		"details": {"poison": poison, "burn": burn_tick}
	}

func process_end_of_turn(statuses: Dictionary, metadata: Dictionary) -> void:
	# Handles Decay (Durations, Poison/Burn decay)
	
	# 1. Poison/Burn Decay (-1 stack)
	for k in ["poison", "burn"]:
		if statuses.has(k):
			var v = statuses[k]
			if v > 0:
				statuses[k] = max(0, v - 1)
				
	# 2. Duration Tick
	var keys = statuses.keys()
	for k in keys:
		if statuses[k] <= 0: continue
		
		# Check metadata
		var meta = metadata.get(k, {})
		var type = meta.get("type", "turns")
		
		if type == "turns":
			var d = meta.get("duration", 1)
			d -= 1
			meta["duration"] = d
			if d <= 0:
				statuses[k] = 0 # Expire
		elif type == "next_turn_only":
			# Expire end of turn (Shock)
			statuses[k] = 0
			
	# Cleanup 0
	for k in keys:
		if statuses[k] <= 0:
			statuses.erase(k)
			metadata.erase(k)
			
func cleanse(statuses: Dictionary, metadata: Dictionary, amount: int = 1) -> void:
	# Cleanse highest priority negative status
	# Priority: Burn > Poison > Shock > Chill > Sap > Fragile > Seed Mark
	var removed = 0
	while removed < amount:
		var found = false
		for k in CLEANSE_PRIORITY:
			if statuses.get(k, 0) > 0:
				# Found top priority
				if k in ["sap", "fragile"]: # Binary, remove all
					statuses[k] = 0
				else:
					statuses[k] = max(0, statuses[k] - 1)
				found = true
				break
		if not found: break
		removed += 1

