extends Node2D
class_name SpawnerBaloes

signal balao_criado(balao: Balao)
signal chefe_pronto_para_spawn

const PROGRESSO_GATILHO_CHEFE := 0.5
const VIDA_MAXIMA := 40
const VIDAS_CHEFE := VIDA_MAXIMA
const VELOCIDADE_CHEFE := 18.0
const ESCALA_CHEFE := Vector2(2.0,2.0)
const QUANTIDADE_FILHOS_MIN := 6
const QUANTIDADE_FILHOS_MAX := 7
const MAX_FILHOS_FORTIFICADOS := 2
const CHANCE_FILHO_FORTIFICADO := 0.4
const COR_BALAO_EXPRESSAO := Color("4fca72")
const ESPACAMENTO_MIN_HORIZONTAL := 94.0
const ESPACAMENTO_MIN_VERTICAL := 112.0
const TENTATIVAS_POSICAO_LIVRE := 24

@export var cena_balao: PackedScene
@export var intervalo_spawn: float = 1.4
@export var largura_area: float = 0.0
@export var margem_esquerda: float = 45.0
@export var margem_direita: float = 45.0
@export var pos_y_inicial: float = -95.0

@export var digitos_lixo: Array[String] = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
@export var simbolos_lixo: Array[String] = ["@", "#", "$", "%", "&", "?", ";", "*", "/", "-"]

@export var chance_token_correto: float = 0.45
@export_range(0.0, 1.0) var vies_mesmo_tipo: float = 0.75
@export var paleta_cores: Array[Color] = [Color(0.55, 0.6, 0.75)]

var eh_fortificado = false
var chance_fortificado: float = 0.0
var tem_chefe: bool = false

var gerenciador: GerenciadorExpressao
var _timer: Timer
var _rng := RandomNumberGenerator.new()
var _balao_alvo_vivo := false
## Para cada caractere da expressão, há no máximo um balão vivo. Isso vale
## também para símbolos fora da ordem atual: um segundo "=" não pode ficar
## aguardando e mudar de significado depois que o primeiro for resolvido.
var _baloes_expressao_vivos: Dictionary = {}
var _chefe_solicitado := false
var _chefe_spawnado := false

func _ready() -> void:
	if largura_area <= 0.0:
		var largura_tela := float(get_viewport_rect().size.x)
		largura_area = max(largura_tela - position.x - margem_direita, 100.0)

	_rng.randomize()
	_timer = Timer.new()
	_timer.wait_time = intervalo_spawn
	_timer.autostart = false
	_timer.timeout.connect(_spawnar)
	add_child(_timer)


func iniciar(gerenciador_expressao: GerenciadorExpressao) -> void:
	gerenciador = gerenciador_expressao
	gerenciador.token_correto_coletado.connect(_on_token_avancou)

	# Mesmo a sub-fase do chefe começa normalmente. O chefe é solicitado
	# somente quando metade da expressão tiver sido completada.
	_timer.start()

func aplicar_config(config: ConfigFase) -> void:
	if config == null:
		return
	intervalo_spawn = config.intervalo_spawn
	chance_token_correto = config.chance_token_correto
	vies_mesmo_tipo = config.vies_mesmo_tipo

	chance_fortificado = config.chance_balao_fortificado
	tem_chefe = config.inicia_com_chefe

	if not config.paleta_cores.is_empty():
		paleta_cores = config.paleta_cores
	if _timer:
		_timer.wait_time = intervalo_spawn

func pausar(pausado: bool) -> void:
	_timer.paused = pausado

func _on_token_avancou(_simbolo: String, _indice: int) -> void:
	_balao_alvo_vivo = false
	# A coleta pode vir de uma callback de colisão. Adiamos o alerta para
	# fora do flush de física, sem depender de estado ainda não atualizado.
	call_deferred("_verificar_gatilho_chefe")

func _verificar_gatilho_chefe() -> void:
	if not tem_chefe or _chefe_solicitado or gerenciador == null:
		return

	var total := gerenciador.expressao.size()
	if total <= 0 or gerenciador.indice_atual >= total:
		return
	if float(gerenciador.indice_atual) / float(total) < PROGRESSO_GATILHO_CHEFE:
		return
	_chefe_solicitado = true
	_timer.stop()
	chefe_pronto_para_spawn.emit()

