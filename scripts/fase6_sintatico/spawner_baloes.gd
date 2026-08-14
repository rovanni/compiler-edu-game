extends Node2D
class_name SpawnerBaloes
## Cria balões periodicamente. Garante que, a qualquer momento, exista NO
## MÁXIMO UM balão em tela carregando o símbolo que é "a vez dele" na
## expressão (o próximo token esperado). Isso evita que dois balões com o
## mesmo símbolo correto apareçam juntos e sejam contados como dois acertos.
##
## As cores dos balões são sorteadas de uma paleta (paleta_cores) e são
## puramente estéticas/distração — nunca indicam se o balão é certo ou
## errado. Isso é o que muda entre as fases 1/2/3 (mais cores = mais
## confuso visualmente, sem mudar a lógica).
##
## Viés de confusão: o "lixo" (balões que não são o próximo esperado) é
## sorteado majoritariamente do MESMO TIPO do que está sendo esperado no
## momento — se o próximo esperado é dígito, a maioria do lixo também é
## dígito; se é símbolo/operador, a maioria do lixo também é símbolo.
## Nunca 100%, para não virar previsível.

signal balao_criado(balao: Balao)

@export var cena_balao: PackedScene
@export var intervalo_spawn: float = 1.4
## Se <= 0, calculado automaticamente a partir da largura da viewport
## (descontando a posição X deste spawner) em _ready(), para os balões
## ocuparem a tela inteira em qualquer resolução.
@export var largura_area: float = 0.0
@export var margem_direita: float = 60.0
@export var pos_y_inicial: float = -40.0

## Dígitos "lixo" (0-9) disponíveis para confundir quando se espera dígito.
@export var digitos_lixo: Array[String] = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
## Símbolos/operadores "lixo" disponíveis para confundir quando se espera símbolo.
@export var simbolos_lixo: Array[String] = ["@", "#", "$", "%", "&", "?", ";", "*", "/", "-"]

## Chance (0.0 a 1.0) de tentar spawnar o próximo token correto a cada
## intervalo, quando não há nenhum balão-alvo vivo em tela.
@export var chance_token_correto: float = 0.45

## Fração do lixo que deve ser do MESMO TIPO do próximo esperado
## (dígito puxa mais dígito, símbolo puxa mais símbolo). 0.75 = 75% do
## tempo o lixo "combina" com o tipo esperado, 25% é do outro tipo, pra
## não ficar 100% previsível.
@export_range(0.0, 1.0) var vies_mesmo_tipo: float = 0.75

## Paleta de cores possíveis para os balões (estética/distração).
## Uma única cor = todos iguais (fase 1). Mais cores = mais confuso.
@export var paleta_cores: Array[Color] = [Color(0.55, 0.6, 0.75)]

var gerenciador: GerenciadorExpressao
var _timer: Timer
var _rng := RandomNumberGenerator.new()

## true enquanto existir em tela um balão carregando o símbolo "certo" atual.
## Impede que dois balões-alvo apareçam ao mesmo tempo.
var _balao_alvo_vivo := false

func _ready() -> void:
	if largura_area <= 0.0:
		var largura_tela := float(get_viewport_rect().size.x)
		largura_area = max(largura_tela - position.x - margem_direita, 100.0)

	_rng.randomize()
	_timer = Timer.new()
	_timer.wait_time = intervalo_spawn
	_timer.autostart = true
	_timer.timeout.connect(_spawnar)
	add_child(_timer)

func iniciar(gerenciador_expressao: GerenciadorExpressao) -> void:
	gerenciador = gerenciador_expressao
	gerenciador.token_correto_coletado.connect(_on_token_avancou)

