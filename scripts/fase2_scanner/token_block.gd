extends RigidBody2D

signal placed(block: RigidBody2D)

var token_data: Dictionary = {}
var target_position := Vector2.ZERO
var target_index := 0
var is_placed := false
var placement_enabled := false
var held := false
var start_position := Vector2.ZERO

# O bloco repousa nas mãos levantadas da pose de transporte.
const BLOCK_CARRY_OFFSET := Vector2(0, -93	)
const SLOT_SNAP_RADIUS := 150.0

@onready var lexeme_label: Label = $Lexeme
@onready var kind_label: Label = $Kind


func configure(data: Dictionary, destination: Vector2, destination_index: int, compact: bool) -> void:
	token_data = data.duplicate(true)
	target_position = destination
	target_index = destination_index
	scale = Vector2.ONE * (0.68 if compact else 1.0)
	var lexeme := str(token_data.get("lexeme", "?"))
	lexeme_label.text = lexeme
	lexeme_label.add_theme_font_size_override("font_size", 13 if compact else (15 if lexeme.length() >= 4 else 18))
	kind_label.text = ScannerData.kind_short(int(token_data.get("kind", -1)))
	var color := ScannerData.kind_color(int(token_data.get("kind", -1)))
	$Panel.color = color
	kind_label.add_theme_color_override("font_color", Color("071523"))
	var badge := StyleBoxFlat.new()
	badge.bg_color = color.lightened(0.2)
	badge.border_color = Color("071523")
	badge.set_border_width_all(2)
	badge.set_corner_radius_all(3)
	kind_label.add_theme_stylebox_override("normal", badge)


func set_start_position(value: Vector2) -> void:
	start_position = value


func _physics_process(_delta: float) -> void:
	if is_placed or held or not placement_enabled:
		return
	# A colocação é deliberadamente tolerante para não exigir precisão de pixel.
	if global_position.distance_to(target_position) < 28.0 and linear_velocity.length() < 90.0:
		_snap_into_slot()


func set_placement_enabled(value: bool) -> void:
	placement_enabled = value


func pick_up(holder: Node2D) -> void:
	# Qualquer bloco pode ser carregado; apenas o bloco atual da sequência
	# tem placement_enabled e, portanto, pode ser entregue no encaixe.
	if is_placed or held:
		return
	held = true
	freeze = true
	sleeping = true
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	collision_layer = 0
	collision_mask = 0
	reparent(holder, true)
	# O bloco fica diretamente acima das mãos da pose de transporte.
	position = BLOCK_CARRY_OFFSET
	rotation = 0.0


func drop(world_parent: Node2D, drop_position: Vector2) -> void:
	if not held:
		return
	held = false
	reparent(world_parent, true)
	global_position = drop_position
	freeze = false
	sleeping = false
	collision_layer = 1
	collision_mask = 1
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	# Soltar sobre o vão encaixa o bloco imediatamente, sem exigir que a física
	# acerte um ponto exato depois do lançamento.
	# No topo da ponte o jogador fica acima do centro do slot; a tolerância
	# vertical maior permite entregar sem exigir que o bloco atravesse a ponte.
	if placement_enabled and drop_position.distance_to(target_position) <= SLOT_SNAP_RADIUS:
		_snap_into_slot()

func _snap_into_slot() -> void:
	if is_placed:
		return
	is_placed = true
	held = false
	freeze = true
	sleeping = true
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	collision_layer = 0
	collision_mask = 0
	global_position = target_position
	rotation = 0.0
	placed.emit(self)


func hide_after_delivery() -> void:
	# O bloco já entregue sai de cena, mas permanece na árvore para que um
	# reinício por queda consiga restaurar toda a sequência.
	visible = false
	set_placement_enabled(false)


func reset_to_start() -> void:
	held = false
	is_placed = false
	visible = true
	reparent(get_tree().current_scene, true)
	global_position = start_position if start_position != Vector2.ZERO else token_data.get("position", global_position)
	freeze = false
	sleeping = false
	collision_layer = 1
	collision_mask = 1
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
