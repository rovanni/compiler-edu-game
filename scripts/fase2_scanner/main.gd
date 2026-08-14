extends Node2D

enum PhaseState { INTRO, PLAYING, PAUSED, PORTAL_READY, TRANSITION, GAME_OVER, COMPLETE }
const PLAYER_SCENE := preload("res://scenes/common/player.tscn")
const HUD_SCENE := preload("res://scenes/common/game_hud.tscn")
const TOKEN_SCENE := preload("res://scenes/fase2_scanner/scanner_token.tscn")
const PORTAL_SCENE := preload("res://scenes/fase2_scanner/portal.tscn")
const BACKGROUND_TEXTURE := preload("res://assets/fase1_tokens/Background.png")
const TERRAIN_TEXTURE := preload("res://assets/fase1_tokens/Background2.png")

var challenges: Array[Dictionary] = ScannerData.challenges()
var challenge_index := 0
var challenge_checkpoint := 0
var time_remaining := 0.0
var state := PhaseState.INTRO
var state_before_pause := PhaseState.PLAYING
var sequence := ScannerSequence.new()
var spawned_tokens: Array = []
var invulnerable := false
var player
var hud
var portal
var token_container: Node2D

func _ready() -> void:
	if GameManager.current_phase_id != 2:
		if GameManager.session_active: GameManager.begin_phase(2)
		else: GameManager.start_new_session(2)
	_build_world()
	_build_hud()
	GameManager.game_over.connect(_on_game_over)
	_load_challenge(0)

func _process(delta: float) -> void:
	if state != PhaseState.PLAYING: return
	time_remaining = maxf(time_remaining - delta, 0.0)
	hud.set_timer(time_remaining)
	if time_remaining <= 0.0: _handle_timeout()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		if state == PhaseState.PAUSED: _resume_game()
		elif state == PhaseState.PLAYING or state == PhaseState.PORTAL_READY: _pause_game()
		get_viewport().set_input_as_handled()

func _build_world() -> void:
	var background := Sprite2D.new()
	background.texture = BACKGROUND_TEXTURE
	background.position = Vector2(640, 360)
	background.scale = Vector2(1280.0 / 1672.0, 720.0 / 941.0)
	background.z_index = -20
	add_child(background)
	var terrain := Sprite2D.new()
	terrain.texture = TERRAIN_TEXTURE
	terrain.position = Vector2(640, 360)
	terrain.scale = Vector2(1280.0 / 1536.0, 720.0 / 1024.0)
	terrain.z_index = -10
	add_child(terrain)
	# Colisões medidas sobre o terreno já escalado para 1280 × 720.
	_create_platform(Vector2(155, 581), Vector2(310, 80), false)
	_create_platform(Vector2(622, 575), Vector2(336, 80), false)
	_create_platform(Vector2(855, 598), Vector2(170, 244), false)
	_create_platform(Vector2(1177, 624), Vector2(205, 100), false)
	_create_platform(Vector2(350, 308), Vector2(210, 24), true)
	_create_platform(Vector2(649, 217), Vector2(202, 24), true)
	_create_platform(Vector2(879, 366), Vector2(172, 24), true)
	_create_platform(Vector2(1190, 337), Vector2(180, 24), true)
	_create_platform(Vector2(-20, 360), Vector2(40, 720), false)
	_create_platform(Vector2(1300, 360), Vector2(40, 720), false)
	_create_hazard(Vector2(381, 568), Vector2(148, 36))
	_create_hazard(Vector2(1007, 568), Vector2(134, 36))
	var scanner_sign := Label.new()
	scanner_sign.position = Vector2(35, 340)
	scanner_sign.size = Vector2(130, 42)
	scanner_sign.text = "SCANNER →"
	scanner_sign.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scanner_sign.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	scanner_sign.add_theme_font_size_override("font_size", 18)
	scanner_sign.add_theme_color_override("font_color", Color("ffc43d"))
	var sign_style := StyleBoxFlat.new()
	sign_style.bg_color = Color("071523")
	sign_style.border_color = Color("42627d")
	sign_style.set_border_width_all(2)
	sign_style.set_corner_radius_all(6)
	scanner_sign.add_theme_stylebox_override("normal", sign_style)
	add_child(scanner_sign)
	token_container = Node2D.new()
	add_child(token_container)
	portal = PORTAL_SCENE.instantiate()
	portal.position = Vector2(1190, 548)
	portal.entered.connect(_on_portal_entered)
	add_child(portal)
	player = PLAYER_SCENE.instantiate()
	player.position = Vector2(90, 522)
	add_child(player)
	player.set_spawn(Vector2(90, 522))
	player.fell_out.connect(_on_player_fell)

