extends CharacterBody2D

@export var caractere: String = "?"

@onready var label = $Label
@onready var area = $Area2D


func _ready():

	label.text = caractere

	if not area.body_entered.is_connected(_on_area_body_entered):
		area.body_entered.connect(_on_area_body_entered)


func _on_area_body_entered(body):

	if not body.has_method("receber_dano"):
		return

	if body.global_position.y >= global_position.y:
		return

	if body.velocity.y <= 0:
		return

	body.velocity.y = -250

	body.receber_dano()
