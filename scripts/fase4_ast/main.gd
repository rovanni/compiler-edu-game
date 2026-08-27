extends Node2D

enum PhaseState { INTRO, PLAYING, PAUSED, PORTAL_READY, RESETTING, GAME_OVER, COMPLETE }

const NODE_SCENE := preload("res://scenes/fase4_ast/no_ast.tscn")
const PLATFORM_SCRIPT := preload("res://scripts/fase4_ast/ast_platform.gd")
const PORTAL_SCRIPT := preload("res://scripts/fase4_ast/ast_portal.gd")
const AMBIENCE_TARGET_VOLUME_DB := -20.0

const SLOT_ORDER := ["root", "left", "right", "left_left", "left_right", "right_left", "right_right"]
const SLOT_POSITIONS := {
	"root": Vector2(640, 160),
	"left": Vector2(420, 315),
	"right": Vector2(840, 315),
	"left_left": Vector2(320, 470),
	"left_right": Vector2(500, 470),
	"right_left": Vector2(780, 470),
	"right_right": Vector2(960, 470),
}
const SLOT_LABELS := {
	"root": "RAIZ",
	"left": "FILHO ESQ.",
	"right": "FILHO DIR.",
	"left_left": "FOLHA",
	"left_right": "FOLHA",
	"right_left": "FOLHA",
	"right_right": "FOLHA",
}
const EDGES := [
	["root", "left"], ["root", "right"],
	["left", "left_left"], ["left", "left_right"],
	["right", "right_left"], ["right", "right_right"],
]

const CHALLENGES := [
	{
		"expression": "a + b * c",
		"lesson": "A multiplicação tem precedência. Por isso, b * c forma a subárvore direita e + fica na raiz.",
		"nodes": {
			"root": {"token": "+"},
			"left": {"token": "a"},
			"right": {"token": "*"},
			"right_left": {"token": "b"},
			"right_right": {"token": "c"},
		},
	},
	{
		"expression": "x = y + 1",
		"lesson": "A atribuição é a última operação. O identificador x fica à esquerda e y + 1 forma a subárvore direita.",
		"nodes": {
			"root": {"token": "="},
			"left": {"token": "x"},
			"right": {"token": "+"},
			"right_left": {"token": "y"},
			"right_right": {"token": "1"},
		},
	},
	{
		"expression": "a * b + c",
		"lesson": "A multiplicação a * b é avaliada antes da soma. Ela forma a subárvore esquerda de +.",
		"nodes": {
			"root": {"token": "+"},
			"left": {"token": "*"},
			"right": {"token": "c"},
			"left_left": {"token": "a"},
			"left_right": {"token": "b"},
		},
	},
	{
		"expression": "( a + b ) * c",
		"lesson": "Os parênteses fazem a + b virar uma subárvore completa. A multiplicação fica na raiz.",
		"nodes": {
			"root": {"token": "*"},
			"left": {"token": "+"},
			"right": {"token": "c"},
			"left_left": {"token": "a"},
			"left_right": {"token": "b"},
		},
	},
]

@onready var platforms_root: Node2D = $Platforms
@onready var nodes_root: Node2D = $Nodes
@onready var player = $Jogador
@onready var hud = $HUD
@onready var ambience_player: AudioStreamPlayer = $ForestAmbience

var session := AstSession.new()
var active_nodes: Dictionary = {}
var active_slots: Dictionary = {}
var portal
var entry_portal
var challenge_index := 0
var phase_checkpoint := 0
var time_remaining := 180.0
var state := PhaseState.INTRO
var state_before_pause := PhaseState.PLAYING
var interaction_locked := false


func _ready() -> void:
	_start_ambience()
	if GameManager.current_phase_id != 4:
		if GameManager.session_active:
			GameManager.begin_phase(4)
		else:
			GameManager.start_new_session(4)

	phase_checkpoint = GameManager.create_checkpoint()
	_build_world()
	_connect_hud()
	GameManager.game_over.connect(_on_game_over)
	challenge_index = randi() % CHALLENGES.size()
	_start_challenge(challenge_index)


