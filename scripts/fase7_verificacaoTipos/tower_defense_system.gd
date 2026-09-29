## tower_defense_system.gd
##
## O "tabuleiro" da mecânica nova dos Níveis 2-4 (GDD seção 5-B, versão 2.0):
## Torre da Verificação no estilo Tower Defense (inspirado em Bloons TD, a
## pedido do Anibal — substitui o sistema de linhas/tabuleiro da v1.x).
##
## É um componente de DADOS, igual ao grid_system.gd que ele substitui: não
## desenha nada, não sabe de Sprite/Control/input, só a simulação. Quem cria
## um TowerDefenseSystem (a cena do nível, ainda não construída — falta arte
## de torre/inimigo) chama `inicializar()` com o DefenseLevelData daquele
## nível e escuta os sinais abaixo pra atualizar a UI.
##
## Conceito central: um inimigo anda por um caminho abstrato (progresso de
## 0.0 a 1.0). Cada slot de construção tem uma posição nesse caminho e um
## alcance; uma defesa (torre) construída num slot destrói automaticamente
## qualquer inimigo que passe dentro do alcance E cujo `defesa_correta`
## bata com o tipo da torre. A decisão de qual é a "defesa correta" de cada
## inimigo é sempre calculada com type_checker.gd (nunca duplicada aqui) —
## ver defense_level_data_factory.gd.
class_name TowerDefenseSystem
extends RefCounted

## Marca a torre especial "Erro de Tipo / Compilador" — não é um
## DataTypes.Tipo de verdade (que vai de 0 a 4), por isso um valor bem fora
## da faixa do enum, pra nunca colidir por acidente.
const DEFESA_ERRO := -99

signal defesa_construida(indice_slot: int, tipo_defesa)
signal defesa_trocada(indice_slot: int, tipo_antigo, tipo_novo)
signal defesa_recusada(indice_slot: int, motivo: String)
signal inimigo_spawnado(id: int, texto: String)
signal inimigo_destruido(id: int, pontos: int)
signal inimigo_escapou(id: int, dano: float)
signal pontuacao_atualizada(pontos: int)
signal compilador_atualizado(percentual: float)
signal onda_iniciada(indice: int)
signal onda_concluida(indice: int)
signal compilacao_falhou
signal vitoria

var slots: Array = [] # {posicao, alcance, ocupado, tipo_defesa}
var pontos: int = 0
var barra_compilador: float = 100.0
var inimigos_ativos: Array = []
var jogo_ativo: bool = true
var venceu: bool = false

var _config # DefenseLevelData
var _indice_onda: int = -1
var _tempo_onda: float = 0.0
var _fila_onda: Array = []
var _proximo_id: int = 0


func inicializar(config) -> void:
	_config = config
	pontos = config.pontos_iniciais
	barra_compilador = 100.0
	jogo_ativo = true
	venceu = false
	inimigos_ativos.clear()
	_proximo_id = 0

	slots.clear()
	for definicao in config.slots:
		slots.append({
			"posicao": definicao["posicao"],
			"alcance": definicao["alcance"],
			"ocupado": false,
			"tipo_defesa": null,
		})

	_indice_onda = -1
	_avancar_onda()


## Custo pra construir uma defesa de `tipo_defesa` neste nível (0 se não
## estiver definido explicitamente em custo_defesa — não deveria acontecer
## com dados bem formados, mas evita divisão feia por Dictionary vazio).
func custo_de(tipo_defesa) -> int:
	return _config.custo_defesa.get(tipo_defesa, 0)


## Tenta construir uma defesa de `tipo_defesa` no slot `indice_slot`.
## Retorna {"sucesso": bool, "motivo": String (só quando falha)}.
func construir_defesa(indice_slot: int, tipo_defesa) -> Dictionary:
	if not jogo_ativo:
		return _recusar(indice_slot, "jogo encerrado")
	if indice_slot < 0 or indice_slot >= slots.size():
		return _recusar(indice_slot, "slot inválido")

	var slot: Dictionary = slots[indice_slot]
	if slot["ocupado"]:
		return _recusar(indice_slot, "slot já ocupado")
	if not _config.tipos_disponiveis.has(tipo_defesa):
		return _recusar(indice_slot, "defesa indisponível neste nível")

	var custo := custo_de(tipo_defesa)
	if pontos < custo:
		return _recusar(indice_slot, "pontos insuficientes")

	pontos -= custo
	slot["ocupado"] = true
	slot["tipo_defesa"] = tipo_defesa
	defesa_construida.emit(indice_slot, tipo_defesa)
	pontuacao_atualizada.emit(pontos)
	return {"sucesso": true}


