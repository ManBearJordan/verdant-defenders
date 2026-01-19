extends Node

# Telemetry System V2 (NDJSON)
# Writes 1-line JSON events to user://run_logs/telemetry.ndjson
# Implements "Degenerate Loop Detection" and "Balance Auditing" hooks.

const LOG_FILE_PATH = "user://run_logs/telemetry.ndjson"
const TELEMETRY_VERSION = "1.0"

var _current_run_id: String = ""
var _file_access: FileAccess = null
var _is_logging_enabled: bool = false

# Loop Detection State
var _loop_monitor: Dictionary = {
	"cards_played": 0,
	"unique_cards_played": {}, # Set behavior via manual tracking
	"same_card_max_plays": 0,
	"energy_start": 0,
	"energy_end": 0,
	"energy_gained": 0,
	"energy_spent": 0,
	"cards_drawn": 0,
	"cards_created": 0,
	"exhausted": 0,
	"last_12_cards_sequence": [], # Array of card_ids
	"loop_signature_hashes": []   # integer hashes
}

var _loop_flags_triggered_this_turn: Array = [] # "hard", "soft", "loop"

# -------------------------------------------------------------------------
# TASK 10: Fight Aggregation (per-fight metrics, not per-turn)
# -------------------------------------------------------------------------
var _fight_agg: Dictionary = {}

func _reset_fight_aggregator() -> void:
	# Called on fight start
	_fight_agg = {
		# Context
		"fight_id": "",
		"act": 0,
		"ascension": 0,
		"node_type": "normal",
		"enemy_archetypes": [],
		"elite_modifiers": [],
		"player_character": "growth",
		"deck_size": 0,
		"avg_card_cost": 0.0,
		
		# Outcome accumulators
		"turns_taken": 0,
		"damage_taken_total": 0,
		"healing_gained_total": 0,
		"block_generated_total": 0,
		"energy_generated_total": 0,
		"cards_played_total": 0,
		"cards_drawn_total": 0,
		
		# Status applied totals (by player)
		"poison_applied": 0,
		"burn_applied": 0,
		"sap_applied": 0,
		"fragile_applied": 0,
		"chill_applied": 0,
		"shock_applied": 0,
		
		# Status effectiveness
		"poison_damage_dealt": 0,
		"burn_damage_dealt": 0,
		"damage_reduced_by_sap": 0,
		"damage_reduced_by_chill": 0,
		"attacks_missed_due_to_shock": 0,
		
		# Elite-specific
		"elite_hp_start": 0,
		"elite_hp_end": 0,
		"modifiers_count": 0,
		"turns_survived": 0,
		"player_hp_at_kill": 0,
		
		# Boss-specific
		"phase_count": 0,
		"phase_transitions_turns": [],
		"boss_healing_total": 0,
		"player_death_phase": 0,
		
		# Card metrics (keyed by card_id)
		"card_metrics": {}
	}

# -------------------------------------------------------------------------
# Lifecycle & File I/O
# -------------------------------------------------------------------------

func _ready() -> void:
	# Ensure log directory exists
	if not DirAccess.dir_exists_absolute("user://run_logs"):
		DirAccess.make_dir_absolute("user://run_logs")
	
	# Open file for appending
	if _is_logging_enabled:
		_open_log_file()
		print("TelemetrySystem V2 Ready. Logging to: %s" % LOG_FILE_PATH)
	else:
		print("TelemetrySystem V2 Ready. Logging DISABLED.")

func _open_log_file() -> void:
	if FileAccess.file_exists(LOG_FILE_PATH):
		_file_access = FileAccess.open(LOG_FILE_PATH, FileAccess.READ_WRITE)
		_file_access.seek_end()
	else:
		_file_access = FileAccess.open(LOG_FILE_PATH, FileAccess.WRITE)

func _log(event_type: String, data: Dictionary) -> void:
	if not _is_logging_enabled or not _file_access:
		return
	
	# Construct base object
	var entry = {
		"ts": Time.get_unix_time_from_system() * 1000, # ms
		"event": event_type,
		"run_id": _current_run_id if _current_run_id != "" else "no_run_id",
		"version": TELEMETRY_VERSION,
		"build": "0.5.0-dev" # Should ideally come from ProjectSettings
	}
	
	# Merge specific event data
	entry.merge(data)
	
	# Write line
	var json_line = JSON.stringify(entry)
	_file_access.store_line(json_line)
	_file_access.flush() # Ensure flush for crash safety

# -------------------------------------------------------------------------
# Event: Run Lifecycle
# -------------------------------------------------------------------------

