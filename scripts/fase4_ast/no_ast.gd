extends Area2D

signal token_alocado_correto
signal token_alocado_errado

@export var rotulo: String = "RAIZ"
@export var token_esperado: String = "+"

var preenchido: bool = false
var jogador_proximo: bool = false

@onready var label_tipo: Label = $LabelTipo
@onready var label_token: Label = $LabelToken
@onready var panel: Panel = $Panel
@onready var timer_pisca: Timer = $TimerPisca

var cor_vazia   := Color("#1a1a2e")
var cor_correta := Color("#1e7e34")
var cor_errada  := Color("#8b0000")
var _piscando   := false

func _ready() -> void:
	label_tipo.text = rotulo
	label_token.text = "?"
	_aplicar_cor(cor_vazia)

func receber_token(token: String) -> void:
	if preenchido:
		return
	if token == token_esperado:
		preenchido = true
		label_token.text = token
		_aplicar_cor(cor_correta)
		token_alocado_correto.emit()
	else:
		token_alocado_errado.emit()
		_piscar_erro()

func _piscar_erro() -> void:
	if _piscando:
		return
	_piscando = true
	_aplicar_cor(cor_errada)
	timer_pisca.start()

func _on_timer_pisca_timeout() -> void:
	_aplicar_cor(cor_vazia)
	_piscando = false

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Jogador":
		jogador_proximo = true

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Jogador":
		jogador_proximo = false

func _aplicar_cor(cor: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = cor
	style.border_color = Color("#e0c060")
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)
