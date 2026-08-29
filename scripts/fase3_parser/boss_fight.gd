extends Node2D

@onready var title_label: Label = $CanvasLayer/UI/TitleLabel
@onready var desc_label: Label = $CanvasLayer/UI/DescLabel
@onready var boss_block: ColorRect = $Arena/BossBody/BossBlock
@onready var boss_name_label: Label = $Arena/BossBody/BossBlock/BossNameLabel
@onready var background_sprite: Sprite2D = $Background
@onready var health_bar: ProgressBar = $CanvasLayer/UI/BossHealthBar
@onready var hearts_container: HBoxContainer = $CanvasLayer/UI/HeartsContainer if $CanvasLayer/UI.has_node("HeartsContainer") else null
@onready var lives_label: Label = $CanvasLayer/UI/LivesLabel if $CanvasLayer/UI.has_node("LivesLabel") else null
@onready var return_button: Button = $CanvasLayer/UI/ReturnButton
@onready var boss_body: StaticBody2D = $Arena/BossBody
@onready var player: CharacterBody2D = $Player
@onready var plates_node: Node2D = $Arena/Plates
@onready var exit_portal: Area2D = $Arena/ExitPortal
@onready var boss_anim: AnimatedSprite2D = $Arena/BossBody/AnimatedSprite2D if $Arena/BossBody.has_node("AnimatedSprite2D") else null

const HEART_TEXTURE_PATH: String = "res://assets/fase3_parser/sprites/heart.png"
var full_heart_tex: AtlasTexture
var empty_heart_tex: AtlasTexture
var heart_rects: Array[TextureRect] = []

@export var arena_boss_name: String = ""
@export var arena_boss_id: String = ""
@export var arena_boss_color: Color = Color(0, 0, 0, 0)


static var current_boss_id: String = "boss_1"
static var current_boss_name: String = "Boss 1"
static var current_boss_color: Color = Color(0.9, 0.2, 0.2)
static var current_boss_bg_path: String = ""
static var show_hints: bool = false

var boss_health: int = 3
var expected_sequence: Array = []
var current_sequence: Array = []
var is_fight_active: bool = true

var possible_codes: Array = [
	["var", "x", "=", "10"],
	["if", "(", "true", ")"],
	["print", "(", "\"ola\"", ")"],
	["func", "main", "(", ")"]
]

const PROJECTILE_SCENE = preload("res://scenes/fase3_parser/projectile.tscn")

func _is_gosma() -> bool:
	return current_boss_name.to_lower() == "gosma" or current_boss_id == "boss_gosma_green"

func _is_fantasma() -> bool:
	return current_boss_name.to_lower() == "fantasma" or current_boss_id == "boss_fantasma_blue" or current_boss_id == "boss_3"

