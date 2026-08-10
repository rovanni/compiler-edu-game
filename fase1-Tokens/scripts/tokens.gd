extends Area2D

signal coletado

@export var texto: String = "int"

func _ready() -> void:
	$Label.text = texto

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Jogador":
		coletar()

func coletar() -> void:
	coletado.emit()

	hide()
	set_deferred("monitoring", false)

func resetar() -> void:
	show()
	set_deferred("monitoring", true)