func _build_hud() -> void:
	hud = HUD_SCENE.instantiate()
	add_child(hud)
	hud.configure_phase("FASE 2 - SCANNER", "ORGANIZE OS TOKENS NA ORDEM CORRETA", true)
	hud.pause_requested.connect(_pause_game)
	hud.resume_requested.connect(_resume_game)
	hud.intro_confirmed.connect(_start_challenge)
	hud.menu_confirmed.connect(_return_to_menu)
	hud.hint_requested.connect(_use_hint)
	hud.objective_requested.connect(_show_objective)
	hud.retry_requested.connect(_retry_phase)
	hud.replay_requested.connect(_replay_phase)

func _load_challenge(index: int) -> void:
	challenge_index = index
	state = PhaseState.INTRO
	player.set_controls_enabled(false)
	portal.set_enabled(false)
	_clear_tokens()
	var challenge := _current_challenge()
	sequence.configure(challenge["tokens"])
	time_remaining = float(challenge["time_limit"])
	challenge_checkpoint = GameManager.create_checkpoint()
	hud.configure_scanner(ScannerData.source_bbcode(challenge["tokens"]), challenge["tokens"].size(), _progress_text())
	hud.set_timer(time_remaining)
	hud.set_feedback("O Scanner lê o código da esquerda para a direita.", Color("f4f7fb"))
	_spawn_challenge_tokens(challenge["tokens"])
	player.respawn()
	hud.show_intro("DESAFIO %d/2 - %s" % [index + 1, challenge["title"]], _intro_text(index))

func _spawn_challenge_tokens(tokens: Array) -> void:
	for data in tokens:
		var token = TOKEN_SCENE.instantiate()
		token.position = data["position"]
		token_container.add_child(token)
		token.configure(data)
		token.touched.connect(_on_token_touched)
		spawned_tokens.append(token)

func _clear_tokens() -> void:
	for token in spawned_tokens:
		if is_instance_valid(token): token.queue_free()
	spawned_tokens.clear()

func _start_challenge() -> void:
	state = PhaseState.PLAYING
	player.set_controls_enabled(true)

func _on_token_touched(token) -> void:
	if state != PhaseState.PLAYING or invulnerable: return
	var result := sequence.try_accept(token.token_data)
	if result == ScannerSequence.Result.WRONG:
		_handle_wrong_token(token)
		return
	var slot_index := sequence.expected_index - 1
	token.collect()
	var awarded := GameManager.register_correct_action()
	var kind := int(token.token_data["kind"])
	hud.set_slot(slot_index, str(token.token_data["lexeme"]), ScannerData.kind_short(kind), ScannerData.kind_color(kind))
	hud.set_progress(_progress_text())
	if challenge_index == 0:
		hud.set_feedback("Token identificado! %s é %s. %s (+%d)" % [token.token_data["lexeme"], ScannerData.kind_name(kind), token.token_data["explanation"], awarded], Color("73e6a2"))
	else:
		hud.set_feedback("Token identificado: %s (%s). +%d pontos" % [token.token_data["lexeme"], ScannerData.kind_name(kind), awarded], Color("73e6a2"))
	if result == ScannerSequence.Result.COMPLETE:
		state = PhaseState.PORTAL_READY
		portal.set_enabled(true)
		hud.set_feedback("Sequência correta! Desafio concluído. O portal foi ativado!", Color("ffc43d"))

func _handle_wrong_token(token) -> void:
	var remaining := GameManager.register_mistake("token_fora_de_ordem", true)
	hud.set_feedback("Token fora de ordem! Procure o próximo elemento do código antes de '%s'." % token.token_data["lexeme"], Color("ff7b7b"))
	if remaining > 0: _start_invulnerability(0.8)

func _handle_timeout() -> void:
	if state != PhaseState.PLAYING: return
	state = PhaseState.TRANSITION
	player.set_controls_enabled(false)
	GameManager.rollback_to(challenge_checkpoint)
	var remaining := GameManager.register_mistake("tempo_esgotado", true)
	if remaining > 0:
		hud.set_feedback("Tempo esgotado! O desafio será reiniciado.", Color("ff7b7b"))
		call_deferred("_load_challenge", challenge_index)

func _on_hazard_body_entered(body: Node2D) -> void:
	if body != player or invulnerable: return
	if state != PhaseState.PLAYING and state != PhaseState.PORTAL_READY: return
	var remaining := GameManager.register_mistake("perigo", true)
	if remaining > 0:
		player.respawn()
		hud.set_feedback("Cuidado com os espinhos! Você perdeu uma vida.", Color("ff7b7b"))
		_start_invulnerability(1.0)

func _on_player_fell() -> void:
	_on_hazard_body_entered(player)

