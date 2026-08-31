extends CharacterBody2D


signal perdeu_coracao
signal morreu


@export var velocidade := 250.0
@export var forca_pulo := 600.0
@export var gravidade := 1200.0

var coracoes := 3


var posicao_inicial := Vector2.ZERO

var pode_receber_dano := true

var estava_caindo := false


@onready var sprite := $AnimatedSprite2D


func _ready():

	posicao_inicial = global_position
	sprite.play("parado")


func _physics_process(delta):

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


	estava_caindo = velocity.y > 0 and not is_on_floor()


	if not is_on_floor():

		sprite.play("pular")

	elif direcao != 0:

		sprite.play("andar")

	else:

		sprite.play("parado")


	move_and_slide()
	


func receber_dano():

	if not pode_receber_dano:

		return

	pode_receber_dano = false

	coracoes -= 1



	perdeu_coracao.emit()


	if coracoes <= 0:


		morreu.emit()

		return


	global_position = posicao_inicial

	velocity = Vector2.ZERO


	await get_tree().create_timer(0.7).timeout


	pode_receber_dano = true
