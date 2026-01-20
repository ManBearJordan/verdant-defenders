extends Control

# GameOverScreen.gd

@onready var title_lbl = $Panel/VBox/Title
@onready var stats_container = $Panel/VBox/Stats
@onready var menu_btn = $Panel/VBox/MenuBtn
@onready var restart_btn = $Panel/VBox/RestartBtn

func _ready() -> void:
	_populate()
	menu_btn.pressed.connect(_on_menu)
	restart_btn.pressed.connect(_on_restart)

func _populate() -> void:
	var rc = get_node_or_null("/root/RunController")
	if not rc: return
	
	var m = rc.run_metrics
	
	# Title
	# If we came here from 'battle_defeat', it's Game Over.
	# If we came from 'run_completed' (future), it's Victory.
	# For now, assume Defeat defaulting.
	title_lbl.text = "RUN ENDED"
	if rc.player_hp <= 0:
		title_lbl.text = "DEFEAT"
		title_lbl.add_theme_color_override("font_color", Color.RED)
	else:
		title_lbl.text = "VICTORY" # If triggered otherwise
		title_lbl.add_theme_color_override("font_color", Color.GREEN)
		
	# Stats
	var txt = ""
	txt += "Act: %d - Floor: %d\n" % [rc.current_act, rc.current_floor]
	txt += "Rooms Cleared: %d\n" % [m.get("rooms_cleared", 0)]
	txt += "Elites Defeated: %d\n" % [m.get("elites_defeated", 0)]
	txt += "\n"
	txt += "Verdant Shards Earned: %d\n" % [m.get("shards_earned", 0)]
	txt += "Cards Drafted: %d\n" % [m.get("cards_added", 0)]
	txt += "Cards Purged: %d\n" % [m.get("cards_removed", 0)]
	
	var lbl = Label.new()
	lbl.text = txt
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_container.add_child(lbl)

func _on_menu() -> void:
	get_tree().change_scene_to_file("res://Scenes/UI/MainMenu.tscn")

func _on_restart() -> void:
	var rc = get_node_or_null("/root/RunController")
	if rc:
		rc.start_new_run(rc.current_class_id)
		# Start new run switches to Map automatically
