extends Control


@onready var botao_menu = $BotaoMenu
@onready var botao_jogar_novamente = $BotaoJogarNovamente


func _ready():

	botao_menu.pressed.connect(
		_on_botao_menu_pressed
	)

	botao_jogar_novamente.pressed.connect(
		_on_botao_jogar_novamente_pressed
	)


func _on_botao_menu_pressed():

	print("Voltando para o menu...")

	get_tree().change_scene_to_file(
		"res://scenes/menu/menu.tscn"
	)


func _on_botao_jogar_novamente_pressed():

	print("Começando uma nova partida...")

	get_tree().change_scene_to_file(
		"res://scenes/fase5_erroLexico/niveis/nivel1.tscn"
	)
