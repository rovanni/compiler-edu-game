extends Node2D

const HUD_SCENE := preload("res://scenes/common/game_hud.tscn")
var tokens_coletados := 0
var total_tokens := 0
var phase_checkpoint := 0
var paused := false
var completed := false
var hud

func _ready() -> void:
	if GameManager.current_phase_id != 1:
		if GameManager.session_active: GameManager.begin_phase(1)
		else: GameManager.start_new_session(1)
	phase_checkpoint = GameManager.create_checkpoint()
	$Jogador.set_spawn($Jogador.global_position)
	$Jogador.fell_out.connect(_on_espinho_atingido)
	total_tokens = $Tokens.get_child_count()
	for token in $Tokens.get_children(): token.coletado.connect(_on_token_coletado)
	$Espinho2.atingido.connect(_on_espinho_atingido)
	$Espinho.atingido.connect(_on_espinho_atingido)
	GameManager.game_over.connect(_on_game_over)
	criar_hud()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		if paused: _retomar()
		elif not completed: _pausar()
		get_viewport().set_input_as_handled()

func _on_token_coletado() -> void:
	if paused or completed: return
	tokens_coletados += 1
	var awarded := GameManager.register_correct_action()
	hud.set_feedback("Token coletado! +%d pontos" % awarded, Color("73e6a2"))
	if tokens_coletados == total_tokens: vencer()

func _on_espinho_atingido() -> void:
	if paused or completed: return
	var remaining := GameManager.register_mistake("perigo", true)
	if remaining > 0:
		GameManager.rollback_to(phase_checkpoint)
		resetar_fase()
		hud.set_feedback("Cuidado! Você perdeu uma vida e deve recolher os tokens novamente.", Color("ff7b7b"))

func resetar_fase() -> void:
	$Jogador.respawn()
	tokens_coletados = 0
	for token in $Tokens.get_children(): token.resetar()

func vencer() -> void:
	if completed: return
	completed = true
	$Jogador.set_controls_enabled(false)
	var bonus := GameManager.complete_phase(1, not GameManager.phase_had_mistake)
	hud.show_completion("FASE 1 CONCLUÍDA!", "Todos os tokens foram coletados. +%d pontos de conclusão.\n\nAgora siga para o Vale do Scanner e organize os tokens na ordem do código." % bonus, true)

func criar_hud() -> void:
	hud = HUD_SCENE.instantiate()
	add_child(hud)
	hud.configure_phase("FASE 1 - REINO DOS TOKENS", "COLETE OS TOKENS E EVITE OS ESPINHOS", false)
	hud.hide_scanner_interface()
	hud.pause_requested.connect(_pausar)
	hud.resume_requested.connect(_retomar)
	hud.menu_confirmed.connect(_voltar_menu)
	hud.retry_requested.connect(_tentar_novamente)
	hud.next_requested.connect(_ir_para_fase_2)

func _pausar() -> void:
	if paused or completed: return
	paused = true
	$Jogador.set_controls_enabled(false)
	hud.show_pause()

func _retomar() -> void:
	if not paused: return
	paused = false
	$Jogador.set_controls_enabled(true)

func _on_game_over(phase_id: int) -> void:
	if phase_id != 1: return
	paused = true
	$Jogador.set_controls_enabled(false)
	hud.show_game_over()

func _tentar_novamente() -> void:
	GameManager.rollback_to(phase_checkpoint)
	GameManager.reset_lives()
	GameManager.begin_phase(1)
	get_tree().reload_current_scene()

func _ir_para_fase_2() -> void:
	GameManager.begin_phase(2)
	get_tree().change_scene_to_file("res://scenes/fase2_scanner/main.tscn")

func _voltar_menu() -> void:
	if not completed: GameManager.abandon_phase()
	get_tree().change_scene_to_file("res://scenes/menu/menu.tscn")
