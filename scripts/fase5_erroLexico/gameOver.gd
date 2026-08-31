extends Control


@onready var botao_tentar_novamente = $BotaoTentarNovamente


func _ready():

	botao_tentar_novamente.pressed.connect(
		_on_botao_tentar_novamente_pressed
	)


func _on_botao_tentar_novamente_pressed():

	print(
		"Voltando para o nível ",
		Global.nivel_game_over
	)


	match Global.nivel_game_over:

		1:
			get_tree().change_scene_to_file(
				"res://scenes/fase5_erroLexico/niveis/nivel1.tscn"
			)

		2:
			get_tree().change_scene_to_file(
				"res://scenes/fase5_erroLexico/niveis/nivel2.tscn"
			)

		3:
			get_tree().change_scene_to_file(
				"res://scenes/fase5_erroLexico/niveis/nivel3.tscn"
			)

		4:
			get_tree().change_scene_to_file(
				"res://scenes/fase5_erroLexico/niveis/nivel4.tscn"
			)

		5:
			get_tree().change_scene_to_file(
				"res://scenes/fase5_erroLexico/niveis/nivel5.tscn"
			)