## Troca a defesa já construída no slot `indice_slot` por uma de
## `novo_tipo` (mecânica de troca de torre, pedida pelo Anibal — GDD 5-B.2).
## Cobra o custo do tipo NOVO, sem reembolso do que já foi gasto na torre
## antiga (é como comprar de novo, não um upgrade com desconto — evita
## qualquer forma de "lavar" pontos trocando pra frente e pra trás).
## Recusa se o slot estiver vazio (nesse caso é `construir_defesa`, não
## troca), se o tipo pedido já for o que está construído ali, se o tipo
## não estiver disponível neste nível, ou se faltar pontos pro custo novo.
## Retorna {"sucesso": bool, "motivo": String (só quando falha)}.
func trocar_defesa(indice_slot: int, novo_tipo) -> Dictionary:
	if not jogo_ativo:
		return _recusar(indice_slot, "jogo encerrado")
	if indice_slot < 0 or indice_slot >= slots.size():
		return _recusar(indice_slot, "slot inválido")

	var slot: Dictionary = slots[indice_slot]
	if not slot["ocupado"]:
		return _recusar(indice_slot, "slot vazio — construa uma defesa primeiro")
	if slot["tipo_defesa"] == novo_tipo:
		return _recusar(indice_slot, "já é esse tipo de defesa")
	if not _config.tipos_disponiveis.has(novo_tipo):
		return _recusar(indice_slot, "defesa indisponível neste nível")

	var custo := custo_de(novo_tipo)
	if pontos < custo:
		return _recusar(indice_slot, "pontos insuficientes pra trocar")

	pontos -= custo
	var tipo_antigo = slot["tipo_defesa"]
	slot["tipo_defesa"] = novo_tipo
	defesa_trocada.emit(indice_slot, tipo_antigo, novo_tipo)
	pontuacao_atualizada.emit(pontos)
	return {"sucesso": true}


func _recusar(indice_slot: int, motivo: String) -> Dictionary:
	defesa_recusada.emit(indice_slot, motivo)
	return {"sucesso": false, "motivo": motivo}


## Um "tick" da simulação — spawna, anda, resolve combate e fugas.
## Chamado a cada frame (delta real) OU repetidamente com delta fixo nos
## testes, pra simular o tempo passando sem precisar de engine gráfica.
func avancar(delta: float) -> void:
	if not jogo_ativo:
		return

	_tempo_onda += delta

	while not _fila_onda.is_empty() and _fila_onda[0]["atraso"] <= _tempo_onda:
		_spawnar_inimigo(_fila_onda.pop_front())

	for inimigo in inimigos_ativos:
		if not inimigo["_removido"]:
			inimigo["progresso"] += inimigo["velocidade"] * delta

	_resolver_combate()
	_resolver_fugas()

	inimigos_ativos = inimigos_ativos.filter(func(i): return not i["_removido"])

	if jogo_ativo and _fila_onda.is_empty() and inimigos_ativos.is_empty():
		var onda_terminada := _indice_onda
		onda_concluida.emit(onda_terminada)
		_avancar_onda()


func _spawnar_inimigo(spec: Dictionary) -> void:
	var inimigo := {
		"id": _proximo_id,
		"categoria": spec.get("categoria", "VALOR"),
		"texto": spec.get("texto", ""),
		"defesa_correta": spec["defesa_correta"],
		"progresso": 0.0,
		"velocidade": spec.get("velocidade", 0.12),
		"pontos_recompensa": spec.get("pontos_recompensa", 50),
		"dano_escape": spec.get("dano_escape", 10.0),
		"_removido": false,
	}
	_proximo_id += 1
	inimigos_ativos.append(inimigo)
	inimigo_spawnado.emit(inimigo["id"], inimigo["texto"])


func _resolver_combate() -> void:
	for slot in slots:
		if not slot["ocupado"]:
			continue
		for inimigo in inimigos_ativos:
			if inimigo["_removido"]:
				continue
			if inimigo["defesa_correta"] != slot["tipo_defesa"]:
				continue
			if absf(inimigo["progresso"] - slot["posicao"]) <= slot["alcance"]:
				_matar_inimigo(inimigo)


func _matar_inimigo(inimigo: Dictionary) -> void:
	inimigo["_removido"] = true
	pontos += inimigo["pontos_recompensa"]
	inimigo_destruido.emit(inimigo["id"], inimigo["pontos_recompensa"])
	pontuacao_atualizada.emit(pontos)


func _resolver_fugas() -> void:
	for inimigo in inimigos_ativos:
		if inimigo["_removido"]:
			continue
		if inimigo["progresso"] >= 1.0:
			_escapar_inimigo(inimigo)


func _escapar_inimigo(inimigo: Dictionary) -> void:
	inimigo["_removido"] = true
	barra_compilador = maxf(barra_compilador - inimigo["dano_escape"], 0.0)
	inimigo_escapou.emit(inimigo["id"], inimigo["dano_escape"])
	compilador_atualizado.emit(barra_compilador)
	if barra_compilador <= 0.0:
		jogo_ativo = false
		compilacao_falhou.emit()


## Avança pra próxima onda (ou vitória, se essa era a última). Chamada uma
## vez em `inicializar()` (pra armar a onda 0) e de novo toda vez que uma
## onda termina (fila de spawn vazia + nenhum inimigo dela ainda na tela).
func _avancar_onda() -> void:
	_indice_onda += 1
	if _indice_onda >= _config.ondas.size():
		jogo_ativo = false
		venceu = true
		vitoria.emit()
		return

	_tempo_onda = 0.0
	_fila_onda = _config.ondas[_indice_onda]["inimigos"].duplicate(true)
	_fila_onda.sort_custom(func(a, b): return a["atraso"] < b["atraso"])
	onda_iniciada.emit(_indice_onda)
