extends Area2D

signal atingido

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Jogador":
		atingido.emit()