func _ready() -> void:
	_init_hearts_ui()
	if arena_boss_name != "":
		current_boss_name = arena_boss_name
	if arena_boss_id != "":
		current_boss_id = arena_boss_id
	if arena_boss_color != Color(0, 0, 0, 0):
		current_boss_color = arena_boss_color

	if title_label:
		title_label.text = "FASE DE COMBATE: " + current_boss_name.to_upper()
	if desc_label:
		desc_label.text = "Pise nas placas na ordem correta para atacar!"
	
	if _is_gosma():
		if boss_block:
			boss_block.hide()
		if boss_anim:
			boss_anim.show()
			boss_anim.scale = Vector2(0.45, 0.45)
			boss_anim.animation = "slime_attacking"
			if boss_anim.sprite_frames.has_animation("slime_attacking"):
				boss_anim.sprite_frames.set_animation_loop("slime_attacking", false)
			boss_anim.stop()
			boss_anim.frame = 0

	elif _is_fantasma():
		if boss_block:
			boss_block.hide()
		if boss_anim:
			boss_anim.show()
			boss_anim.scale = Vector2(0.12, 0.12)
			boss_anim.animation = "ghost_attacking"
			if boss_anim.sprite_frames.has_animation("ghost_attacking"):
				boss_anim.sprite_frames.set_animation_loop("ghost_attacking", false)
			boss_anim.stop()
			boss_anim.frame = 0
	else:
		if boss_block:
			boss_block.show()
			boss_block.color = current_boss_color
		if boss_anim:
			boss_anim.hide()
			
	if boss_name_label:
		boss_name_label.text = current_boss_name.to_upper()
	if background_sprite and current_boss_bg_path != "":
		var bg_tex = load(current_boss_bg_path)
		if bg_tex:
			background_sprite.texture = bg_tex
			
	if player:
		player.player_took_damage.connect(_on_player_took_damage)
		player.player_died.connect(_on_player_died)
		update_lives_ui(player.current_lives)
		EffectHelper.play_one_shot_effect(self, "res://assets/fase3_parser/sprites/smoke_burst.png", player.global_position, 128.0, 15.0)
		
	if plates_node:
		for plate in plates_node.get_children():
			if plate is PressurePlate:
				if not plate.plate_pressed.is_connected(_on_plate_pressed):
					plate.plate_pressed.connect(_on_plate_pressed)

	if exit_portal:
		exit_portal.body_entered.connect(_on_exit_portal_entered)
		_setup_exit_portal_animation()
		
	# Inicia automaticamente animações decorativas/cenário (como chamas)
	_start_ambient_animations(self)

func _setup_exit_portal_animation() -> void:
	if not exit_portal:
		return
		
	var anim_sprite = exit_portal.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if not anim_sprite:
		anim_sprite = exit_portal.get_node_or_null("PortalAnim") as AnimatedSprite2D
		
	var color_rect = exit_portal.get_node_or_null("ColorRect")
	
	if anim_sprite and anim_sprite.sprite_frames:
		if color_rect:
			color_rect.visible = false
		if not anim_sprite.is_playing():
			anim_sprite.play()
			
	_generate_new_puzzle()

func _generate_new_puzzle() -> void:
	if not is_fight_active: return
	
	var plates = []
	if plates_node:
		for child in plates_node.get_children():
			if child is PressurePlate:
				plates.append(child)
				
	var active_plates_count = plates.size()
	if active_plates_count == 0:
		return
		
	var possible_codes_for_level = []
	if active_plates_count <= 4:
		possible_codes_for_level = [
			["var", "x", "=", "10"],
			["if", "(", "true", ")"],
			["print", "(", "\"ola\"", ")"],
			["func", "main", "(", ")"],
			["y", "+=", "5", ";"]
		]
	elif active_plates_count == 5:
		possible_codes_for_level = [
			["var", "x", "=", "10", ";"],
			["if", "(", "x", ">", "0"],
			["print", "(", "\"ola\"", ")", ";"],
			["while", "(", "true", ")", "{"],
			["return", "x", "+", "y", ";"]
		]
	else: # >= 6
		possible_codes_for_level = [
			["var", "x", "=", "10", ";", "print(x)"],
			["if", "(", "x", "==", "5", ")"],
			["for", "i", "in", "range", "(", "10)"],
			["while", "(", "true", ")", "{", "}"]
		]
	
	var random_code = possible_codes_for_level[randi() % possible_codes_for_level.size()]
	expected_sequence = random_code.duplicate()
	
	var shuffled_code = random_code.duplicate()
	shuffled_code.shuffle()
	
	if plates_node:
		for i in range(plates.size()):
			if i < shuffled_code.size():
				plates[i].set_value(shuffled_code[i])
				plates[i].reset_plate()
	
	current_sequence.clear()
	if desc_label:
		if show_hints:
			desc_label.text = "Monte o código logicamente:\n" + " ".join(expected_sequence)
		else:
			desc_label.text = "Monte o código na ordem correta!"

func _on_plate_pressed(plate_value: String) -> void:
	if not is_fight_active: return
	
	current_sequence.append(plate_value)
	
	if current_sequence.size() == expected_sequence.size():
		_check_sequence()

