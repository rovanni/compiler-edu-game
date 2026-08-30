extends Node2D
class_name CanhaoFase6

signal disparou

@export var cena_projetil: PackedScene
@export var velocidade_horizontal: float = 520.0
@export var margem_horizontal: float = 52.0
@export var altura_boca: float = 94.0

@onready var som_tiro: AudioStreamPlayer = $Tiro

var ativo := true
var _controle_por_mouse := true
var _mouse_x := 0.0
var _ultimo_toque_ms := -1000
var _toque_em_andamento := false
var _toque_jogo_ativo := false
var _toque_arrastou := false
var _toque_inicio := Vector2.ZERO

const JANELA_CLIQUE_EMULADO_MS := 120
const LIMIAR_ARRASTE_TOUCH := 12.0

func _ready() -> void:
	_mouse_x = get_viewport_rect().size.x * 0.5
	position.x = _mouse_x

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_definir_posicao_ponteiro(event.position.x)
	elif event is InputEventScreenDrag:
		_definir_posicao_ponteiro(event.position.x)
		if _toque_jogo_ativo and event.position.distance_to(_toque_inicio) >= LIMIAR_ARRASTE_TOUCH:
			_toque_arrastou = true
	elif event is InputEventScreenTouch:
		_definir_posicao_ponteiro(event.position.x)
		if event.pressed:
			_toque_em_andamento = true
			_toque_arrastou = false
			_toque_inicio = event.position
		else:
			# Se um botão consumir a soltura, _unhandled_input não será chamado.
			# A limpeza adiada evita deixar o canhão preso no modo touch.
			call_deferred("_limpar_toque_consumido")
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_A, KEY_D, KEY_LEFT, KEY_RIGHT]:
			_controle_por_mouse = false
		elif event.keycode == KEY_SPACE:
			_disparar()

## Clique e toque são tratados como input não consumido para que botões da
## interface (Próximo, Pular etc.) tenham prioridade e não provoquem tiros.
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_toque_jogo_ativo = true
			return
		var deve_disparar := _toque_jogo_ativo and not _toque_arrastou
		_toque_em_andamento = false
		_toque_jogo_ativo = false
		_ultimo_toque_ms = Time.get_ticks_msec()
		if deve_disparar:
			_definir_posicao_ponteiro(event.position.x)
			_aplicar_posicao_ponteiro()
			_disparar()
	elif (
		event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_LEFT
		and event.pressed
	):
		# Alguns totens emulam um clique de mouse logo depois do toque nativo.
		# Ignorá-lo impede que um único dedo gere dois projéteis.
		if _toque_em_andamento or Time.get_ticks_msec() - _ultimo_toque_ms <= JANELA_CLIQUE_EMULADO_MS:
			return
		_disparar()

func _physics_process(delta: float) -> void:
	if not ativo:
		return

	var direcao := Input.get_axis(&"move_left", &"move_right")
	if not is_zero_approx(direcao):
		_controle_por_mouse = false
		position.x += direcao * velocidade_horizontal * delta
	elif _controle_por_mouse:
		_aplicar_posicao_ponteiro()

	var largura := get_viewport_rect().size.x
	position.x = clampf(position.x, margem_horizontal, largura - margem_horizontal)

func _definir_posicao_ponteiro(posicao_x: float) -> void:
	_mouse_x = posicao_x
	_controle_por_mouse = true

func _aplicar_posicao_ponteiro() -> void:
	var largura := get_viewport_rect().size.x
	position.x = clampf(_mouse_x, margem_horizontal, largura - margem_horizontal)

func _limpar_toque_consumido() -> void:
	if not _toque_em_andamento:
		return
	_toque_em_andamento = false
	_toque_jogo_ativo = false
	_toque_arrastou = false

func definir_ativo(valor: bool) -> void:
	ativo = valor
	visible = valor
	if not valor:
		limpar_projeteis()

func limpar_projeteis() -> void:
	for projetil in get_tree().get_nodes_in_group(&"projeteis_fase6"):
		if is_instance_valid(projetil):
			projetil.queue_free()

func _disparar() -> void:
	if not ativo or cena_projetil == null:
		return

	var projetil := cena_projetil.instantiate()
	get_parent().add_child(projetil)
	projetil.global_position = global_position + Vector2(0.0, -altura_boca)
	som_tiro.pitch_scale = randf_range(0.94, 1.06)
	som_tiro.play()
	disparou.emit()
