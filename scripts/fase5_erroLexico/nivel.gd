extends Node2D

@export var numero_nivel: int = 1

var monstros_invalidos_restantes := 0
var portal_aberto := false
var trocando_nivel := false

@onready var jogador = $Jogador
@onready var monstros = $Monstros
@onready var portal = $Cenario/Portal

@onready var coracao1 = $CanvasLayer/HUD/Coracao1
@onready var coracao2 = $CanvasLayer/HUD/Coracao2
@onready var coracao3 = $CanvasLayer/HUD/Coracao3


func _ready():

	for monstro in monstros.get_children():

		if monstro.has_signal("monstro_morreu"):

			monstros_invalidos_restantes += 1

			monstro.monstro_morreu.connect(
				_on_monstro_invalido_morreu
			)


	jogador.perdeu_coracao.connect(
		_on_jogador_perdeu_coracao
	)

	jogador.morreu.connect(
		_on_jogador_morreu
	)

	portal.body_entered.connect(
		_on_portal_body_entered
	)

	portal.monitoring = false

	atualizar_coracoes()


func _on_monstro_invalido_morreu():

	monstros_invalidos_restantes -= 1

	if monstros_invalidos_restantes <= 0:

		abrir_portal()

func abrir_portal():

	if portal_aberto:
		return


	portal_aberto = true


	portal.set_deferred("monitoring", true)

func _on_portal_body_entered(body):

	if not portal_aberto:
		return

	if body != jogador:
		return

	if trocando_nivel:
		return

	trocando_nivel = true

	call_deferred("proximo_nivel")

func _on_jogador_perdeu_coracao():
	atualizar_coracoes()

func atualizar_coracoes():

	if jogador.coracoes >= 1:
		coracao1.visible = true
	else:
		coracao1.visible = false


	if jogador.coracoes >= 2:
		coracao2.visible = true
	else:
		coracao2.visible = false


	if jogador.coracoes >= 3:
		coracao3.visible = true
	else:
		coracao3.visible = false

func _on_jogador_morreu():

	Global.nivel_game_over = numero_nivel

	call_deferred("_abrir_game_over")
	
func _abrir_game_over():

	get_tree().change_scene_to_file(
		"res://scenes/fase5_erroLexico/gameOver.tscn"
	)

func proximo_nivel():

	match numero_nivel:

		1:
			get_tree().change_scene_to_file(
				"res://scenes/fase5_erroLexico/niveis/nivel2.tscn"
			)

		2:
			get_tree().change_scene_to_file(
				"res://scenes/fase5_erroLexico/niveis/nivel3.tscn"
			)

		3:
			get_tree().change_scene_to_file(
				"res://scenes/fase5_erroLexico/niveis/nivel4.tscn"
			)

		4:
			get_tree().change_scene_to_file(
				"res://scenes/fase5_erroLexico/niveis/nivel5.tscn"
			)

		5:
			get_tree().change_scene_to_file(
				"res://scenes/fase5_erroLexico/conclusao.tscn"
			)
