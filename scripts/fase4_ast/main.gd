extends Node2D

# --- Expressões pré-definidas (cada uma tem exatamente 5 tokens para 5 nós) ---
const EXPRESSOES := [
	{
		"expressao": "a + b * c",
		"nos": [
			{"rotulo": "RAIZ",       "token": "+"},
			{"rotulo": "FILHO ESQ.", "token": "a"},
			{"rotulo": "FILHO DIR.", "token": "*"},
			{"rotulo": "FOLHA",      "token": "b"},
			{"rotulo": "FOLHA",      "token": "c"},
		]
	},
	{
		"expressao": "x = y + 1",
		"nos": [
			{"rotulo": "RAIZ",       "token": "="},
			{"rotulo": "FILHO ESQ.", "token": "x"},
			{"rotulo": "FILHO DIR.", "token": "+"},
			{"rotulo": "FOLHA",      "token": "y"},
			{"rotulo": "FOLHA",      "token": "1"},
		]
	},
	{
		"expressao": "a * b + c",
		"nos": [
			{"rotulo": "RAIZ",       "token": "+"},
			{"rotulo": "FILHO ESQ.", "token": "*"},
			{"rotulo": "FILHO DIR.", "token": "c"},
			{"rotulo": "FOLHA",      "token": "a"},
			{"rotulo": "FOLHA",      "token": "b"},
		]
	},
]

var posicao_inicial: Vector2
var nos_ast: Array = []
var tokens_na_fila: Array = []
var token_atual: String = ""
var nos_preenchidos: int = 0
var total_nos: int = 0
var vidas: int = 3
var fase_concluida: bool = false
var expressao_atual: Dictionary = {}

@onready var hud              = $HUD
@onready var jogador          = $Jogador
@onready var portal           = $Portal
@onready var label_expressao  = $UIExpressao/VBox/LabelExpressao
@onready var label_vidas      = $UIVidas/LabelVidas

func _ready() -> void:
	posicao_inicial = jogador.global_position
	portal.hide()

	nos_ast = $Nos.get_children()
	total_nos = nos_ast.size()

	_inicializar_fase()

func _inicializar_fase() -> void:
	# Escolhe expressão aleatória
	expressao_atual = EXPRESSOES[randi() % EXPRESSOES.size()]
	label_expressao.text = expressao_atual["expressao"]

	var dados_nos: Array = expressao_atual["nos"]

	# Configura os nós usando apenas os 5 primeiros
	for i in range(min(nos_ast.size(), dados_nos.size())):
		var no = nos_ast[i]
		no.rotulo         = dados_nos[i]["rotulo"]
		no.token_esperado = dados_nos[i]["token"]
		no._ready()  # re-inicializa labels com novos valores
		# Conecta sinais apenas se ainda não conectados
		if not no.token_alocado_correto.is_connected(_on_no_preenchido):
			no.token_alocado_correto.connect(_on_no_preenchido)
		if not no.token_alocado_errado.is_connected(_on_no_erro):
			no.token_alocado_errado.connect(_on_no_erro)

	# Cria fila de tokens embaralhados (apenas os 5 tokens ativos)
	tokens_na_fila = []
	for i in range(min(nos_ast.size(), dados_nos.size())):
		tokens_na_fila.append(dados_nos[i]["token"])
	tokens_na_fila.shuffle()

	nos_preenchidos = 0
	fase_concluida  = false
	vidas           = 3

	_proximo_token()
	_atualizar_vidas()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://scenes/menu/menu.tscn")

	if event.is_action_pressed("interact") and not fase_concluida:
		_tentar_alocar()

func _tentar_alocar() -> void:
	for no in nos_ast:
		if no.jogador_proximo and not no.preenchido:
			no.receber_token(token_atual)
			return

func _on_no_preenchido() -> void:
	nos_preenchidos += 1
	if nos_preenchidos < total_nos:
		_proximo_token()
	else:
		_vencer()

func _on_no_erro() -> void:
	vidas -= 1
	_atualizar_vidas()
	hud.mostrar_instrucao("❌ Token errado! Tente outro nó.")
	await get_tree().create_timer(1.5).timeout
	if not fase_concluida:
		hud.mostrar_instrucao("Selecione um nó e pressione  E  para alocar")
	if vidas <= 0:
		_resetar_fase()

func _proximo_token() -> void:
	if tokens_na_fila.is_empty():
		return
	token_atual = tokens_na_fila.pop_front()
	hud.atualizar_token(token_atual)
	hud.mostrar_instrucao("Selecione um nó e pressione  E  para alocar")

func _atualizar_vidas() -> void:
	var texto := ""
	for i in range(vidas):
		texto += "❤️"
	label_vidas.text = texto if vidas > 0 else "💀"

func _resetar_fase() -> void:
	jogador.global_position = posicao_inicial
	jogador.velocity        = Vector2.ZERO

	# Reseta visual dos nós
	for no in nos_ast:
		no.preenchido    = false
		no.jogador_proximo = false
		no.label_token.text = "?"
		no._aplicar_cor(no.cor_vazia)

	# Reinicia tudo com nova expressão aleatória
	await get_tree().create_timer(0.3).timeout
	_inicializar_fase()

func _vencer() -> void:
	fase_concluida = true
	portal.show()
	hud.mostrar_instrucao("🎉 Fase concluída! Vá até o portal!")

func _on_portal_entered(body: Node2D) -> void:
	if body.name == "Jogador" and fase_concluida:
		get_tree().change_scene_to_file("res://scenes/menu/menu.tscn")