func _check_sequence() -> void:
	var is_correct = true
	for i in range(expected_sequence.size()):
		if current_sequence[i] != expected_sequence[i]:
			is_correct = false
			break
			
	if is_correct:
		_spawn_projectile(player.global_position, boss_body, false)
		desc_label.text = "SUCESSO! Você disparou contra o chefão!"
		await get_tree().create_timer(1.5).timeout
	else:
		desc_label.text = "SINTAXE INVÁLIDA! O chefão disparou contra você!"
		
		if _is_gosma() and boss_anim:
			if boss_anim.sprite_frames.has_animation("slime_attacking"):
				boss_anim.sprite_frames.set_animation_loop("slime_attacking", false)
			boss_anim.animation = "slime_attacking"
			boss_anim.frame = 0
			boss_anim.play("slime_attacking")
			
			# Aguarda até o frame 7 da animação para disparar o projétil
			while boss_anim.is_playing() and boss_anim.frame < 7:
				await boss_anim.frame_changed
			
			if is_fight_active and is_instance_valid(boss_body):
				_spawn_projectile(boss_body.global_position, player, true)
			
			# Aguarda o término da animação do ataque
			if boss_anim.is_playing():
				await boss_anim.animation_finished
			
			# Mantém o boss parado no primeiro frame (frame 0)
			boss_anim.stop()
			boss_anim.frame = 0
			
			await get_tree().create_timer(0.5).timeout
		elif _is_fantasma() and boss_anim:
			if boss_anim.sprite_frames.has_animation("ghost_attacking"):
				boss_anim.sprite_frames.set_animation_loop("ghost_attacking", false)
			boss_anim.animation = "ghost_attacking"
			boss_anim.frame = 0
			boss_anim.play("ghost_attacking")
			
			# Aguarda até o frame 6 da animação para disparar o projétil
			while boss_anim.is_playing() and boss_anim.frame < 6:
				await boss_anim.frame_changed
			
			if is_fight_active and is_instance_valid(boss_body):
				_spawn_projectile(boss_body.global_position, player, true)
			
			# Aguarda o término da animação do ataque
			if boss_anim.is_playing():
				await boss_anim.animation_finished
			
			# Mantém o boss parado no primeiro frame (frame 0)
			boss_anim.stop()
			boss_anim.frame = 0
			
			await get_tree().create_timer(0.5).timeout
		else:
			_spawn_projectile(boss_body.global_position, player, true)
			await get_tree().create_timer(1.5).timeout
		
	if is_fight_active:
		_generate_new_puzzle()

func _spawn_projectile(spawn_pos: Vector2, target_node: Node2D, is_enemy: bool) -> void:
	var proj = PROJECTILE_SCENE.instantiate()
	proj.global_position = spawn_pos
	proj.target = target_node
	proj.is_enemy_projectile = is_enemy
	
	if is_enemy and _is_gosma():
		if proj.has_method("set_slime_attack_sprite"):
			proj.set_slime_attack_sprite()
	else:
		var color_rect = proj.get_node_or_null("ColorRect")
		if color_rect:
			color_rect.color = Color(1, 0, 0) if is_enemy else Color(0, 0.8, 1)
		
	add_child.call_deferred(proj)

func boss_take_damage() -> void:
	if not is_fight_active: return
	
	boss_health -= 1
	if health_bar:
		health_bar.value = boss_health
		
	if boss_health <= 0:
		is_fight_active = false
		desc_label.text = "CHEFÃO DERROTADO! Vidas restauradas."
		if player:
			player.current_lives = player.max_lives
			update_lives_ui(player.current_lives)
			
		if boss_anim and boss_anim.visible:
			if _is_gosma() and boss_anim.sprite_frames.has_animation("slime_dying"):
				boss_anim.sprite_frames.set_animation_loop("slime_dying", false)
				boss_anim.play("slime_dying")
				await boss_anim.animation_finished
			
		if is_instance_valid(boss_body):
			boss_body.queue_free()
		if exit_portal:
			exit_portal.visible = true
			exit_portal.set_deferred("monitoring", true)