func spawnar_chefe() -> void:
	if _chefe_spawnado or cena_balao == null or gerenciador == null:
		return
	_chefe_spawnado = true
	var balao: Balao = cena_balao.instantiate()

	# O chefe nunca pode carregar um caractere da expressão, mesmo fora da
	# posição atual. Assim ele sempre é um alvo inválido inequívoco.
	var simbolo_chefe := "" #_escolher_lixo_invalido()

	balao.simbolo = simbolo_chefe
	balao.position = Vector2((margem_esquerda + largura_area) / 2.0, pos_y_inicial)
	balao.cor_balao = _cor_para_simbolo(simbolo_chefe)

	balao.vidas = VIDAS_CHEFE
	balao.eh_gigante = true
	balao.velocidade_queda = VELOCIDADE_CHEFE
	balao.scale = ESCALA_CHEFE

	# Conecta o sinal para gerar os balões de dentro dele ao morrer
	balao.precisa_gerar_filhos.connect(_on_balao_gigante_destruido)

	add_child(balao)
	balao_criado.emit(balao)

func _on_balao_gigante_destruido(pos_origem: Vector2) -> void:
	var qtd_filhos := _rng.randi_range(QUANTIDADE_FILHOS_MIN, QUANTIDADE_FILHOS_MAX)
	var fortificados_criados := 0
	var pos_origem_local := to_local(pos_origem)

	for _i in range(qtd_filhos):
		var filho: Balao = cena_balao.instantiate()

		# Sorteia os símbolos dos balões de dentro do chefe
		var simbolo := _escolher_simbolo()
		if simbolo == "":
			simbolo = _escolher_lixo_diferente_de(gerenciador.proximo_esperado())

		filho.simbolo = simbolo
		var eh_alvo := simbolo == gerenciador.proximo_esperado()

		# Espalha os filhos usando um arco para cima e pros lados
		var offset_x := _rng.randf_range(-180.0, 180.0)
		var offset_y := _rng.randf_range(-150.0, 20.0)

		var posicao_filho: Variant = _encontrar_posicao_livre(
			pos_origem_local.y + offset_y,
			clampf(pos_origem_local.x + offset_x, margem_esquerda, largura_area),
			180.0
		)
		if posicao_filho == null:
			filho.queue_free()
			continue
		filho.position = posicao_filho
		if eh_alvo:
			_balao_alvo_vivo = true
			filho.chegou_ao_chao.connect(_on_balao_alvo_resolvido_no_chao, CONNECT_ONE_SHOT)
			filho.estourado.connect(_on_balao_alvo_resolvido_estourado, CONNECT_ONE_SHOT)

		filho.cor_balao = _cor_para_simbolo(simbolo)

		if (
			not eh_alvo
			and fortificados_criados < MAX_FILHOS_FORTIFICADOS
			and _rng.randf() < CHANCE_FILHO_FORTIFICADO
		):
			filho.vidas = 2
			fortificados_criados += 1
			eh_fortificado = true

		add_child(filho)
		_registrar_balao_expressao_vivo(filho)
		balao_criado.emit(filho)

	# Somente após o balão gigante morrer, o spawner normal é ligado.
	_timer.start()

func _spawnar() -> void:
	if gerenciador == null or cena_balao == null:
		return
	if gerenciador.indice_atual >= gerenciador.expressao.size():
		return

	var simbolo := _escolher_simbolo()
	if simbolo == "":
		return

	var posicao_spawn: Variant = _encontrar_posicao_livre(pos_y_inicial)
	if posicao_spawn == null:
		return

	var eh_alvo := simbolo == gerenciador.proximo_esperado()
	if eh_alvo:
		_balao_alvo_vivo = true

	var balao: Balao = cena_balao.instantiate()
	balao.simbolo = simbolo
	balao.position = posicao_spawn
	balao.cor_balao = _cor_para_simbolo(simbolo)

	if not eh_alvo:
		if chance_fortificado > 0.0 and _rng.randf() < chance_fortificado:
			balao.vidas = 2
			eh_fortificado = true
	add_child(balao)

	if eh_alvo:
		balao.chegou_ao_chao.connect(_on_balao_alvo_resolvido_no_chao, CONNECT_ONE_SHOT)
		balao.estourado.connect(_on_balao_alvo_resolvido_estourado, CONNECT_ONE_SHOT)
	_registrar_balao_expressao_vivo(balao)

	balao_criado.emit(balao)

func _on_balao_alvo_resolvido_no_chao(_simbolo: String, _posicao: Vector2) -> void:
	_balao_alvo_vivo = false

func _on_balao_alvo_resolvido_estourado(_simbolo: String) -> void:
	_balao_alvo_vivo = false

func _registrar_balao_expressao_vivo(balao: Balao) -> void:
	if gerenciador == null or not gerenciador.faz_parte_da_expressao(balao.simbolo):
		return
	_baloes_expressao_vivos[balao.simbolo] = balao
	balao.estourado.connect(_on_balao_expressao_estourado.bind(balao.simbolo), CONNECT_ONE_SHOT)
	balao.chegou_ao_chao.connect(_on_balao_expressao_chegou_ao_chao.bind(balao.simbolo), CONNECT_ONE_SHOT)

