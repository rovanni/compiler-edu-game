extends CharacterBody2D


signal perdeu_coracao
signal morreu

@export var velocidade := 250.0
@export var forca_pulo := 575.0
@export var gravidade := 1200.0

var coracoes := 3
var posicao_inicial := Vector2.ZERO
var pode_receber_dano := true
var estava_caindo := false
var controles_ativos := true

@onready var sprite := $AnimatedSprite2D

func _ready():

	# Guarda onde o jogador começou o nível
	posicao_inicial = global_position
	sprite.play("parado")

func _physics_process(delta):
	if not controles_ativos:
		return
		
	if not is_on_floor():

		velocity.y += gravidade * delta

	else:

		if velocity.y > 0:
			velocity.y = 0
			
	var direcao := Input.get_axis(
		"esquerda",
		"direita"
	)
	velocity.x = direcao * velocidade
	
	if direcao != 0:

		sprite.flip_h = direcao < 0
		
	if Input.is_action_just_pressed("pular") and is_on_floor():
		velocity.y = -forca_pulo
		SoundManager.play_jump()

	estava_caindo = (
		velocity.y > 0
		and not is_on_floor()
	)
	if not is_on_floor():

		sprite.play("pular")

	elif direcao != 0:

		sprite.play("andar")
		SoundManager.play_footstep()

	else:

		sprite.play("parado")

	move_and_slide()
	
func set_controls_enabled(enabled: bool) -> void:
	controles_ativos = enabled
	if not enabled:
		velocity = Vector2.ZERO
		sprite.play("parado")

func receber_dano():

	# Evita receber vários danos seguidos
	if not pode_receber_dano:

		return


	pode_receber_dano = false
	coracoes -= 1
	SoundManager.play_hurt()
	
	perdeu_coracao.emit()

	if coracoes <= 0:
		morreu.emit()

		return

	global_position = posicao_inicial

	velocity = Vector2.ZERO

	await get_tree().create_timer(0.7).timeout


	pode_receber_dano = true
