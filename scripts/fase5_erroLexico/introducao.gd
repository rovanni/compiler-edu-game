extends Control


@onready var botao_jogar = $BotaoJogar


func _ready():

	botao_jogar.pressed.connect(_on_botao_jogar_pressed)


func _on_botao_jogar_pressed():

	get_tree().change_scene_to_file(
		"res://scenes/fase5_erroLexico/niveis/nivel1.tscn"
	)