func _start_ambience() -> void:
	var looped_stream := ambience_player.stream.duplicate()
	if looped_stream is AudioStreamWAV:
		looped_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		looped_stream.loop_begin = 0
		looped_stream.loop_end = int(round(looped_stream.get_length() * float(looped_stream.mix_rate)))
	ambience_player.stream = looped_stream
	ambience_player.volume_db = -36.0
	ambience_player.play()
	create_tween().tween_property(ambience_player, "volume_db", AMBIENCE_TARGET_VOLUME_DB, 1.4)


func _process(delta: float) -> void:
	if state != PhaseState.PLAYING:
		return
	time_remaining = maxf(time_remaining - delta, 0.0)
	hud.set_time(time_remaining)
	if time_remaining <= 0.0:
		_handle_timeout()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		if state == PhaseState.PAUSED:
			_resume_game()
		elif state == PhaseState.PLAYING or state == PhaseState.PORTAL_READY:
			_pause_game()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed(&"interact") and state == PhaseState.PLAYING:
		_try_place_current_token()
		get_viewport().set_input_as_handled()


func _draw() -> void:
	for edge in EDGES:
		var parent_id: String = edge[0]
		var child_id: String = edge[1]
		if not active_slots.has(parent_id) or not active_slots.has(child_id):
			continue
		var from: Vector2 = SLOT_POSITIONS[parent_id] + Vector2(0, 43)
		var to: Vector2 = SLOT_POSITIONS[child_id] - Vector2(0, 69)
		var middle_y: float = (from.y + to.y) * 0.5
		_draw_branch_segment(from, Vector2(from.x, middle_y))
		_draw_branch_segment(Vector2(from.x, middle_y), Vector2(to.x, middle_y))
		_draw_branch_segment(Vector2(to.x, middle_y), to)


func _draw_branch_segment(from: Vector2, to: Vector2) -> void:
	draw_line(from, to, Color(0.02, 0.07, 0.05, 0.72), 8.0, true)
	var length := from.distance_to(to)
	if length <= 0.1:
		return
	var direction := (to - from) / length
	var cursor := 0.0
	while cursor < length:
		var dash_end := minf(cursor + 9.0, length)
		draw_line(from + direction * cursor, from + direction * dash_end, Color("f4e8aa"), 2.5, true)
		cursor += 15.0


func _build_world() -> void:
	var platform_specs := [
		{"position": Vector2(115, 585), "size": Vector2(230, 30), "one_way": false},
		{"position": Vector2(320, 537), "size": Vector2(138, 18), "one_way": true},
		{"position": Vector2(500, 537), "size": Vector2(138, 18), "one_way": true},
		{"position": Vector2(780, 537), "size": Vector2(138, 18), "one_way": true},
		{"position": Vector2(960, 537), "size": Vector2(138, 18), "one_way": true},
		{"position": Vector2(420, 382), "size": Vector2(190, 20), "one_way": true},
		{"position": Vector2(840, 382), "size": Vector2(190, 20), "one_way": true},
		{"position": Vector2(640, 226), "size": Vector2(190, 20), "one_way": true},
		{"position": Vector2(1170, 585), "size": Vector2(220, 30), "one_way": false},
	]
	for spec in platform_specs:
		var platform = PLATFORM_SCRIPT.new()
		platform.configure(spec["size"], spec["one_way"])
		platform.position = spec["position"]
		platforms_root.add_child(platform)

	_create_boundary(Vector2(-20, 360), Vector2(40, 720))
	_create_boundary(Vector2(1300, 360), Vector2(40, 720))

	entry_portal = PORTAL_SCRIPT.new()
	entry_portal.name = "EntryPortal"
	entry_portal.position = Vector2(105, 500)
	add_child(entry_portal)
	entry_portal.set_enabled(true)

	portal = PORTAL_SCRIPT.new()
	portal.name = "ExitPortal"
	portal.position = Vector2(1170, 500)
	portal.entered.connect(_on_portal_entered)
	add_child(portal)

	player.set_spawn(Vector2(105, 520))
	player.respawn()
	player.fell_out.connect(_on_player_fell)


