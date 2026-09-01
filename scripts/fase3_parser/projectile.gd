class_name Projectile
extends Area2D

@export var speed: float = 400.0
@export var is_enemy_projectile: bool = true

var target: Node2D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func set_slime_attack_sprite() -> void:
	var color_rect = get_node_or_null("ColorRect")
	if color_rect:
		color_rect.visible = false
		
	var sf = EffectHelper.create_sprite_frames("res://assets/fase3_parser/sprites/slime-attack.png", "default", true, 12.0)
	if sf:
		var anim = AnimatedSprite2D.new()
		anim.sprite_frames = sf
		var tex = load("res://assets/fase3_parser/sprites/slime-attack.png") as Texture2D
		if tex and tex.get_height() > 0:
			var s = 64.0 / float(tex.get_height())
			anim.scale = Vector2(s, s)
		add_child(anim)
		anim.play("default")

func set_final_attack_sprite() -> void:
	var color_rect = get_node_or_null("ColorRect")
	if color_rect:
		color_rect.visible = false
		
	var tex = load("res://assets/fase3_parser/sprites/final-atack.png") as Texture2D
	if not tex:
		return
		
	var sf = SpriteFrames.new()
	if not sf.has_animation("default"):
		sf.add_animation("default")
	sf.set_animation_loop("default", true)
	sf.set_animation_speed("default", 12.0)
	
	var count = 5
	var frame_w = float(tex.get_width()) / float(count)
	var frame_h = float(tex.get_height())
	
	for i in range(count):
		var atlas = AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(i * frame_w, 0, frame_w, frame_h)
		sf.add_frame("default", atlas)
		
	var anim = AnimatedSprite2D.new()
	anim.sprite_frames = sf
	if frame_h > 0:
		var s = 64.0 / frame_h
		anim.scale = Vector2(s, s)
	add_child(anim)
	anim.play("default")

func _physics_process(delta: float) -> void:
	if target != null and is_instance_valid(target):
		var direction = (target.global_position - global_position).normalized()
		global_position += direction * speed * delta
		rotation = direction.angle()
	else:
		# Se perdeu o alvo, destrói
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if is_enemy_projectile:
		if body.is_in_group("player") or body.name == "Player":
			if body.has_method("take_damage"):
				body.take_damage()
			queue_free()
	else:
		if body.is_in_group("boss") or body.name == "BossBody":
			if body.has_method("take_damage"):
				body.take_damage()
			queue_free()
