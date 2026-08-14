extends Area2D
class_name Balao
## Um balão que cai carregando um símbolo (token) matemático/sintático.
## Pode ser "estourado" (clique) ou deixado cair até o chão.
##
## Visual: usa o sprite placeholder em assets/fase6_sintatico/balao.svg,
## recolorido via `modulate` (Sprite2D.self_modulate) — troque o arquivo de
## textura quando tiver a arte final; a lógica de cor/recolorir não muda.
## A cor é puramente ESTÉTICA/distração — nunca indica se o balão é certo
## ou errado. Quem monta a fase (spawner) sorteia a cor de uma paleta.
##
## Efeito de estouro (estilhaços): toca tanto quando o balão é eliminado
## por clique quanto quando o balão CORRETO cai e é coletado (mesmo efeito
## visual nos dois casos).

signal estourado(simbolo: String)
signal chegou_ao_chao(simbolo: String, posicao: Vector2)

@export var simbolo: String = "x"
@export var velocidade_queda: float = 90.0
@export var cor_balao: Color = Color(0.55, 0.6, 0.75)

var _ja_resolvido := false

@onready var label: Label = $Label
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	if label:
		label.text = simbolo
	if sprite:
		sprite.self_modulate = cor_balao
	input_event.connect(_on_input_event)

## Define a cor deste balão (estética). Pode ser chamado antes ou depois
## de entrar na árvore.
func definir_cor(cor: Color) -> void:
	cor_balao = cor
	if sprite:
		sprite.self_modulate = cor_balao

func _process(delta: float) -> void:
	if _ja_resolvido:
		return
	position.y += velocidade_queda * delta

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if _ja_resolvido:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		estourar()

## Clique simples estoura o balão.
func estourar() -> void:
	if _ja_resolvido:
		return
	_ja_resolvido = true
	EfeitoEstouro.tocar_em(get_parent(), global_position)
	estourado.emit(simbolo)
	queue_free()

## Chamado pelo chão (Area2D) quando o balão chega embaixo sem ser estourado.
func cair_no_chao() -> void:
	if _ja_resolvido:
		return
	_ja_resolvido = true
	chegou_ao_chao.emit(simbolo, global_position)
	queue_free()
