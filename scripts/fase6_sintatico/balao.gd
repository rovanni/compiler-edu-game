extends Area2D
class_name Balao

signal estourado(simbolo: String)
signal chegou_ao_chao(simbolo: String, posicao: Vector2)
# Novo sinal para o Balão Gigante avisar o Spawner que deve soltar os filhos
signal precisa_gerar_filhos(posicao: Vector2)

@export var simbolo: String = "x"
@export var velocidade_queda: float = 90.0
@export var cor_balao: Color = Color(0.55, 0.6, 0.75)

# Variáveis para controle de vidas e status
var vidas: int = 1
var eh_gigante: bool = false
var _ja_resolvido := false

@onready var label: Label = $Label
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	if label:
		label.text = simbolo
	if sprite:
		sprite.self_modulate = cor_balao

func definir_cor(cor: Color) -> void:
	cor_balao = cor
	if sprite:
		sprite.self_modulate = cor_balao

func _process(delta: float) -> void:
	if _ja_resolvido:
		return
	position.y += velocidade_queda * delta

func estourar() -> void:
	if _ja_resolvido:
		return
		
	vidas -= 1
	
	# Feedback visual simples se o balão ainda não estourar (Fortificado ou Gigante)
	if vidas > 0:
		if sprite:
			sprite.self_modulate = sprite.self_modulate.darkened(0.2) # Escurece a cor atual
		scale *= 0.9 # Encolhe ligeiramente a cada "hit"
		return

	_ja_resolvido = true

	# Se for o balão gigante, emite o sinal antes de sumir
	if eh_gigante:
		precisa_gerar_filhos.emit(global_position)

	EfeitoEstouro.tocar_em(get_parent(), global_position)
	estourado.emit(simbolo)
	queue_free()

func cair_no_chao() -> void:
	if _ja_resolvido:
		return
	_ja_resolvido = true
	chegou_ao_chao.emit(simbolo, global_position)
	queue_free()