func log_run_start(seed_val: int, character: String, difficulty: int, deck: Array, relics: Array, sigils: Array) -> void:
	_current_run_id = "run_%d_%d" % [Time.get_unix_time_from_system(), randi() % 9999]
	var data = {
		"seed": seed_val,
		"character": character,
		"difficulty": difficulty,
		"starting_deck": deck,
		"starting_relics": relics,
		"starting_sigils": sigils
	}
	_log("run_start", data)

func log_run_end(act: int, floor_num: int, result: String, time_ms: int, deck_size: int, cards_added: int, cards_removed: int, upgrades: int, death_info: Dictionary = {}) -> void:
	var data = {
		"act_reached": act,
		"final_floor": floor_num,
		"result": result, # "win", "loss", "abandon"
		"summary": {
			"time_ms": time_ms,
			"deck_size": deck_size,
			"cards_added": cards_added,
			"cards_removed": cards_removed,
			"upgrades": upgrades
		}
	}
	if not death_info.is_empty():
		data["death"] = death_info
	_log("run_end", data)
	_current_run_id = "" # Clear run ID

# -------------------------------------------------------------------------
# Event: Encounters
# -------------------------------------------------------------------------

func log_room_choice(act: int, floor_num: int, options: Array, picked: Dictionary) -> void:
	# options: array of {type, id}
	# picked: {type, id}
	var data = {
		"act": act,
		"floor": floor_num,
		"options": options,
		"picked": picked
	}
	_log("room_choice", data)

func log_reward_choice(act: int, floor_num: int, reward_type: String, options: Array, picked: Variant) -> void:
	var data = {
		"act": act,
		"floor": floor_num,
		"reward_type": reward_type,
		"options": options,
		"picked": picked
	}
	_log("reward_choice", data)

func log_combat_start(fight_id: String, fight_type: String, act: int, floor_num: int, enemies: Array, player_state: Dictionary) -> void:
	# TASK 10: Initialize fight aggregator
	_reset_fight_aggregator()
	
	# Populate context
	_fight_agg.fight_id = fight_id
	_fight_agg.act = act
	_fight_agg.node_type = fight_type
	_fight_agg.enemy_archetypes = enemies.map(func(e): return e.get("id", "unknown"))
	_fight_agg.deck_size = player_state.get("deck_size", 0)
	_fight_agg.avg_card_cost = player_state.get("avg_card_cost", 0.0)
	_fight_agg.player_character = player_state.get("character", "growth")
	
	# Get ascension from controller
	var ac = get_node_or_null("/root/AscensionController")
	if ac:
		_fight_agg.ascension = ac.ascension_level
	
	# Capture elite modifiers if elite fight
	if fight_type == "elite":
		for e in enemies:
			var mods = e.get("modifiers", [])
			for m in mods:
				_fight_agg.elite_modifiers.append(m.get("id", "unknown"))
			_fight_agg.modifiers_count += mods.size()
			_fight_agg.elite_hp_start = e.get("max_hp", 0)
	
	var data = {
		"fight_id": fight_id,
		"fight_type": fight_type, # normal, elite, boss
		"act": act,
		"floor": floor_num,
		"enemies": enemies, # Array of {id, max_hp}
		"player_state": player_state # {max_hp, hp, deck_size, relics:[], sigils:[]}
	}
	_log("combat_start", data)