func _on_portal_entered() -> void:
	if state != PhaseState.PORTAL_READY: return
	state = PhaseState.TRANSITION
	player.set_controls_enabled(false)
	if challenge_index + 1 < challenges.size(): _load_challenge(challenge_index + 1)
	else: _complete_phase()

func _complete_phase() -> void:
	state = PhaseState.COMPLETE
	var bonus := GameManager.complete_phase(2, not GameManager.phase_had_mistake)
	hud.show_completion("SCANNER CONCLUÍDO!", "O Scanner transforma o código-fonte em tokens. Você reconheceu palavras-chave, identificadores, números, operadores e símbolos.\n\n[b]+%d pontos de conclusão.[/b]\nOs tokens agora estão prontos para o Parser!" % bonus, false)

func _pause_game() -> void:
	if state != PhaseState.PLAYING and state != PhaseState.PORTAL_READY: return
	state_before_pause = state
	state = PhaseState.PAUSED
	player.set_controls_enabled(false)
	hud.show_pause()

func _resume_game() -> void:
	if state != PhaseState.PAUSED: return
	state = state_before_pause
	player.set_controls_enabled(true)

func _show_objective() -> void:
	if state != PhaseState.PLAYING and state != PhaseState.PORTAL_READY: return
	state_before_pause = state
	state = PhaseState.PAUSED
	player.set_controls_enabled(false)
	hud.show_objective("OBJETIVO DO SCANNER", _objective_text())

func _use_hint() -> void:
	if state != PhaseState.PLAYING or sequence.is_complete(): return
	GameManager.register_hint()
	var expected := sequence.next_token()
	for token in spawned_tokens:
		if not token.collected and str(token.token_data["lexeme"]) == str(expected["lexeme"]) and int(token.token_data["kind"]) == int(expected["kind"]):
			token.highlight(3.0)
			break
	hud.set_feedback("Dica: %s O próximo token foi destacado." % _current_challenge()["hint"], Color("ffc43d"))

func _on_game_over(phase_id: int) -> void:
	if phase_id != 2: return
	state = PhaseState.GAME_OVER
	player.set_controls_enabled(false)
	hud.show_game_over()

func _retry_phase() -> void:
	GameManager.rollback_to(0)
	GameManager.reset_lives()
	GameManager.begin_phase(2)
	_load_challenge(0)

func _replay_phase() -> void:
	GameManager.reset_lives()
	GameManager.begin_phase(2)
	_load_challenge(0)

func _return_to_menu() -> void:
	if state != PhaseState.COMPLETE: GameManager.abandon_phase()
	get_tree().change_scene_to_file("res://scenes/menu/menu.tscn")

func _start_invulnerability(seconds: float) -> void:
	invulnerable = true
	await get_tree().create_timer(seconds).timeout
	invulnerable = false

func _current_challenge() -> Dictionary:
	return challenges[challenge_index]

func _progress_text() -> String:
	return "FASE 2/6  •  DESAFIO %d/2  •  TOKENS %d/%d" % [challenge_index + 1, sequence.expected_index, sequence.expected_tokens.size()]

func _intro_text(index: int) -> String:
	if index == 0:
		return "[b]O Scanner[/b], ou analisador léxico, lê o código-fonte da esquerda para a direita e transforma cada elemento em um token.\n\n[color=#58a6ff]PAL - Palavra-chave[/color]   [color=#6ee7a8]ID - Identificador[/color]\n[color=#c084fc]NUM - Número[/color]   [color=#fbbf24]OP - Operador[/color]   [color=#fb7185]SIM - Símbolo[/color]\n\nToque nos tokens na ordem de [b]int x = 10;[/b]."
	return "Agora o código é maior e a ajuda será menor. Leia da esquerda para a direita e organize os nove tokens de [b]if (x > 10) return x;[/b]."

func _objective_text() -> String:
	return "O Scanner separou os tokens, mas eles estão fora de ordem. Explore as plataformas e toque no próximo token do código.\n\n[b]Código atual:[/b] %s\n\nToken errado, espinho ou tempo esgotado custa 5 pontos e uma vida. A dica custa 5 pontos." % _current_challenge()["source"]

func _create_platform(center: Vector2, size: Vector2, one_way: bool) -> void:
	var body := StaticBody2D.new()
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	collision.position = center
	collision.one_way_collision = one_way
	collision.one_way_collision_margin = 10.0
	body.add_child(collision)
	add_child(body)

func _create_hazard(center: Vector2, size: Vector2) -> void:
	var area := Area2D.new()
	area.collision_layer = 8
	area.collision_mask = 1
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	collision.position = center
	area.add_child(collision)
	area.body_entered.connect(_on_hazard_body_entered)
	add_child(area)
