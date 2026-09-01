extends Node2D

const HUD_SCENE := preload("res://scenes/common/game_hud.tscn")

@export var numero_nivel: int = 1

var monstros_invalidos_restantes := 0
var portal_aberto := false
var trocando_nivel := false
var paused := false
var phase_checkpoint := 0
var hud: CanvasLayer

@onready var jogador = $Jogador
@onready var monstros = $Monstros
@onready var portal = $Cenario/Portal

func _ready():
	if GameManager.current_phase_id != 5:
		if GameManager.session_active:
			GameManager.begin_phase(5)
		else:
			GameManager.start_new_session(5)

	phase_checkpoint = GameManager.create_checkpoint()

	# Oculta o HUD antigo (corações estáticos) se existir na cena
	if has_node("CanvasLayer"):
		$CanvasLayer.visible = false

	criar_hud()

	for monstro in monstros.get_children():
		if monstro.has_signal("monstro_morreu"):
			monstros_invalidos_restantes += 1
			monstro.monstro_morreu.connect(_on_monstro_invalido_morreu)

	jogador.perdeu_coracao.connect(_on_jogador_perdeu_coracao)
	jogador.morreu.connect(_on_jogador_morreu)

	portal.body_entered.connect(_on_portal_body_entered)
	portal.monitoring = false

	GameManager.game_over.connect(_on_game_over)
	mostrar_inicio_nivel()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		if paused:
			_retomar()
		else:
			_pausar()
		get_viewport().set_input_as_handled()

func criar_hud() -> void:
	hud = HUD_SCENE.instantiate()
	add_child(hud)
	hud.configure_phase(
		"FASE 5 - CASTELO DOS ERROS LÉXICOS",
		"NÍVEL %d: ELIMINE APENAS MONSTROS COM CARACTERES INVÁLIDOS" % numero_nivel,
		false
	)
	hud.hide_scanner_interface()

	hud.pause_requested.connect(_pausar)
	hud.resume_requested.connect(_retomar)
	hud.menu_confirmed.connect(_voltar_menu)
	hud.retry_requested.connect(_tentar_novamente)
	hud.next_requested.connect(_proximo_nivel)

func mostrar_inicio_nivel() -> void:
	hud.show_area_title("NÍVEL %d - CASTELO DOS ERROS" % numero_nivel)
	SoundManager.play_portal()

func _on_monstro_invalido_morreu():
	monstros_invalidos_restantes -= 1
	hud.set_feedback("Monstro inválido eliminado! Restantes: %d" % monstros_invalidos_restantes, Color("73e6a2"))

	if monstros_invalidos_restantes <= 0:
		abrir_portal()

func abrir_portal():
	if portal_aberto:
		return
	portal_aberto = true
	portal.set_deferred("monitoring", true)
	SoundManager.play_portal()
	hud.set_feedback("Portal liberado! Entre no portal para avançar.", Color("ffc43d"))

func _on_portal_body_entered(body):
	if not portal_aberto or body != jogador or trocando_nivel or paused:
		return
	trocando_nivel = true
	SoundManager.play_portal()
	call_deferred("_proximo_nivel")

func _on_jogador_perdeu_coracao():
	var remaining := GameManager.register_mistake("dano", true)
	if remaining > 0:
		hud.set_feedback("Cuidado! Você perdeu uma vida.", Color("ff7b7b"))

func _on_jogador_morreu():
	Global.nivel_game_over = numero_nivel
	paused = true
	if is_instance_valid(jogador) and jogador.has_method("set_controls_enabled"):
		jogador.set_controls_enabled(false)
	hud.show_game_over()

func _on_game_over(phase_id: int) -> void:
	if phase_id != 5:
		return
	_on_jogador_morreu()

func _pausar() -> void:
	if paused:
		return
	paused = true
	if is_instance_valid(jogador) and jogador.has_method("set_controls_enabled"):
		jogador.set_controls_enabled(false)
	hud.show_pause()

func _retomar() -> void:
	if not paused:
		return
	paused = false
	if is_instance_valid(jogador) and jogador.has_method("set_controls_enabled"):
		jogador.set_controls_enabled(true)

func _voltar_menu() -> void:
	GameManager.abandon_phase()
	get_tree().change_scene_to_file("res://scenes/menu/menu.tscn")

func _tentar_novamente() -> void:
	GameManager.rollback_to(phase_checkpoint)
	GameManager.reset_lives()
	GameManager.begin_phase(5)
	get_tree().reload_current_scene()

func _proximo_nivel():
	match numero_nivel:
		1:
			get_tree().change_scene_to_file("res://scenes/fase5_erroLexico/niveis/nivel2.tscn")
		2:
			get_tree().change_scene_to_file("res://scenes/fase5_erroLexico/niveis/nivel3.tscn")
		3:
			get_tree().change_scene_to_file("res://scenes/fase5_erroLexico/niveis/nivel4.tscn")
		4:
			get_tree().change_scene_to_file("res://scenes/fase5_erroLexico/niveis/nivel5.tscn")
		5:
			var bonus := GameManager.complete_phase(5, not GameManager.phase_had_mistake)
			hud.show_completion(
				"FASE 5 CONCLUÍDA!",
				"Você dominou o Castelo dos Erros Léxicos! +%d pontos obtidos." % bonus,
				false
			)
