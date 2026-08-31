extends Area2D
## Faixa sensível na parte inferior da tela. Quando um balão a atravessa,
## consideramos que ele "chegou ao chão" (o jogador optou por deixá-lo cair).

func _on_area_entered(area: Area2D) -> void:
	if area is Balao:
		area.cair_no_chao()
