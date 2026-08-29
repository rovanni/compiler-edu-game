extends CharacterBody2D

signal fell_out

const SPEED := 220.0
const JUMP_VELOCITY := -540.0
const FALL_LIMIT := 780.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var carry_pose: Sprite2D = $CarryPose
@onready var carry_walk: AnimatedSprite2D = $CarryWalk
@onready var carry_jump: Sprite2D = $CarryJump
var controls_enabled := true
var spawn_position := Vector2.ZERO
var _fall_reported := false
var _exit_animation_active := false
var held_block
var _carrying_block := false

const BLOCK_DROP_OFFSET := Vector2(64, -70)


func _ready() -> void:
	spawn_position = global_position


func _physics_process(delta: float) -> void:
	if not controls_enabled:
		velocity = Vector2.ZERO
		if _exit_animation_active:
			sprite.play(&"pular")
			return
		atualizar_animacao()
		return
	if not is_on_floor():
		velocity += get_gravity() * delta
	if Input.is_action_just_pressed(&"jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		SoundManager.play_jump()
	if Input.is_action_just_pressed(&"interact"):
		_toggle_block()
	if Input.is_action_just_pressed(&"drop_down") and is_on_floor():
		global_position.y += 8.0
	var direction := Input.get_axis(&"move_left", &"move_right")
	if direction != 0.0:
		velocity.x = direction * SPEED
		if is_on_floor():
			SoundManager.play_footstep()
		sprite.flip_h = direction < 0.0
		carry_pose.flip_h = direction < 0.0
		carry_walk.flip_h = direction < 0.0
		carry_jump.flip_h = direction < 0.0
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
	if held_block and is_instance_valid(held_block):
		held_block.drop(get_tree().current_scene, spawn_position + BLOCK_DROP_OFFSET)
	held_block = null
	_set_carry_animation(false)
	global_position = spawn_position
	velocity = Vector2.ZERO
	_fall_reported = false


func set_controls_enabled(enabled: bool) -> void:
	controls_enabled = enabled
	if not enabled:
		velocity = Vector2.ZERO


func _toggle_block() -> void:
	if held_block and is_instance_valid(held_block):
		drop_held_block()
		return
	var nearest
	# Also catches a block resting directly on/above the head.
	var nearest_distance := 145.0
	for candidate in get_tree().get_nodes_in_group(&"carryable_block"):
		if not is_instance_valid(candidate) or candidate.is_placed or candidate.held:
			continue
		var offset: Vector2 = candidate.global_position - global_position
		var distance := offset.length()
		var reachable := distance < nearest_distance or (absf(offset.x) < 90.0 and absf(offset.y) < 145.0)
		if reachable and distance < nearest_distance:
			nearest = candidate
			nearest_distance = distance
	if nearest:
		nearest.pick_up(self)
		held_block = nearest
		SoundManager.play_lift()
		_set_carry_animation(true)


func drop_held_block() -> void:
	if held_block and is_instance_valid(held_block):
		held_block.drop(get_tree().current_scene, global_position + BLOCK_DROP_OFFSET)
	held_block = null
	_set_carry_animation(false)


func finish_block_delivery(block: Node) -> void:
	if held_block == block:
		held_block = null
		_set_carry_animation(false)


func play_exit_animation() -> void:
	_exit_animation_active = true
	var start_position := global_position + Vector2(0, 24)
	global_position = start_position
	modulate = Color(1, 1, 1, 0.0)
	scale = Vector2(0.72, 0.72)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position", spawn_position, 0.72)
	tween.tween_property(self, "modulate:a", 1.0, 0.42)
	tween.tween_property(self, "scale", Vector2.ONE, 0.72)
	await tween.finished
	_exit_animation_active = false
	sprite.play(&"idle")


func atualizar_animacao() -> void:
	if _carrying_block:
		if not is_on_floor():
			carry_pose.visible = false
			carry_walk.visible = false
			carry_walk.stop()
			carry_jump.visible = true
			return
		var walking := is_on_floor() and absf(velocity.x) > 0.1
		carry_pose.visible = not walking
		carry_walk.visible = walking
		carry_jump.visible = false
		if walking:
			carry_walk.play(&"andar_carregando")
		else:
			carry_walk.stop()
		return
	if not is_on_floor():
		sprite.play(&"pular")
	elif absf(velocity.x) > 0.1:
		sprite.play(&"andar")
	else:
		sprite.play(&"idle")


func _set_carry_animation(active: bool) -> void:
	# As poses de carga substituem a animação normal enquanto houver um bloco.
	_carrying_block = active
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