func _create_boundary(position: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = position
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	platforms_root.add_child(body)


func _connect_hud() -> void:
	hud.pause_requested.connect(_pause_game)
	hud.resume_requested.connect(_resume_game)
	hud.intro_confirmed.connect(_begin_playing)
	hud.menu_requested.connect(_return_to_menu)
	hud.hint_requested.connect(_use_hint)
	hud.retry_requested.connect(_retry_phase)
	hud.replay_requested.connect(_replay_phase)


func _start_challenge(index: int) -> void:
	challenge_index = index
	state = PhaseState.INTRO
	interaction_locked = false
	player.set_controls_enabled(false)
	player.respawn()
	entry_portal.set_enabled(true)
	portal.set_enabled(false)

	for old_node in nodes_root.get_children():
		nodes_root.remove_child(old_node)
		old_node.queue_free()
	active_nodes.clear()
	active_slots.clear()

	var challenge := _current_challenge()
	var definitions: Dictionary = challenge["nodes"]
	for slot_id in SLOT_ORDER:
		if not definitions.has(slot_id):
			continue
		var node = NODE_SCENE.instantiate()
		node.position = SLOT_POSITIONS[slot_id]
		nodes_root.add_child(node)
		node.configure(slot_id, SLOT_LABELS[slot_id], str(definitions[slot_id]["token"]))
		active_nodes[slot_id] = node
		active_slots[slot_id] = true
	queue_redraw()

	session.configure(definitions)
	phase_checkpoint = GameManager.create_checkpoint()
	time_remaining = 180.0
	hud.set_expression(challenge["expression"], challenge["lesson"])
	hud.set_progress(0, session.total())
	hud.set_time(time_remaining)
	hud.set_instruction("APROXIME-SE DE UM NÓ\nE PRESSIONE  E  PARA ALOCAR")
	_update_held_token()
	hud.show_intro(challenge["expression"], challenge["lesson"])


func _begin_playing() -> void:
	if state != PhaseState.INTRO:
		return
	state = PhaseState.PLAYING
	SoundManager.play_portal()
	player.set_controls_enabled(false)
	await player.play_portal_exit_animation()
	player.set_controls_enabled(true)


func _try_place_current_token() -> void:
	if interaction_locked or session.current_token.is_empty():
		return
	var target = _nearest_available_node()
	if target == null:
		hud.show_feedback("Aproxime-se de um nó vazio antes de pressionar E.", Color("ffcf70"))
		return

	var placed_token := session.current_token
	var result := session.try_place(target.slot_id)
	if result == AstSession.Result.WRONG:
		_handle_wrong_node(target)
		return

	target.mark_filled(placed_token, _token_color(placed_token))
	SoundManager.play_confirmation()
	var awarded := GameManager.register_correct_action()
	hud.set_progress(session.progress(), session.total())
	hud.show_feedback("Correto! '%s' ocupa esse nó. +%d pontos" % [placed_token, awarded], Color("7ce5a5"))

	if result == AstSession.Result.COMPLETE:
		state = PhaseState.PORTAL_READY
		portal.set_enabled(true)
		player.set_held_token("")
		hud.set_token("", Color("36c77b"))
		hud.set_instruction("ÁRVORE COMPLETA!\nATRAVESSE O PORTAL")
		hud.show_feedback("AST concluída! O portal foi ativado.", Color("ffc94a"))
	else:
		_update_held_token()


func _nearest_available_node():
	var nearest = null
	var nearest_distance := INF
	for node in active_nodes.values():
		if not node.is_player_nearby():
			continue
		var distance: float = player.global_position.distance_squared_to(node.global_position)
		if distance < nearest_distance:
			nearest = node
			nearest_distance = distance
	return nearest


func _handle_wrong_node(target) -> void:
	interaction_locked = true
	target.flash_error()
	SoundManager.play_error()
	var remaining := GameManager.register_mistake("no_ast_incorreto", true)
	var expected := session.expected_for(target.slot_id)
	hud.show_feedback("Esse nó não recebe '%s'. Reavalie a precedência e a posição dos filhos." % session.current_token, Color("ff7b83"))
	if remaining > 0:
		await get_tree().create_timer(0.55).timeout
		if state == PhaseState.PLAYING:
			hud.show_feedback("O nó escolhido espera outra parte da expressão; '%s' continua na sua mão." % session.current_token, Color("ffcf70"))
	interaction_locked = false
	# Mantém a variável para facilitar depuração no editor sem revelar a resposta na interface.
	if expected.is_empty():
		push_warning("Nó AST sem token esperado: %s" % target.slot_id)


func _use_hint() -> void:
	if state != PhaseState.PLAYING or session.current_token.is_empty():
		return
	GameManager.register_hint()
	for slot_id in active_nodes:
		if session.expected_for(slot_id) == session.current_token and not session.placed_by_slot.has(slot_id):
			active_nodes[slot_id].highlight_hint()
			break
	hud.show_feedback("Dica: o nó correto para '%s' foi iluminado por alguns segundos. -5 pontos" % session.current_token, Color("ffc94a"))


func _update_held_token() -> void:
	var color := _token_color(session.current_token)
	player.set_held_token(session.current_token, color)
	hud.set_token(session.current_token, color)


func _token_color(token: String) -> Color:
	if token in ["+", "-", "*", "/", "="]:
		return Color("a855f7")
	if token.is_valid_int() or token.is_valid_float():
		return Color("f5b642")
	return Color("39bde8")


func _handle_timeout() -> void:
	if state != PhaseState.PLAYING:
		return
	state = PhaseState.RESETTING
	player.set_controls_enabled(false)
	SoundManager.play_error()
	GameManager.rollback_to(phase_checkpoint)
	var remaining := GameManager.register_mistake("tempo_esgotado", true)
	if remaining <= 0:
		return
	hud.show_feedback("Tempo esgotado. A expressão será reiniciada.", Color("ff7b83"))
	await get_tree().create_timer(1.0).timeout
	_start_challenge(challenge_index)


func _on_player_fell() -> void:
	if state != PhaseState.PLAYING and state != PhaseState.PORTAL_READY:
		return
	SoundManager.play_hurt()
	var remaining := GameManager.register_mistake("queda", true)
	if remaining > 0:
		player.respawn()
		hud.show_feedback("Cuidado com os vãos! Você perdeu uma vida.", Color("ff7b83"))


func _on_portal_entered() -> void:
	if state != PhaseState.PORTAL_READY:
		return
	state = PhaseState.COMPLETE
	player.set_controls_enabled(false)
	SoundManager.play_portal()
	var bonus := GameManager.complete_phase(4, not GameManager.phase_had_mistake)
	hud.show_completion(_current_challenge()["expression"], bonus)


func _pause_game() -> void:
	if state != PhaseState.PLAYING and state != PhaseState.PORTAL_READY:
		return
	state_before_pause = state
	state = PhaseState.PAUSED
	player.set_controls_enabled(false)
	hud.show_pause()


func _resume_game() -> void:
	if state != PhaseState.PAUSED:
		return
	state = state_before_pause
	player.set_controls_enabled(true)


func _on_game_over(phase_id: int) -> void:
	if phase_id != 4:
		return
	state = PhaseState.GAME_OVER
	player.set_controls_enabled(false)
	portal.set_enabled(false)
	hud.show_game_over()


func _retry_phase() -> void:
	GameManager.rollback_to(phase_checkpoint)
	GameManager.reset_lives()
	GameManager.begin_phase(4)
	_start_challenge(challenge_index)


func _replay_phase() -> void:
	GameManager.reset_lives()
	GameManager.begin_phase(4)
	_start_challenge((challenge_index + 1) % CHALLENGES.size())


func _return_to_menu() -> void:
	if state != PhaseState.COMPLETE:
		GameManager.abandon_phase()
	get_tree().change_scene_to_file("res://scenes/menu/menu.tscn")


func _current_challenge() -> Dictionary:
	return CHALLENGES[challenge_index]
