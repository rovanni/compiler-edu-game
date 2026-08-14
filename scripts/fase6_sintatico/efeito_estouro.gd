extends AnimatedSprite2D
class_name EfeitoEstouro
## Efeito visual de "estouro" (estilhaços) tocado tanto quando um balão é
## clicado/eliminado quanto quando o balão correto cai e é coletado.
## Usa os placeholders SVG em assets/fase6_sintatico/estouro_*.svg — troque
## os arquivos quando tiver a arte final, a lógica não muda.
## Se autodestrói ao fim da animação.

func _ready() -> void:
	animation_finished.connect(queue_free)

## Cria e posiciona uma instância deste efeito na cena `pai`, na posição
## dada. Uso: EfeitoEstouro.tocar_em(pai, posicao_global)
static func tocar_em(pai: Node, posicao_global: Vector2) -> void:
	var cena: PackedScene = load("res://scenes/fase6_sintatico/efeito_estouro.tscn")
	var instancia := cena.instantiate()
	pai.add_child(instancia)
	instancia.global_position = posicao_global
