extends CharacterBody2D

signal monstro_morreu

@export var caractere: String = "?"

@onready var sprite_vivo := $AnimatedSprite2D
@onready var sprite_morto := $AnimatedSprite2D_morto
@onready var label := $Label
@onready var area := $Area2D

var morto := false

func _ready():
	label.text = caractere
	sprite_vivo.visible = true
	sprite_morto.visible = false
	sprite_vivo.play("vivo")
	sprite_morto.z_index = 0

	if not area.body_entered.is_connected(_on_area_body_entered):
		area.body_entered.connect(_on_area_body_entered)

func _on_area_body_entered(body):
	if morto:
		return
	if not body.has_method("receber_dano"):
		return
	if not body.estava_caindo:
		return
	morrer(body)

func morrer(jogador):
	morto = true
	area.set_deferred("monitoring", false)
	$CollisionShape2D.set_deferred("disabled", true)
	jogador.velocity.y = -250

	sprite_vivo.visible = false
	sprite_morto.visible = true
	sprite_morto.z_index = -1
	sprite_morto.play("morto")

	SoundManager.play_confirmation()
	GameManager.register_correct_action()

	monstro_morreu.emit()

	await sprite_morto.animation_finished
	queue_free()
