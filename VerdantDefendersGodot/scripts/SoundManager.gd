extends Node

# SoundManager - Global Audio Management
# Uses AudioStreamPlayers for SFX and Music

var _bgm_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []

var volumes := {
	"master": 1.0,
	"music": 0.8,
	"sfx": 1.0
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_audio()

func _setup_audio() -> void:
	# Music Player
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = "Music"
	add_child(_bgm_player)
	
	# SFX Pool
	for i in range(10):
		var p = AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_sfx_players.append(p)
	
	# Assume default bus layout exists or create it
	# In Godot 4 script, we can't easily create layout at runtime if not in project.godot
	# But we can push volume via Db.

func play_music(stream: AudioStream) -> void:
	if _bgm_player.stream == stream and _bgm_player.playing:
		return
	
	_bgm_player.stream = stream
	_bgm_player.play()

func play_sfx(stream_path: String, random_pitch: bool = true) -> void:
	if not ResourceLoader.exists(stream_path):
		return # Silent fail
		
	var stream = load(stream_path)
	if not stream: return
	
	for p in _sfx_players:
		if not p.playing:
			p.stream = stream
			if random_pitch:
				p.pitch_scale = randf_range(0.9, 1.1)
			else:
				p.pitch_scale = 1.0
			p.play()
			return

func set_volume(bus_name: String, value: float) -> void:
	volumes[bus_name] = clamp(value, 0.0, 1.0)
	var idx = AudioServer.get_bus_index(bus_name.capitalize())
	if idx != -1:
		AudioServer.set_bus_volume_db(idx, linear_to_db(value))
	
	# Mute if 0
	if idx != -1:
		AudioServer.set_bus_mute(idx, value <= 0.0)

# Helpers for common sounds
func play_button_click() -> void:
	play_sfx("res://Audio/UI/click.wav")

func play_card_draw() -> void:
	play_sfx("res://Audio/Cards/draw.wav")