func _on_player_took_damage(new_lives: int) -> void:
	update_lives_ui(new_lives)

func _on_player_died() -> void:
	is_fight_active = false
	desc_label.text = "VOCÊ FOI DERROTADO! Retornando..."
	await get_tree().create_timer(2.0).timeout
	_return_to_main_room()

func _init_hearts_ui() -> void:
	var base_tex = load(HEART_TEXTURE_PATH) as Texture2D
	if base_tex:
		var tex_size = base_tex.get_size()
		var frame_w = tex_size.x / 2.0
		var frame_h = tex_size.y
		
		full_heart_tex = AtlasTexture.new()
		full_heart_tex.atlas = base_tex
		full_heart_tex.region = Rect2(0, 0, frame_w, frame_h)
		
		empty_heart_tex = AtlasTexture.new()
		empty_heart_tex.atlas = base_tex
		empty_heart_tex.region = Rect2(frame_w, 0, frame_w, frame_h)
	
	if lives_label:
		lives_label.visible = false
		
	var ui_node = $CanvasLayer/UI if has_node("CanvasLayer/UI") else null
	if hearts_container == null and ui_node != null:
		if ui_node.has_node("HeartsContainer"):
			hearts_container = ui_node.get_node("HeartsContainer") as HBoxContainer
		else:
			hearts_container = HBoxContainer.new()
			hearts_container.name = "HeartsContainer"
			hearts_container.offset_left = 40.0
			hearts_container.offset_top = 40.0
			hearts_container.offset_right = 180.0
			hearts_container.offset_bottom = 80.0
			hearts_container.add_theme_constant_override("separation", 8)
			ui_node.add_child(hearts_container)
			
	heart_rects.clear()
	if hearts_container:
		for child in hearts_container.get_children():
			if child is TextureRect:
				heart_rects.append(child)
				
		while heart_rects.size() < 3:
			var tr = TextureRect.new()
			tr.name = "Heart%d" % (heart_rects.size() + 1)
			hearts_container.add_child(tr)
			heart_rects.append(tr)
		
		for tr in heart_rects:
			tr.custom_minimum_size = Vector2(36, 36)
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			tr.pivot_offset = Vector2(18, 18)

func update_lives_ui(lives: int) -> void:
	if heart_rects.is_empty():
		_init_hearts_ui()
		
	for i in range(heart_rects.size()):
		var tr = heart_rects[i]
		if i < lives:
			tr.texture = full_heart_tex
		else:
			if tr.texture == full_heart_tex:
				var tween = create_tween()
				tween.tween_property(tr, "scale", Vector2(1.3, 1.3), 0.1).from(Vector2.ONE)
				tween.tween_property(tr, "scale", Vector2.ONE, 0.1)
			tr.texture = empty_heart_tex
			
	if lives_label and not hearts_container:
		var hearts = ""
		for i in range(lives):
			hearts += "❤️"
		lives_label.text = hearts

func _on_exit_portal_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		_return_to_main_room()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_return_to_main_room()

func _on_return_button_pressed() -> void:
	_return_to_main_room()

func _return_to_main_room() -> void:
	if player and player.current_lives <= 0:
		player.current_lives = player.max_lives
	get_tree().change_scene_to_file("res://scenes/fase3_parser/main_room.tscn")

func _start_ambient_animations(node: Node) -> void:
	for child in node.get_children():
		if child is AnimatedSprite2D and child != boss_anim:
			if player and (child == player.get_node_or_null("AnimatedSprite2D") or player.is_ancestor_of(child)):
				continue
			if child.sprite_frames:
				var anim_name = child.animation if (child.animation != "" and child.sprite_frames.has_animation(child.animation)) else child.sprite_frames.get_animation_names()[0]
				if not child.is_playing():
					child.play(anim_name)
		_start_ambient_animations(child)
