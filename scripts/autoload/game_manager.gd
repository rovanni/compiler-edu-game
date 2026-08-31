extends Node

signal session_reset
signal score_changed(total: int, delta: int)
signal lives_changed(current: int, maximum: int)
signal combo_changed(streak: int, bonus: int)
signal phase_started(phase_id: int)
signal phase_completed(phase_id: int, flawless: bool)
signal game_over(phase_id: int)

const MAX_LIVES := 3
const CORRECT_POINTS := 10
const MISTAKE_PENALTY := 5
const PHASE_COMPLETE_POINTS := 50
const FLAWLESS_POINTS := 30

var session_active := false
var score := 0
var lives := MAX_LIVES
var combo := 0
var current_phase_id := 0
var completed_phases: Dictionary = {}

var phase_had_mistake := false
var _phase_positive_points := 0
var _phase_terminal := false

func _ready() -> void:
	_ensure_input_actions()

func start_new_session(start_phase_id: int = 1) -> void:
	session_active = true
	score = 0
	lives = MAX_LIVES
	combo = 0
	current_phase_id = 0
	completed_phases.clear()
	phase_had_mistake = false
	_phase_positive_points = 0
	_phase_terminal = false

	session_reset.emit()
	score_changed.emit(score, 0)
	lives_changed.emit(lives, MAX_LIVES)
	combo_changed.emit(combo, 0)

	begin_phase(start_phase_id)

func begin_phase(phase_id: int) -> void:
	if not session_active:
		session_active = true
		score = 0
		lives = MAX_LIVES
		completed_phases.clear()

	current_phase_id = phase_id
	combo = 0
	phase_had_mistake = false
	_phase_positive_points = 0
	_phase_terminal = false

	if lives <= 0:
		lives = MAX_LIVES

	lives_changed.emit(lives, MAX_LIVES)
	combo_changed.emit(combo, 0)
	phase_started.emit(phase_id)

func register_correct_action() -> int:
	if _phase_terminal:
		return 0
	combo += 1
	var bonus := _combo_bonus(combo)
	var awarded := CORRECT_POINTS + bonus
	score += awarded
	_phase_positive_points += awarded
	score_changed.emit(score, awarded)
	combo_changed.emit(combo, bonus)
	return awarded

func register_mistake(_reason: String = "erro", costs_life: bool = true) -> int:
	if _phase_terminal:
		return lives
	phase_had_mistake = true
	_apply_penalty(MISTAKE_PENALTY)
	_reset_combo()
	if costs_life:
		lives = maxi(lives - 1, 0)
		lives_changed.emit(lives, MAX_LIVES)
		if lives == 0:
			_phase_terminal = true
			game_over.emit(current_phase_id)
	return lives

## Penalidade para perigos que encerram a tentativa independentemente das
## vidas restantes (por exemplo, deixar o chefe da Fase 6 chegar ao chão).
func register_fatal_mistake(_reason: String = "perigo_fatal") -> int:
	if _phase_terminal:
		return lives
	phase_had_mistake = true
	_apply_penalty(MISTAKE_PENALTY)
	_reset_combo()
	lives = 0
	lives_changed.emit(lives, MAX_LIVES)
	_phase_terminal = true
	game_over.emit(current_phase_id)
	return lives

func register_hint() -> void:
	if _phase_terminal:
		return
	phase_had_mistake = true
	_apply_penalty(MISTAKE_PENALTY)
	_reset_combo()

func create_checkpoint() -> int:
	return _phase_positive_points

func rollback_to(checkpoint: int) -> void:
	var safe_checkpoint := clampi(checkpoint, 0, _phase_positive_points)
	var rollback_amount := _phase_positive_points - safe_checkpoint
	if rollback_amount > 0:
		var previous_score := score
		score = maxi(score - rollback_amount, 0)
		_phase_positive_points = safe_checkpoint
		score_changed.emit(score, score - previous_score)
	_reset_combo()

func complete_phase(phase_id: int, flawless: bool) -> int:
	if _phase_terminal:
		return 0
	_phase_terminal = true
	var really_flawless := flawless and not phase_had_mistake
	var bonus := PHASE_COMPLETE_POINTS
	if really_flawless:
		bonus += FLAWLESS_POINTS
	score += bonus
	_phase_positive_points = 0
	completed_phases[phase_id] = true
	score_changed.emit(score, bonus)
	phase_completed.emit(phase_id, really_flawless)
	return bonus

## Dá o mesmo bônus de pontos de "fase completa" (+ bônus "sem erros" se
## aplicável), SEM marcar completed_phases e SEM travar _phase_terminal
## nem emitir phase_completed. Usado por fases com sub-etapas internas
## (ex: Fase 6, que tem 3 sub-fases) para premiar o progresso em cada
## sub-etapa sem disparar o carimbo "✓ concluída" do menu antes da hora —
## esse carimbo só deve vir de complete_phase(), chamado na última etapa.
func award_sub_phase_bonus() -> int:
	if _phase_terminal:
		return 0
	var really_flawless := not phase_had_mistake
	var bonus := PHASE_COMPLETE_POINTS
	if really_flawless:
		bonus += FLAWLESS_POINTS
	score += bonus
	score_changed.emit(score, bonus)
	# Reseta o rastreio de erro/pontos-positivos para a próxima sub-etapa,
	# do mesmo jeito que begin_phase() faz ao trocar de fase.
	phase_had_mistake = false
	_phase_positive_points = 0
	return bonus

func register_time_bonus(amount: int) -> int:
	if _phase_terminal:
		return 0
	var awarded := maxi(amount, 0)
	if awarded == 0:
		return 0
	score += awarded
	_phase_positive_points += awarded
	score_changed.emit(score, awarded)
	return awarded


func abandon_phase() -> void:
	rollback_to(0)
	current_phase_id = 0
	_phase_terminal = false
	_reset_combo()

func reset_lives() -> void:
	lives = MAX_LIVES
	_phase_terminal = false
	lives_changed.emit(lives, MAX_LIVES)

func is_phase_completed(phase_id: int) -> bool:
	return completed_phases.get(phase_id, false)

func _apply_penalty(amount: int) -> void:
	var previous_score := score
	score = maxi(score - amount, 0)
	score_changed.emit(score, score - previous_score)

func _reset_combo() -> void:
	combo = 0
	combo_changed.emit(combo, 0)

func _combo_bonus(streak: int) -> int:
	if streak <= 1:
		return 0
	if streak == 2:
		return 2
	if streak == 3:
		return 4
	return 8

func _ensure_input_actions() -> void:
	_register_action(&"move_left", [KEY_A, KEY_LEFT])
	_register_action(&"move_right", [KEY_D, KEY_RIGHT])
	_register_action(&"jump", [KEY_W, KEY_UP, KEY_SPACE])
	_register_action(&"drop_down", [KEY_S, KEY_DOWN])
	_register_action(&"pause", [KEY_ESCAPE])

func _register_action(action: StringName, keys: Array[int]) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for keycode in keys:
		var already_registered := false
		for existing_event in InputMap.action_get_events(action):
			if existing_event is InputEventKey and existing_event.keycode == keycode:
				already_registered = true
				break
		if already_registered:
			continue
		var event := InputEventKey.new()
		event.keycode = keycode
		InputMap.action_add_event(action, event)
