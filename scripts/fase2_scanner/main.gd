extends Node2D

enum PhaseState { INTRO, PLAYING, PAUSED, PORTAL_READY, TRANSITION, GAME_OVER, COMPLETE }
const HUD_SCENE := preload("res://scenes/common/game_hud.tscn")
const TOKEN_BLOCK_SCENE := preload("res://scenes/fase2_scanner/token_block.tscn")

# A Fase 2 agora é um único percurso grande, sem trocar para uma segunda parte.
var challenges: Array[Dictionary] = [ScannerData.challenges()[0]]
var challenge_index := 0
var challenge_checkpoint := 0
var elapsed_time := 0.0
var state := PhaseState.INTRO
var state_before_pause := PhaseState.PLAYING
var placed_blocks := 0
var spawned_blocks: Array = []
var invulnerable := false
var player
var hud
var portal
var entry_portal
var block_container: Node2D
var alignment_rack
var camera: Camera2D
var bridge_progress
var bridge_right_surface: CollisionPolygon2D
var bridge_gate: CollisionPolygon2D
var bridge_complete := false

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
	elapsed_time += delta
	hud.set_timer(elapsed_time)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		if state == PhaseState.PAUSED: _resume_game()
		elif state == PhaseState.PLAYING or state == PhaseState.PORTAL_READY: _pause_game()
		get_viewport().set_input_as_handled()

func _build_world() -> void:
	# O mundo fica exposto no main.tscn para edição direta no 2D.
	_fit_backgrounds()
	alignment_rack = $AlignmentRack
	block_container = $BlockContainer
	entry_portal = $Portals/EntryPortal
	portal = $Portals/ExitPortal
	player = $Player
	camera = $Player/Camera2D
	bridge_progress = $BridgeSlots/BridgeProgress
	bridge_right_surface = get_node_or_null("Platforms/BridgeRightSurfaceBody/CollisionPolygon2D") as CollisionPolygon2D
	bridge_gate = get_node_or_null("Platforms/BridgeGateBody/CollisionPolygon2D") as CollisionPolygon2D
	if bridge_progress and not bridge_progress.bridge_completed.is_connected(_on_bridge_completed):
		bridge_progress.bridge_completed.connect(_on_bridge_completed)
	_reset_bridge_access()
	entry_portal.set_label("ENTRADA")
	entry_portal.set_enabled(true)
	if not portal.entered.is_connected(_on_portal_entered):
		portal.entered.connect(_on_portal_entered)
	if not player.fell_out.is_connected(_on_player_fell):
		player.fell_out.connect(_on_player_fell)
	# O portal é ancorado pelo piso; o spawn fica com os pés no topo dele.
	player.set_spawn(entry_portal.position + Vector2(0, -29))

func _fit_backgrounds() -> void:
	# A fase é um único mapa largo: uma imagem cobre todo o cenário sem sobreposição.
	var map_size := Vector2(2560.0, 720.0)
	var first := get_node_or_null("Background/ValleySky") as Sprite2D
	var second := get_node_or_null("Background/ValleySkySecond") as Sprite2D
	if first == null or first.texture == null:
		return
	var image_size := first.texture.get_size()
	var uniform_scale := maxf(map_size.x / image_size.x, map_size.y / image_size.y)
	var uniform := Vector2.ONE * uniform_scale
	first.scale = uniform
	first.position = map_size * 0.5
	first.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	first.z_index = -20
	if second:
		second.visible = false

func _build_hud() -> void:
	hud = HUD_SCENE.instantiate()
	add_child(hud)
	hud.configure_phase("FASE 2 - SCANNER", "PEGUE OS BLOCOS E LEVE-OS ATÉ A ESTAÇÃO", true)
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
	_clear_blocks()
	var challenge := _current_challenge()
	placed_blocks = 0
	if bridge_progress and bridge_progress.has_method("reset_bridge"):
		bridge_progress.reset_bridge()
	_reset_bridge_access()
	if index == 0:
		elapsed_time = 0.0
	challenge_checkpoint = GameManager.create_checkpoint()
	hud.configure_scanner(ScannerData.source_bbcode(challenge["tokens"]), challenge["tokens"].size(), _progress_text())
	hud.set_bridge_order(challenge["tokens"], 0)
	hud.set_timer(elapsed_time)
	hud.set_feedback("Pegue um bloco com E e leve-o até a estação final.", Color("f4f7fb"))
	_spawn_challenge_blocks(challenge["tokens"])
	player.respawn()
	hud.show_intro("DESAFIO %d/1 - %s" % [index + 1, challenge["title"]], _intro_text(index))

