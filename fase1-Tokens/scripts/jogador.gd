extends CharacterBody2D

const SPEED = 160.0
const JUMP_VELOCITY = -585.0

@onready var sprite = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction := Input.get_axis("ui_left", "ui_right")

	if direction:
		velocity.x = direction * SPEED
		sprite.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

	atualizar_animacao()


func atualizar_animacao() -> void:
	if not is_on_floor():
		sprite.play("pular")
	elif abs(velocity.x) > 0.1:
		sprite.play("andar")
	else:
		sprite.play("idle")
