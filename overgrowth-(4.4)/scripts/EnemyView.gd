extends Control
class_name EnemyView

@onready var _name: Label        = %NameLabel
@onready var _hp: Label          = %HpLabel
@onready var _intent: Label      = %IntentLabel
@onready var _sprite: TextureRect= %Sprite
@onready var _highlight: ColorRect = %Highlight
@onready var _status_label: Label = get_node_or_null("StatusLabel")

# UX Components (Dynamically added)
var _passive_row = null
var _meter = null
var _intent_badge_label = null

var unit: EnemyUnit = null

const ENEMY_TEX_MAP := {
	"sproutling": "res://Art/characters/sproutling.png",
	"spore_puffer": "res://Art/characters/spore_puffer.png",
	"vine_shooter": "res://Art/characters/vine_shooter.png",
	"bark_shield": "res://Art/characters/bark_shield.png",
	"sap_warden": "res://Art/characters/sap_warden.png",
}

func _safe_load_tex(path: String) -> Texture2D:
	if path != "" and ResourceLoader.exists(path):
		var tex := load(path)
		if tex is Texture2D:
			return tex
	return null

func setup(e: EnemyUnit) -> void:
	unit = e
	_name.text = e.display_name
	_hp.text   = "HP %s/%s" % [e.current_hp, e.max_hp]
	_intent.text = _format_intent(e.intent)
	
	_update_status_display()
	_update_visuals()
	_update_ux_components(e)

func _update_ux_components(e: EnemyUnit) -> void:
	# 1. Passive Row
	if _passive_row == null:
		var script = load("res://scripts/BossPassiveRow.gd")
		if script:
			_passive_row = script.new()
			add_child(_passive_row)
			_passive_row.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
			_passive_row.position.y += 180 # Below sprite
			_passive_row.custom_minimum_size = Vector2(160, 40)
			_passive_row.alignment = BoxContainer.ALIGNMENT_CENTER

	# Passives Population
	if _passive_row:
		# Clear previous?
		for c in _passive_row.get_children():
			c.queue_free()
			
		# Populate based on ID
		if e.display_name == "World Reclaimer":
			_passive_row.add_passive("HARVEST", "HARVEST", "End of your turn: if Seeds >= 6, consume 5, heal 35, gain +2 Strength.")
		elif e.display_name == "Eternal Arbiter":
			_passive_row.add_passive("CAP", "EQUILIBRIUM", "Poison tick to this boss is capped at 24 per enemy turn.")
		elif e.display_name == "Chronoshard":
			_passive_row.add_passive("LOCK", "LOCK", "You can play up to 5 cards per turn.")

	# Elite Modifiers
	if _passive_row:
		for m in e.modifiers:
			_passive_row.add_passive(m.name.to_upper(), m.name, m.get("desc", ""))
			
	# Threshold Meter (Poison Cap for Arbiter)
	if e.display_name == "Eternal Arbiter":
		if not _meter:
			var m_script = load("res://scripts/ThresholdMeter.gd")
            if m_script:
                _meter = m_script.new()
                add_child(_meter)
                _meter.custom_minimum_size = Vector2(140, 20)
                _meter.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
                _meter.position.y += 240 # Offset below
                
        # Status "poison_tick_preview"? 
        # We need to know pending poison damage.
        # EnemyUnit doesn't calculate it. CombatSystem does.
        # But we can approximate: Poison stacks = damage.
        var p = e.get_status("poison")
        if _meter: _meter.setup(p, 24, 24)
        
    # Intent Badge
    if _intent_badge_label:
        _intent_badge_label.text = ""
        # Check patterns for special intents
        # Reclaimer: Harvest if Seeds >= 6?
        # Arbiter: Purge check?
        var phase_intent = e.intent.get("name", "")
        if "purge" in phase_intent.to_lower():
            _intent_badge_label.text = "PURGE"
        elif "special" in phase_intent.to_lower():
            _intent_badge_label.text = "AOE" # Chronoshard
            
        # Arbiter Purge Window check via custom_data
        if e.display_name == "Eternal Arbiter":
             var turns = e.custom_data.get("turns_active", 0)
             if (turns + 1) % 3 == 0: # Next turn is 3, 6...
                 pass # Intent badge handled above if intent name matches?
                 # Actually intent is set at START of player turn for NEXT enemy turn.
                 # So e.intent is valid.
                 pass

func _update_visuals() -> void:
	# Art
	var id = unit.id
	var path = unit.resource.texture_path
	if path == "": 
		path = ENEMY_TEX_MAP.get(id, "res://Art/characters/%s.png" % id)
		
	var tex = _safe_load_tex(path)
	if tex:
		_sprite.texture = tex
	else:
		_sprite.texture = load("res://icon.svg")

	# Logic for blocking overlay or similar could go here

func _format_intent(intent: Dictionary) -> String:
	if intent.is_empty(): return ""
	match intent.get("type",""):
		"attack": return "⚔️ %d" % int(intent.get("value",0))
		"block":  return "🛡️ %d" % int(intent.get("value",0))
		"buff":   return "💪"
		"debuff": return "💀"
		"heal":   return "💚"
		"judgment": return "⚖️ !"
		"strategic": return "👁️"
		"unknown":   return "❓"
		_:        return intent.get("type","")

func _process(_delta: float) -> void:
	# Continuous update of HP/Status if needed, or rely on setup/refresh calls
	# GameUI calls setup() continuously on refresh loop
	pass

func _ready() -> void:
	if self is Control:
		mouse_filter = Control.MOUSE_FILTER_STOP
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	custom_minimum_size = Vector2(160, 220)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var targeting_system: Node = get_node_or_null("/root/TargetingSystem")
		if targeting_system and targeting_system.has_method("set_target"):
			targeting_system.set_target(self)

func set_highlight(on: bool) -> void:
	if _highlight:
		_highlight.visible = on
		if on: _highlight.color = Color(1, 0.84, 0, 0.4)
	
	var tw = create_tween()
	var target_scale = Vector2(1.15, 1.15) if on else Vector2(1.0, 1.0)
	tw.tween_property(self, "scale", target_scale, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _update_status_display() -> void:
	if not _status_label or not unit: return
	
	var status_text: String = ""
	var statuses = unit.statuses
	
	var status_map = {
		"seeded":     {"icon": "🌱", "label": "Seeded"},
		"poison":     {"icon": "☠️", "label": "Poison"},
		"weak":       {"icon": "💔", "label": "Weak"},
		"vulnerable": {"icon": "🛡️❌", "label": "Vuln"},
		"burn":       {"icon": "🔥", "label": "Burn"},
		"shock":      {"icon": "⚡", "label": "Shock"},
		"chill":      {"icon": "❄️", "label": "Chill"},
		"no_block":   {"icon": "🚫", "label": "No Block"}
	}
	
	for s_name in statuses.keys():
		var val = int(statuses[s_name])
		if val > 0:
			var info = status_map.get(s_name, {"icon": "❓", "label": s_name.capitalize()})
			status_text += "%s %s x%d\n" % [info.icon, info.label, val]
	
	_status_label.text = status_text.strip_edges()
	_status_label.visible = not status_text.is_empty()

func get_current_hp() -> int:
	return unit.current_hp if unit else 0