func _spawn_challenge_blocks(tokens: Array) -> void:
	var destination := _bridge_target_position()
	alignment_rack.configure(_bridge_destinations(), [tokens[0]])
	var starts := _block_start_positions(tokens)
	for index in tokens.size():
		var block = TOKEN_BLOCK_SCENE.instantiate()
		block.position = starts[index]
		block_container.add_child(block)
		block.configure(tokens[index], destination, index, tokens.size() > 5)
		block.set_start_position(starts[index])
		block.placed.connect(_on_block_placed)
		spawned_blocks.append(block)

func _block_start_positions(tokens: Array) -> Array[Vector2]:
	# Cada bloco nasce sobre uma plataforma que possui colisão no main.tscn.
	# A associação é feita pelo lexema, para que a ordem do Scanner não altere
	# o local seguro de nascimento.
	var platform_starts := {
		# O símbolo não fica mais no mesmo piso do portal; ele nasce na
		# plataforma inferior seguinte, que possui colisão própria.
		";": Vector2(359, 540),
		"x": Vector2(886, 420),
		"int": Vector2(850, 205),
		"=": Vector2(1389, 475),
		"10": Vector2(1832, 485),
	}
	var starts: Array[Vector2] = []
	for token in tokens:
		var lexeme := str(token.get("lexeme", ""))
		starts.append(platform_starts.get(lexeme, Vector2(886, 440)))
	return starts

func _clear_blocks() -> void:
	for block in spawned_blocks:
		if is_instance_valid(block): block.queue_free()
	spawned_blocks.clear()

func _start_challenge() -> void:
	state = PhaseState.PLAYING
	_set_active_sequence_block(0)
	player.set_controls_enabled(false)
	if challenge_index == 0:
		hud.show_area_title("VALE DO SCANNER")
	await player.play_exit_animation()
	player.set_controls_enabled(true)

func _on_block_placed(block) -> void:
	if state != PhaseState.PLAYING:
		return
	placed_blocks += 1
	var kind := int(block.token_data["kind"])
	var awarded := GameManager.register_correct_action()
	hud.set_progress(_progress_text())
	player.finish_block_delivery(block)
	block.hide_after_delivery()
	hud.set_bridge_order(_current_challenge()["tokens"], placed_blocks)
	if placed_blocks < spawned_blocks.size():
		_set_active_sequence_block(placed_blocks)
		var next_token: Dictionary = _current_challenge()["tokens"][placed_blocks]
		alignment_rack.configure(_bridge_destinations(), [next_token])
		hud.set_feedback("Bloco alinhado: %s. Próximo: %s. (+%d)" % [block.token_data["lexeme"], next_token["lexeme"], awarded], Color("73e6a2"))
		return
	if bridge_progress and bridge_progress.has_method("activate_slot"):
		bridge_progress.activate_slot(0)
	hud.set_feedback("Todos os blocos foram entregues! A ponte está pronta.", Color("ffc43d"))

func _on_hazard_body_entered(body: Node2D) -> void:
	if body != player or invulnerable: return
	if state != PhaseState.PLAYING and state != PhaseState.PORTAL_READY: return
	var remaining := GameManager.register_mistake("perigo", true)
	if remaining > 0:
		state = PhaseState.PLAYING
		portal.set_enabled(false)
		_reset_block_sequence()
		placed_blocks = 0
		if bridge_progress and bridge_progress.has_method("reset_bridge"):
			bridge_progress.reset_bridge()
		_reset_bridge_access()
		alignment_rack.configure(_bridge_destinations(), [_current_challenge()["tokens"][0]])
		hud.set_bridge_order(_current_challenge()["tokens"], 0)
		player.drop_held_block()
		player.respawn()
		hud.set_feedback("Cuidado com os espinhos! Você perdeu uma vida.", Color("ff7b7b"))
		_start_invulnerability(1.0)

func _on_player_fell() -> void:
	_on_hazard_body_entered(player)

func _on_portal_entered() -> void:
	if state != PhaseState.PORTAL_READY or not bridge_complete: return
	state = PhaseState.TRANSITION
	player.set_controls_enabled(false)
	_complete_phase()