func _on_balao_expressao_estourado(_simbolo_emitido: String, simbolo_rastreado: String) -> void:
	_baloes_expressao_vivos.erase(simbolo_rastreado)

func _on_balao_expressao_chegou_ao_chao(_simbolo_emitido: String, _posicao: Vector2, simbolo_rastreado: String) -> void:
	_baloes_expressao_vivos.erase(simbolo_rastreado)

func _simbolo_expressao_esta_vivo(simbolo: String) -> bool:
	var balao: Balao = _baloes_expressao_vivos.get(simbolo)
	if not is_instance_valid(balao) or balao.is_queued_for_deletion():
		_baloes_expressao_vivos.erase(simbolo)
		return false
	return true

func _escolher_cor() -> Color:
	if paleta_cores.is_empty():
		return Color(0.55, 0.6, 0.75)
	return paleta_cores[_rng.randi_range(0, paleta_cores.size() - 1)]

func _cor_para_simbolo(simbolo: String) -> Color:
	if gerenciador != null and gerenciador.faz_parte_da_expressao(simbolo):
		return COR_BALAO_EXPRESSAO
	return _escolher_cor()

## Quando a área está ocupada, o timer tenta novamente no próximo intervalo
## em vez de inserir dois balões colados. A mesma regra vale para os filhos
## liberados pelo chefe, nos dois eixos.
func _encontrar_posicao_livre(y: float, centro_x: float = -1.0, alcance_x: float = -1.0) -> Variant:
	var minimo_x := margem_esquerda if alcance_x < 0.0 else maxf(margem_esquerda, centro_x - alcance_x)
	var maximo_x := largura_area if alcance_x < 0.0 else minf(largura_area, centro_x + alcance_x)
	for _tentativa in range(TENTATIVAS_POSICAO_LIVRE):
		var candidata := Vector2(_rng.randf_range(minimo_x, maximo_x), y)
		if _posicao_respeita_espacamento(candidata):
			return candidata
	return null

func _posicao_respeita_espacamento(candidata: Vector2) -> bool:
	for filho in get_children():
		if not filho is Balao or not is_instance_valid(filho):
			continue
		var distancia_x := absf(filho.position.x - candidata.x)
		var distancia_y := absf(filho.position.y - candidata.y)
		if distancia_x < ESPACAMENTO_MIN_HORIZONTAL and distancia_y < ESPACAMENTO_MIN_VERTICAL:
			return false
	return true

func _escolher_simbolo() -> String:
	var quer_token_correto := _rng.randf() < chance_token_correto
	if quer_token_correto and not _simbolo_expressao_esta_vivo(gerenciador.proximo_esperado()):
		return gerenciador.proximo_esperado()
	# Todo caractere válido já vivo é excluído, não só o próximo. Isso evita
	# duplicatas que se tornariam "certas" depois que a expressão avançar.
	return _escolher_lixo_diferente_de(gerenciador.proximo_esperado())

func _escolher_lixo() -> String:
	var espera_digito := gerenciador.proximo_esperado_eh_digito()
	var usar_mesmo_tipo := _rng.randf() < vies_mesmo_tipo
	var usar_digitos := espera_digito == usar_mesmo_tipo
	var lista := digitos_lixo if usar_digitos else simbolos_lixo

	if lista.is_empty():
		lista = simbolos_lixo if digitos_lixo.is_empty() else digitos_lixo
	if lista.is_empty():
		return "?"
	return lista[_rng.randi_range(0, lista.size() - 1)]

func _escolher_lixo_diferente_de(simbolo_bloqueado: String) -> String:
	for _tentativa in range(12):
		var candidato := _escolher_lixo()
		if candidato != simbolo_bloqueado and not _simbolo_expressao_esta_vivo(candidato):
			return candidato
	# Fallback determinístico para configurações personalizadas com listas
	# reduzidas: ainda assim, nunca devolve o símbolo que já está protegido.
	for candidato in digitos_lixo + simbolos_lixo:
		if candidato != simbolo_bloqueado and not _simbolo_expressao_esta_vivo(candidato):
			return candidato
	return "§" if simbolo_bloqueado != "§" else "@"

func _escolher_lixo_invalido() -> String:
	var candidatos: Array[String] = []
	for simbolo in digitos_lixo + simbolos_lixo:
		if not gerenciador.faz_parte_da_expressao(simbolo) and simbolo not in candidatos:
			candidatos.append(simbolo)
	if candidatos.is_empty():
		return "§"
	return candidatos[_rng.randi_range(0, candidatos.size() - 1)]
