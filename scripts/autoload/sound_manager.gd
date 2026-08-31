extends Node

const ERROR_SOUND := preload("res://assets/audio/error_003.ogg")
const CONFIRMATION_SOUND := preload("res://assets/audio/confirmation_002.ogg")
const PLAYER_HURT_SOUND := preload("res://assets/audio/playerhurt.wav")
const JUMP_SOUND_PATH := "res://assets/audio/jump_edr.mp3"
const LIFT_SOUND := preload("res://assets/audio/lift.wav")
const FOOTSTEP_SOUND := preload("res://assets/audio/footstep09.ogg")
const PORTAL_SOUND_PATH := "res://assets/audio/portal_beep.mp3"

var _players: Dictionary = {}
var _last_footstep_time := -1.0
var _jump_sound: AudioStream
var _portal_sound: AudioStream

func _ready() -> void:
	_jump_sound = AudioStreamMP3.load_from_file(JUMP_SOUND_PATH)
	_portal_sound = AudioStreamMP3.load_from_file(PORTAL_SOUND_PATH)
	for key in [&"error", &"confirmation", &"hurt", &"jump", &"lift", &"footstep", &"portal"]:
		var player := AudioStreamPlayer.new()
		player.name = "%sPlayer" % str(key).capitalize()
		add_child(player)
		_players[key] = player

func _play(key: StringName, stream: AudioStream) -> void:
	var player: AudioStreamPlayer = _players.get(key)
	if player:
		player.stream = stream
		player.play()

func play_error() -> void: _play(&"error", ERROR_SOUND)
func play_confirmation() -> void: _play(&"confirmation", CONFIRMATION_SOUND)
func play_hurt() -> void: _play(&"hurt", PLAYER_HURT_SOUND)
func play_jump() -> void: _play(&"jump", _jump_sound)
func play_lift() -> void: _play(&"lift", LIFT_SOUND)
func play_portal() -> void:
	_play(&"portal", _portal_sound)
	var timer := get_tree().create_timer(2.0)
	timer.timeout.connect(_stop_portal_sound)

func _stop_portal_sound() -> void:
	var player: AudioStreamPlayer = _players.get(&"portal")
	if player and player.playing:
		player.stop()

func play_footstep() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_footstep_time < 0.28:
		return
	_last_footstep_time = now
	_play(&"footstep", FOOTSTEP_SOUND)