func _complete_phase() -> void:
	state = PhaseState.COMPLETE
	var speed_bonus := GameManager.register_time_bonus(_time_bonus())
	var phase_bonus := GameManager.complete_phase(2, not GameManager.phase_had_mistake)
	hud.show_completion("SCANNER CONCLUÍDO!", "O Scanner transforma o código-fonte em tokens. Você reconheceu palavras-chave, identificadores, números, operadores e símbolos.\n\nTempo total: [b]%s[/b]\nBônus por velocidade: [b]+%d[/b]\nBônus da fase: [b]+%d pontos.[/b]\nOs tokens agora estão prontos para o Parser!" % [_format_elapsed_time(), speed_bonus, phase_bonus], false)

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
	if state != PhaseState.PLAYING or placed_blocks >= spawned_blocks.size(): return
	GameManager.register_hint()
	for block in spawned_blocks:
		if not block.is_placed:
			hud.set_feedback("Dica: leve o bloco '%s' até o encaixe da ponte. %s" % [block.token_data["lexeme"], _current_challenge()["hint"]], Color("ffc43d"))
			return

func _on_game_over(phase_id: int) -> void:
	if phase_id != 2: return
	state = PhaseState.GAME_OVER
	player.set_controls_enabled(false)
	hud.show_game_over()

func _retry_phase() -> void:
	GameManager.rollback_to(0)
	GameManager.reset_lives()
	GameManager.begin_phase(2)
	elapsed_time = 0.0
	_load_challenge(0)

func _replay_phase() -> void:
	GameManager.reset_lives()
	GameManager.begin_phase(2)
	elapsed_time = 0.0
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
	return "FASE 2/6  •  DESAFIO 1/1  •  BLOCOS ENTREGUES %d/%d" % [placed_blocks, _current_challenge()["tokens"].size()]

func _time_bonus() -> int:
	var reference_time := 0
	for challenge in challenges:
		reference_time += int(challenge.get("time_limit", 120.0))
	return maxi(reference_time - int(elapsed_time), 0)

func _format_elapsed_time() -> String:
	var total := maxi(int(elapsed_time), 0)
	return "%02d:%02d" % [total / 60, total % 60]

func _intro_text(index: int) -> String:
	if index == 0:
		return "[b]O Scanner[/b] separou o código em blocos. Atravesse o vale, pegue cada bloco com [b]E[/b] e leve-o até a estação no fim do caminho.\n\n[color=#58a6ff]PAL - Palavra-chave[/color]   [color=#6ee7a8]ID - Identificador[/color]\n[color=#c084fc]NUM - Número[/color]   [color=#fbbf24]OP - Operador[/color]   [color=#fb7185]SIM - Símbolo[/color]\n\nO portal à esquerda marca sua entrada no Vale do Scanner."
	return "Agora o código é maior. Atravesse o percurso e entregue os nove blocos na estação final, seguindo a leitura de [b]if (x > 10) return x;[/b]."

func _objective_text() -> String:
	return "O Scanner separou o código em blocos. Pegue cada bloco com [b]E[/b], atravesse as plataformas e entregue-o na estação final.\n\n[b]Código atual:[/b] %s\n\nEspinhos custam 5 pontos e uma vida. O tempo corrido define o bônus de velocidade. A dica custa 5 pontos." % _current_challenge()["source"]

func _bridge_target_position() -> Vector2:
	return Vector2(1169, 246)


func _bridge_destinations() -> Array[Vector2]:
	return [_bridge_target_position()]


func _set_active_sequence_block(index: int) -> void:
	for block_index in spawned_blocks.size():
		var block = spawned_blocks[block_index]
		if is_instance_valid(block):
			block.set_placement_enabled(block_index == index)


func _reset_block_sequence() -> void:
	for block in spawned_blocks:
		if is_instance_valid(block):
			block.reset_to_start()
	_set_active_sequence_block(0)

func _on_bridge_completed() -> void:
	bridge_complete = true
	if bridge_right_surface:
		# Esta superfície longa é o caminho até o portal de saída.
		bridge_right_surface.disabled = false
	if bridge_gate:
		bridge_gate.disabled = true
	if placed_blocks == spawned_blocks.size() and state == PhaseState.PLAYING:
		state = PhaseState.PORTAL_READY
		portal.set_enabled(true)
		hud.set_feedback("A ponte está completa! O portal de saída foi ativado.", Color("ffc43d"))

func _reset_bridge_access() -> void:
	bridge_complete = false
	if bridge_right_surface:
		bridge_right_surface.disabled = true
	if bridge_gate:
		bridge_gate.disabled = false

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
