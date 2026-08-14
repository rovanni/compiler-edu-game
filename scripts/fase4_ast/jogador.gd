extends CharacterBody2D

signal fell_out

const SPEED := 225.0
const JUMP_VELOCITY := -590.0
const FALL_LIMIT := 770.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var held_token: PanelContainer = $HeldToken
@onready var held_token_label: Label = $HeldToken/Token

var controls_enabled := true
var spawn_position := Vector2.ZERO
var _fall_reported := false


func _ready() -> void:
	spawn_position = global_position
	held_token.visible = false
	atualizar_animacao()


func _physics_process(delta: float) -> void:
	if not controls_enabled:
		velocity = Vector2.ZERO
		return

	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed(&"jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction := Input.get_axis(&"move_left", &"move_right")
	if not is_zero_approx(direction):
		velocity.x = direction * SPEED
		sprite.flip_h = direction < 0.0
		held_token.position.x = -87.0 if direction < 0.0 else 43.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED * 6.0 * delta)

	move_and_slide()
	atualizar_animacao()

	if global_position.y > FALL_LIMIT and not _fall_reported:
		_fall_reported = true
		fell_out.emit()


func set_spawn(new_spawn: Vector2) -> void:
	spawn_position = new_spawn


func respawn() -> void:
	global_position = spawn_position
	velocity = Vector2.ZERO
	_fall_reported = false


func set_controls_enabled(enabled: bool) -> void:
	controls_enabled = enabled
	if not enabled:
		velocity = Vector2.ZERO
	atualizar_animacao()


func set_held_token(token: String, color: Color = Color("9b5de5")) -> void:
	held_token.visible = not token.is_empty()
	held_token_label.text = token
	var style := StyleBoxFlat.new()
	style.bg_color = color.darkened(0.18)
	style.border_color = color.lightened(0.35)
	style.set_border_width_all(3)
	style.set_corner_radius_all(7)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.65)
	style.shadow_size = 5
	held_token.add_theme_stylebox_override("panel", style)


func atualizar_animacao() -> void:
	if not controls_enabled:
		sprite.play(&"idle")
	elif not is_on_floor():
		sprite.play(&"pular")
	elif absf(velocity.x) > 0.1:
		sprite.play(&"andar")
	else:
		sprite.play(&"idle")
