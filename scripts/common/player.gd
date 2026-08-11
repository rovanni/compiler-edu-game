extends CharacterBody2D

signal fell_out

const SPEED := 220.0
const JUMP_VELOCITY := -540.0
const FALL_LIMIT := 780.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
var controls_enabled := true
var spawn_position := Vector2.ZERO
var _fall_reported := false


func _ready() -> void:
	spawn_position = global_position


func _physics_process(delta: float) -> void:
	if not controls_enabled:
		velocity = Vector2.ZERO
		atualizar_animacao()
		return
	if not is_on_floor():
		velocity += get_gravity() * delta
	if Input.is_action_just_pressed(&"jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	if Input.is_action_just_pressed(&"drop_down") and is_on_floor():
		global_position.y += 8.0
	var direction := Input.get_axis(&"move_left", &"move_right")
	if direction != 0.0:
		velocity.x = direction * SPEED
		sprite.flip_h = direction < 0.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)
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


func atualizar_animacao() -> void:
	if not is_on_floor():
		sprite.play(&"pular")
	elif absf(velocity.x) > 0.1:
		sprite.play(&"andar")
	else:
		sprite.play(&"idle")