func log_combat_end(fight_id: String, act: int, floor_num: int, result: String, summary: Dictionary) -> void:
	# TASK 10: Finalize fight aggregator and log fight_outcome
	_fight_agg.turns_taken = summary.get("turns", 0)
	_fight_agg.damage_taken_total = summary.get("damage_taken", 0)
	_fight_agg.healing_gained_total = summary.get("healing", 0)
	_fight_agg.block_generated_total = summary.get("block", 0)
	_fight_agg.cards_played_total = summary.get("cards_played", 0)
	_fight_agg.cards_drawn_total = summary.get("cards_drawn", 0)
	
	# Update elite-specific (if summary contains)
	if summary.has("elite_hp_end"):
		_fight_agg.elite_hp_end = summary.elite_hp_end
		_fight_agg.player_hp_at_kill = summary.get("player_hp", 0)
	
	# Boss-specific
	if summary.has("phase_count"):
		_fight_agg.phase_count = summary.phase_count
		_fight_agg.phase_transitions_turns = summary.get("phase_turns", [])
		_fight_agg.boss_healing_total = summary.get("boss_healing", 0)
		if result == "loss":
			_fight_agg.player_death_phase = summary.get("death_phase", 1)
	
	var data = {
		"fight_id": fight_id,
		"act": act,
		"floor": floor_num,
		"result": result, # win/loss/flee
		"fight_outcome": {
			"turns_taken": _fight_agg.turns_taken,
			"damage_taken_total": _fight_agg.damage_taken_total,
			"healing_gained_total": _fight_agg.healing_gained_total,
			"block_generated_total": _fight_agg.block_generated_total,
			"cards_played_total": _fight_agg.cards_played_total,
			"cards_drawn_total": _fight_agg.cards_drawn_total
		},
		"status_applied": {
			"poison": _fight_agg.poison_applied,
			"burn": _fight_agg.burn_applied,
			"sap": _fight_agg.sap_applied,
			"fragile": _fight_agg.fragile_applied,
			"chill": _fight_agg.chill_applied,
			"shock": _fight_agg.shock_applied
		},
		"status_effectiveness": {
			"poison_damage_dealt": _fight_agg.poison_damage_dealt,
			"burn_damage_dealt": _fight_agg.burn_damage_dealt,
			"damage_reduced_by_sap": _fight_agg.damage_reduced_by_sap,
			"damage_reduced_by_chill": _fight_agg.damage_reduced_by_chill,
			"attacks_missed_due_to_shock": _fight_agg.attacks_missed_due_to_shock
		},
		"card_metrics": _fight_agg.card_metrics
	}
	
	# Add elite/boss metrics conditionally
	if _fight_agg.node_type == "elite":
		data["elite_metrics"] = {
			"elite_hp_start": _fight_agg.elite_hp_start,
			"elite_hp_end": _fight_agg.elite_hp_end,
			"modifiers_count": _fight_agg.modifiers_count,
			"modifiers": _fight_agg.elite_modifiers,
			"player_hp_at_kill": _fight_agg.player_hp_at_kill
		}
	elif _fight_agg.node_type == "boss":
		data["boss_metrics"] = {
			"phase_count": _fight_agg.phase_count,
			"phase_transitions_turns": _fight_agg.phase_transitions_turns,
			"boss_healing_total": _fight_agg.boss_healing_total,
			"player_death_phase": _fight_agg.player_death_phase
		}
	
	_log("combat_end", data)

# -------------------------------------------------------------------------
# Event: Turn & Actions
# -------------------------------------------------------------------------

func log_turn_start(fight_id: String, turn_idx: int, side: String, player_snapshot: Dictionary, enemy_snapshots: Array) -> void:
	if side == "player":
		_reset_loop_monitor(player_snapshot.get("energy", 0))
		_fight_agg.turns_taken = turn_idx # Track current turn
		
	var data = {
		"fight_id": fight_id,
		"turn": turn_idx,
		"side": side,
		"player_snapshot": player_snapshot,
		"enemy_snapshots": enemy_snapshots
	}
	_log("turn_start", data)

func log_card_play(fight_id: String, turn_idx: int, card_id: String, upgraded: bool, cost: int, target: String, delta: Dictionary) -> void:
	# TASK 10: Aggregate card metrics
	_fight_agg.cards_played_total += 1
	_fight_agg.energy_generated_total += delta.get("energy", 0)
	_fight_agg.block_generated_total += delta.get("block", 0)
	
	# Per-card metrics
	if not _fight_agg.card_metrics.has(card_id):
		_fight_agg.card_metrics[card_id] = {
			"times_drawn": 0,
			"times_played": 0,
			"energy_spent": 0,
			"damage_dealt": 0,
			"block_generated": 0,
			"status_applied_total": 0
		}
	var cm = _fight_agg.card_metrics[card_id]
	cm.times_played += 1
	cm.energy_spent += cost
	cm.damage_dealt += delta.get("damage", 0)
	cm.block_generated += delta.get("block", 0)
	
	var data = {
		"fight_id": fight_id,
		"turn": turn_idx,
		"card_id": card_id,
		"upgraded": upgraded,
		"cost_paid": cost,
		"target": target, # none|self|enemy:X|all
		"delta": delta # {damage, block, energy, draw, seeds, runes...}
	}
	_log("card_play", data)
	
	# Update Loop Monitor
	_update_loop_monitor(card_id, cost, delta)
	# Check for flags AFTER update
	_check_degenerate_flags(fight_id, turn_idx)

func log_enemy_intent(fight_id: String, turn_idx: int, enemy_id: String, intent: Dictionary) -> void:
	var data = {
		"fight_id": fight_id,
		"turn": turn_idx,
		"enemy_id": enemy_id,
		"intent": intent # {type, damage, hits, block, statuses:[]}
	}
	_log("enemy_intent", data)

func log_status_apply(fight_id: String, turn_idx: int, source: Dictionary, to: Dictionary, status: String, amount: int) -> void:
	var data = {
		"fight_id": fight_id,
		"turn": turn_idx,
		"source": source, # {type, id}
		"to": to, # {type, enemy_id}
		"status": status,
		"amount": amount
	}
	_log("status_apply", data)

