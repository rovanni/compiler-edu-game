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

func _ready() -> void:
	_mouse_x = get_viewport_rect().size.x * 0.5
	position.x = _mouse_x

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_mouse_x = event.position.x
		_controle_por_mouse = true
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_A, KEY_D, KEY_LEFT, KEY_RIGHT]:
			_controle_por_mouse = false
		elif event.keycode == KEY_SPACE:
			_disparar()

## O clique é tratado como input não consumido para que botões da interface
## (Próximo, Reiniciar etc.) tenham prioridade e não provoquem tiros juntos.
func _unhandled_input(event: InputEvent) -> void:
	if (
		event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_LEFT
		and event.pressed
	):
		_disparar()

func _physics_process(delta: float) -> void:
	if not ativo:
		return

	var direcao := Input.get_axis(&"move_left", &"move_right")
	if not is_zero_approx(direcao):
		_controle_por_mouse = false
		position.x += direcao * velocidade_horizontal * delta
	elif _controle_por_mouse:
		position.x = _mouse_x

	var largura := get_viewport_rect().size.x
	position.x = clampf(position.x, margem_horizontal, largura - margem_horizontal)

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
