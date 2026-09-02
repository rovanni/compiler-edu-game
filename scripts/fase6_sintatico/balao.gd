extends Area2D
class_name Balao

const SHADER_DESTAQUE := preload("res://assets/fase6_sintatico/destaque_pulsante.gdshader")

signal estourado(simbolo: String)
signal chegou_ao_chao(simbolo: String, posicao: Vector2)
# Novo sinal para o Balão Gigante avisar o Spawner que deve soltar os filhos
signal precisa_gerar_filhos(posicao: Vector2)

@export var simbolo: String = "x"
@export var velocidade_queda: float = 65.0
@export var cor_balao: Color = Color(0.55, 0.6, 0.75)

# Variáveis para controle de vidas e status
var vidas: int = 1
var eh_fortificado = false
var eh_gigante: bool = false
var _ja_resolvido := false
var _material_antes_destaque: Material = null
var _material_destaque: ShaderMaterial = null

@onready var label: Label = $Label
@onready var sprite: Sprite2D = $Sprite2D
@onready var sombra: Sprite2D = $Sombra
@onready var sprite_vida_cheia: Sprite2D = $normal
@onready var sprite_vida_2_tercos: Sprite2D = $danificado1
@onready var sprite_vida_1_terco: Sprite2D = $danificado2
@onready var animate: AnimationPlayer = $AnimationPlayer

@onready var blabel: Label = $Label
@onready var bsprite: Sprite2D = $Sprite2D
@onready var barma: Sprite2D = $arma

func _ready() -> void:
	if label:
		label.text = simbolo
	if sprite:
		_atualizar_cor_visual()

	_atualizar_visual_vida()
	_atualizar_visual_fortificado()

func definir_cor(cor: Color) -> void:
	cor_balao = cor
	if sprite:
		_atualizar_cor_visual()

func _atualizar_cor_visual() -> void:
	# Mantém a variedade da paleta sem sacrificar o contraste do balão.
	# A cor é decorativa; o símbolo textual continua sendo a pista principal.
	sprite.self_modulate = cor_balao.lerp(Color.WHITE, 0.42)

func _atualizar_visual_fortificado() -> void:
	if(eh_gigante):
		return

	var fortificado := vidas == 2

	blabel.visible = not fortificado
	bsprite.visible = not fortificado
	barma.visible = fortificado

	eh_fortificado = fortificado

func _atualizar_visual_vida() -> void:
	if not eh_gigante:
		return

	sprite.visible = false
	sombra.visible = false

	var porcentagem := float(vidas) / 22.0

	sprite_vida_cheia.visible = false
	sprite_vida_2_tercos.visible = false
	sprite_vida_1_terco.visible = false

	if porcentagem > 0.66:
		sprite_vida_cheia.visible = true

		if animate.current_animation != "move0":
			animate.play("move0")

	elif porcentagem > 0.33:
		sprite_vida_2_tercos.visible = true

		if animate.current_animation != "move1":
			animate.play("move1")

	elif porcentagem > 0.0:
		sprite_vida_1_terco.visible = true

		if animate.current_animation != "move2":
			animate.play("move2")

	else:
		animate.stop()


## Aplica um filtro somente durante o mini tutorial. A textura original não
## é modificada e qualquer material futuro do asset é restaurado ao sair.
func definir_destaque_visual(ativo: bool) -> void:
	if sprite == null:
		return
	if ativo:
		if _material_destaque != null:
			return
		_material_antes_destaque = sprite.material
		_material_destaque = ShaderMaterial.new()
		_material_destaque.shader = SHADER_DESTAQUE
		_material_destaque.set_shader_parameter("intensidade", 0.0)
		sprite.material = _material_destaque
	else:
		if _material_destaque == null:
			return
		sprite.material = _material_antes_destaque
		_material_antes_destaque = null
		_material_destaque = null

func definir_intensidade_destaque(intensidade: float) -> void:
	if _material_destaque:
		_material_destaque.set_shader_parameter("intensidade", intensidade)

func _process(delta: float) -> void:
	if _ja_resolvido:
		return
	position.y += velocidade_queda * delta

func estourar() -> void:
	if _ja_resolvido:
		return

	if(eh_fortificado):
		EfeitoEstouro.tocar_em(get_parent(), global_position)

	vidas -= 1

	_atualizar_visual_fortificado()
	_atualizar_visual_vida()

	if vidas > 0:
		return

	_ja_resolvido = true

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
