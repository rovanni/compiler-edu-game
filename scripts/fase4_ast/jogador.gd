extends CharacterBody2D

signal fell_out

const SPEED := 225.0
const JUMP_VELOCITY := -590.0
const FALL_LIMIT := 770.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var carry_pose: Sprite2D = $CarryPose
@onready var carry_walk: AnimatedSprite2D = $CarryWalk
@onready var carry_jump: Sprite2D = $CarryJump
@onready var held_token: PanelContainer = $HeldToken
@onready var held_token_label: Label = $HeldToken/Token

var controls_enabled := true
var spawn_position := Vector2.ZERO
var _fall_reported := false
var _carrying_token := false
var _portal_exit_active := false


func _ready() -> void:
	spawn_position = global_position
	held_token.visible = false
	_set_carry_animation(false)
	atualizar_animacao()


func _physics_process(delta: float) -> void:
	if not controls_enabled:
		velocity = Vector2.ZERO
		if _portal_exit_active:
			_show_portal_exit_pose()
			return
		atualizar_animacao()
		return

	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed(&"jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		SoundManager.play_jump()
	if Input.is_action_just_pressed(&"drop_down") and is_on_floor():
		global_position.y += 16.0
		velocity.y = 80.0

	var direction := Input.get_axis(&"move_left", &"move_right")
	if not is_zero_approx(direction):
		velocity.x = direction * SPEED
		if is_on_floor():
			SoundManager.play_footstep()
		sprite.flip_h = direction < 0.0
		carry_pose.flip_h = direction < 0.0
		carry_walk.flip_h = direction < 0.0
		carry_jump.flip_h = direction < 0.0
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
	modulate = Color.WHITE
	scale = Vector2.ONE
	_portal_exit_active = false
	atualizar_animacao()


func play_portal_exit_animation() -> void:
	_portal_exit_active = true
	global_position = spawn_position + Vector2(0.0, -62.0)
	modulate = Color(1.0, 1.0, 1.0, 0.0)
	scale = Vector2(0.72, 0.72)
	_show_portal_exit_pose()

	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "global_position", spawn_position, 0.78)
	tween.tween_property(self, "modulate:a", 1.0, 0.42)
	tween.tween_property(self, "scale", Vector2.ONE, 0.78)
	await tween.finished

	_portal_exit_active = false
	velocity = Vector2.ZERO
	atualizar_animacao()


func set_controls_enabled(enabled: bool) -> void:
	controls_enabled = enabled
	if not enabled:
		velocity = Vector2.ZERO
	atualizar_animacao()


func set_held_token(token: String, color: Color = Color("9b5de5")) -> void:
	var carrying := not token.is_empty()
	held_token.visible = carrying
	held_token_label.text = token
	var style := StyleBoxFlat.new()
	style.bg_color = color.darkened(0.18)
	style.border_color = color.lightened(0.35)
	style.set_border_width_all(3)
	style.set_corner_radius_all(7)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.65)
	style.shadow_size = 5
	held_token.add_theme_stylebox_override("panel", style)
	_set_carry_animation(carrying)


func atualizar_animacao() -> void:
	if _carrying_token:
		sprite.visible = false
		if not is_on_floor():
			carry_pose.visible = false
			carry_walk.visible = false
			carry_walk.stop()
			carry_jump.visible = true
			return
		var walking := absf(velocity.x) > 0.1
		carry_pose.visible = not walking
		carry_walk.visible = walking
		carry_jump.visible = false
		if walking:
			carry_walk.play(&"andar_carregando")
		else:
			carry_walk.stop()
		return

	sprite.visible = true
	carry_pose.visible = false
	carry_walk.visible = false
	carry_jump.visible = false
	carry_walk.stop()
	if not controls_enabled:
		sprite.play(&"idle")
	elif not is_on_floor():
		sprite.play(&"pular")
	elif absf(velocity.x) > 0.1:
		sprite.play(&"andar")
	else:
		sprite.play(&"idle")


func _set_carry_animation(active: bool) -> void:
	_carrying_token = active
	sprite.visible = not active
	carry_pose.visible = active
	carry_walk.visible = false
	carry_jump.visible = false
	carry_walk.stop()
	carry_pose.flip_h = sprite.flip_h
	carry_walk.flip_h = sprite.flip_h
	carry_jump.flip_h = sprite.flip_h
	if not active:
		atualizar_animacao()


func _show_portal_exit_pose() -> void:
	if _carrying_token:
		sprite.visible = false
		carry_pose.visible = false
		carry_walk.visible = false
		carry_walk.stop()
		carry_jump.visible = true
		return

	sprite.visible = true
	carry_pose.visible = false
	carry_walk.visible = false
	carry_jump.visible = false
	carry_walk.stop()
	sprite.play(&"pular")
