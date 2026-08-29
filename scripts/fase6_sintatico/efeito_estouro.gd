extends Node2D
class_name EfeitoEstouro

@onready var animacao: AnimatedSprite2D = $Animacao
@onready var som: AudioStreamPlayer = $Som

func _ready() -> void:
	animacao.animation_finished.connect(_on_animacao_finalizada)
	som.pitch_scale = randf_range(0.96, 1.04)
	som.play()

func _on_animacao_finalizada() -> void:
	animacao.hide()
	if som.playing:
		await som.finished
	queue_free()

## Cria e posiciona uma instância deste efeito na cena `pai`, na posição
## dada. Uso: EfeitoEstouro.tocar_em(pai, posicao_global)
static func tocar_em(pai: Node, posicao_global: Vector2) -> void:
	var cena: PackedScene = load("res://scenes/fase6_sintatico/efeito_estouro.tscn")
	var instancia := cena.instantiate()
	pai.add_child(instancia)
	instancia.global_position = posicao_global