## Aplica os valores de dificuldade/paleta vindos do ConfigFase da fase atual.
## Deve ser chamado antes de _ready() já ter criado o Timer (ou seja, antes
## do node entrar na árvore) ou, se já estiver rodando, atualizamos o timer.
func aplicar_config(config: ConfigFase) -> void:
	if config == null:
		return
	intervalo_spawn = config.intervalo_spawn
	chance_token_correto = config.chance_token_correto
	vies_mesmo_tipo = config.vies_mesmo_tipo
	if not config.paleta_cores.is_empty():
		paleta_cores = config.paleta_cores
	if _timer:
		_timer.wait_time = intervalo_spawn

func pausar(pausado: bool) -> void:
	_timer.paused = pausado

## Quando a expressão avança (token coletado corretamente), o próximo token
## passa a ser outro símbolo, então liberamos o spawn de um novo alvo.
func _on_token_avancou(_simbolo: String, _indice: int) -> void:
	_balao_alvo_vivo = false

func _spawnar() -> void:
	if gerenciador == null or cena_balao == null:
		return
	if gerenciador.indice_atual >= gerenciador.expressao.size():
		return # expressão já completa, para de spawnar

	var simbolo := _escolher_simbolo()
	if simbolo == "":
		return

	var eh_alvo := simbolo == gerenciador.proximo_esperado()
	if eh_alvo:
		_balao_alvo_vivo = true

	var balao: Balao = cena_balao.instantiate()
	balao.simbolo = simbolo
	balao.position = Vector2(_rng.randf_range(0, largura_area), pos_y_inicial)
	balao.cor_balao = _escolher_cor()
	add_child(balao)

	# Se esse balão-alvo for resolvido (chão ou estouro) sem passar pelo
	# gerenciador (ex: foi estourado por engano), também liberamos a trava,
	# senão nenhum novo alvo nasceria até o fim do jogo.
	if eh_alvo:
		balao.chegou_ao_chao.connect(_on_balao_alvo_resolvido_no_chao, CONNECT_ONE_SHOT)
		balao.estourado.connect(_on_balao_alvo_resolvido_estourado, CONNECT_ONE_SHOT)

	balao_criado.emit(balao)

func _on_balao_alvo_resolvido_no_chao(_simbolo: String, _posicao: Vector2) -> void:
	_balao_alvo_vivo = false

func _on_balao_alvo_resolvido_estourado(_simbolo: String) -> void:
	# _on_token_avancou já destrava no caso de acerto; aqui cobrimos o caso
	# de erro (estourou o alvo por engano) para não travar o spawn.
	_balao_alvo_vivo = false

func _escolher_cor() -> Color:
	if paleta_cores.is_empty():
		return Color(0.55, 0.6, 0.75)
	return paleta_cores[_rng.randi_range(0, paleta_cores.size() - 1)]

## Escolhe o símbolo do próximo balão. Retorna "" se não deve spawnar nada
## neste ciclo.
func _escolher_simbolo() -> String:
	var quer_token_correto := _rng.randf() < chance_token_correto

	if quer_token_correto and not _balao_alvo_vivo:
		return gerenciador.proximo_esperado()

	return _escolher_lixo()

## Escolhe um símbolo de "lixo", enviesado para o mesmo tipo (dígito ou
## símbolo) do que está sendo esperado no momento, para confundir mais.
func _escolher_lixo() -> String:
	var espera_digito := gerenciador.proximo_esperado_eh_digito()
	var usar_mesmo_tipo := _rng.randf() < vies_mesmo_tipo

	# "mesmo tipo do esperado" quer dizer: se espera dígito, usa lista de
	# dígitos; se espera símbolo, usa lista de símbolos. Caso contrário,
	# inverte para dar variedade e não ficar 100% previsível.
	var usar_digitos := espera_digito == usar_mesmo_tipo

	var lista := digitos_lixo if usar_digitos else simbolos_lixo
	if lista.is_empty():
		lista = simbolos_lixo if digitos_lixo.is_empty() else digitos_lixo
	if lista.is_empty():
		return "?"
	return lista[_rng.randi_range(0, lista.size() - 1)]