func log_status_remove(fight_id: String, turn_idx: int, source: Dictionary, from_target: Dictionary, status: String, amount: int) -> void:
	var data = {
		"fight_id": fight_id,
		"turn": turn_idx,
		"source": source,
		"from": from_target,
		"status": status,
		"amount": amount
	}
	_log("status_remove", data)
	
func on_card_played(type: String, cost: int) -> void:
	# Deprecated listener, keeping for backward compatibility if any signal usage exists
	pass

# -------------------------------------------------------------------------
# Degenerate Loop Detection
# -------------------------------------------------------------------------

func _reset_loop_monitor(start_energy: int) -> void:
	_loop_monitor = {
		"cards_played": 0,
		"unique_cards_played": {}, # {card_id: count}
		"same_card_max_plays": 0,
		"energy_start": start_energy,
		"energy_end": start_energy,
		"energy_gained": 0,
		"energy_spent": 0,
		"cards_drawn": 0,
		"cards_created": 0,
		"exhausted": 0,
		"last_12_cards_sequence": [],
		"loop_signature_hashes": []
	}
	_loop_flags_triggered_this_turn.clear()

func _update_loop_monitor(card_id: String, cost: int, delta: Dictionary) -> void:
	var m = _loop_monitor
	m.cards_played += 1
	m.energy_spent += cost
	
	if delta.get("energy", 0) > 0:
		m.energy_gained += delta.get("energy", 0)
	
	m.cards_drawn += delta.get("draw", 0)
	# m.cards_created via other hooks if needed
	
	# Update unique counts
	if not m.unique_cards_played.has(card_id):
		m.unique_cards_played[card_id] = 0
	m.unique_cards_played[card_id] += 1
	
	if m.unique_cards_played[card_id] > m.same_card_max_plays:
		m.same_card_max_plays = m.unique_cards_played[card_id]
	
	# Update Rolling Sequence
	m.last_12_cards_sequence.append(card_id)
	if m.last_12_cards_sequence.size() > 12:
		m.last_12_cards_sequence.pop_front()
		
	# Update Hash (simple string concat hash for "last 8")
	if m.last_12_cards_sequence.size() >= 8:
		var slice = m.last_12_cards_sequence.slice(-8)
		var s_str = "".join(slice)
		var h = s_str.hash()
		m.loop_signature_hashes.append(h)
		if m.loop_signature_hashes.size() > 100: m.loop_signature_hashes.pop_front()

func _check_degenerate_flags(fight_id: String, turn_idx: int) -> void:
	var m = _loop_monitor
	var net_energy = (m.energy_start + m.energy_gained - m.energy_spent) - m.energy_start
	
	var flags_hit = []
	
	# D1) Hard Flags
	if m.cards_played >= 16: flags_hit.append("hard_cards")
	if m.same_card_max_plays >= 6: flags_hit.append("hard_same")
	if m.cards_drawn >= 14: flags_hit.append("hard_draw")
	if net_energy >= 5: flags_hit.append("hard_net_nrg")
	if m.energy_gained >= 8: flags_hit.append("hard_gain_nrg")
	
	# D2) Soft Flags (need 2)
	var soft_count = 0
	if m.cards_played >= 12: soft_count += 1
	if m.same_card_max_plays >= 4: soft_count += 1
	if m.cards_drawn >= 10: soft_count += 1
	if net_energy >= 3: soft_count += 1
	if m.energy_gained >= 5: soft_count += 1
	if soft_count >= 2: flags_hit.append("soft_combo")
	
	# D3) Loop Repetition
	# 3 repeats of same hash in same turn?
	if m.loop_signature_hashes.size() >= 3:
		var last_h = m.loop_signature_hashes[-1]
		var match_count = 0
		for h in m.loop_signature_hashes:
			if h == last_h: match_count += 1
		if match_count >= 3:
			flags_hit.append("loop_repetitive")
			
	# If any NEW flags, log
	for f in flags_hit:
		if not f in _loop_flags_triggered_this_turn:
			_loop_flags_triggered_this_turn.append(f)
			_log_degenerate_flag(fight_id, turn_idx, f, m)

func _log_degenerate_flag(fight_id: String, turn_idx: int, reason: String, monitor: Dictionary) -> void:
	var data = {
		"fight_id": fight_id,
		"turn": turn_idx,
		"reason": reason,
		"snapshot": {
			"cards_played": monitor.cards_played,
			"net_energy": (monitor.energy_start + monitor.energy_gained - monitor.energy_spent) - monitor.energy_start,
			"drawn": monitor.cards_drawn,
			"same_card_max": monitor.same_card_max_plays,
			"sequence": monitor.last_12_cards_sequence.slice(-5) # Last 5 for context
		}
	}
	_log("degenerate_flag", data)
