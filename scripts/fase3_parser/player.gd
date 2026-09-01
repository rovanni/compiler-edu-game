extends CharacterBody2D

@export var speed: float = 300.0
@export var acceleration: float = 1800.0
@export var friction: float = 1500.0

## Multiplicador de tamanho para a animação "idle" (ex: 1.1 para aumentar 10%)
@export var idle_scale_multiplier: float = 1.1

var can_move: bool = true

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var base_scale: Vector2 = animated_sprite.scale if animated_sprite else Vector2.ONE

# Variáveis globais para o jogador
static var max_lives: int = 3
static var current_lives: int = 3

signal player_died
signal player_took_damage(new_lives)

func _ready() -> void:
	add_to_group("player")
	can_move = true
	if current_lives <= 0:
		current_lives = max_lives
	if animated_sprite:
		animated_sprite.visible = true
		base_scale = animated_sprite.scale
	_setup_camera_limits()

func take_damage() -> void:
	current_lives -= 1
	if SoundManager:
		SoundManager.play_hurt()
	player_took_damage.emit(current_lives)
	if current_lives <= 0:
		die()

func die() -> void:
	can_move = false
	var parent = get_parent()
	if parent:
		EffectHelper.play_one_shot_effect(parent, "res://assets/fase3_parser/sprites/dying-effect.png", global_position, 140.0, 12.0)
		get_tree().create_timer(0.35).timeout.connect(func():
			if animated_sprite:
				animated_sprite.visible = false
		)
	player_died.emit()

func _physics_process(delta: float) -> void:
	if not can_move:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		move_and_slide()
		_update_animation(Vector2.ZERO)
		return
	
	var input_direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if input_direction == Vector2.ZERO:
		var x := 0.0
		var y := 0.0
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): x -= 1.0
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): x += 1.0
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): y -= 1.0
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): y += 1.0
		if x != 0.0 or y != 0.0:
			input_direction = Vector2(x, y).normalized()
	
	if input_direction != Vector2.ZERO:
		velocity = velocity.move_toward(input_direction.normalized() * speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		
	move_and_slide()
	_clamp_to_background()
	_update_animation(input_direction)

func _clamp_to_background() -> void:
	var parent := get_parent()
	if not parent:
		return
	var bg := parent.get_node_or_null("Background") as Sprite2D
	if bg and bg.texture:
		var bg_size := bg.texture.get_size() * bg.scale
		var half_w := bg_size.x / 2.0
		var half_h := bg_size.y / 2.0
		var center := bg.global_position
		var margin := 60.0
		global_position.x = clamp(global_position.x, center.x - half_w + margin, center.x + half_w - margin)
		global_position.y = clamp(global_position.y, center.y - half_h + margin, center.y + half_h - margin)

func _update_animation(input_direction: Vector2) -> void:
	if animated_sprite == null:
		return
		
	# Ajusta a orientação (flip_h): olhando para a direita se mover para direita, para a esquerda se mover para esquerda
	if input_direction.x > 0:
		animated_sprite.flip_h = false
	elif input_direction.x < 0:
		animated_sprite.flip_h = true
		
	# Toca a animação correspondente e ajusta a escala dinamicamente
	if velocity.length() > 5.0:
		animated_sprite.scale = base_scale
		animated_sprite.play("running")
	else:
		animated_sprite.scale = base_scale * idle_scale_multiplier
		animated_sprite.play("idle")

func _setup_camera_limits() -> void:
	var camera := get_node_or_null("Camera2D") as Camera2D
	if not camera:
		return
		
	var parent := get_parent()
	if not parent:
		return
		
	var background := parent.get_node_or_null("Background")
	if background:
		if background is Sprite2D:
			var sprite := background as Sprite2D
			if sprite.texture:
				var rect := sprite.get_rect()
				var size := rect.size * sprite.scale
				var pos := sprite.global_position
				if sprite.centered:
					pos -= size / 2.0
				camera.limit_left = int(pos.x)
				camera.limit_top = int(pos.y)
				camera.limit_right = int(pos.x + size.x)
				camera.limit_bottom = int(pos.y + size.y)
		elif background is ColorRect:
			var color_rect := background as ColorRect
			var pos := color_rect.global_position
			var size := color_rect.size
			camera.limit_left = int(pos.x)
			camera.limit_top = int(pos.y)
			camera.limit_right = int(pos.x + size.x)
			camera.limit_bottom = int(pos.y + size.y)
