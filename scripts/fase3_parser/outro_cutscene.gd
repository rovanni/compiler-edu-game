extends Control

@onready var video_player: VideoStreamPlayer = $VideoStreamPlayer
@onready var skip_button: Button = $SkipButton

func _ready() -> void:
	if video_player:
		video_player.finished.connect(_on_video_finished)
		
	if skip_button:
		skip_button.pressed.connect(_on_skip_button_pressed)

func _on_video_finished() -> void:
	_return_to_menu()

func _on_skip_button_pressed() -> void:
	_return_to_menu()

func _return_to_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/menu.tscn")
