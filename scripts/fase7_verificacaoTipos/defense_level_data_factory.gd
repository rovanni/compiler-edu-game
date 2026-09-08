## defense_level_data_factory.gd
##
## Monta os DefenseLevelData dos Níveis 2, 3 e 4 da mecânica Tower Defense
## (GDD seção 5-B / 7, versão 2.0) como funções puras — igual ao antigo
## `level_data_factory.gd`, mas pro sistema novo.
##
## O ponto importante: quem decide se um inimigo é "válido" ou "expressão
## com erro" — e qual é a defesa que o mata — é sempre o `type_checker.gd`
## de verdade (`verificar_atribuicao` / `verificar_operador`), nunca uma
## conta feita à mão aqui. Isso garante que a mecânica nova ensina
## exatamente as mesmas regras de tipo do resto do jogo (GDD seção 6).
class_name DefenseLevelDataFactory
extends RefCounted

const DataTypes = preload("res://scripts/fase7_verificacaoTipos/data_types.gd")
const TypeChecker = preload("res://scripts/fase7_verificacaoTipos/type_checker.gd")
const TowerDefenseSystem = preload("res://scripts/fase7_verificacaoTipos/tower_defense_system.gd")


# ---------------------------------------------------------------------------
# Helpers pra montar spec de inimigo a partir de texto/regras reais —
# nunca hardcoding "defesa_correta" à mão.
# ---------------------------------------------------------------------------

## Nível 2: um valor simples anda até a torre (ex.: "42", "'A'", "\"A\"").
## Defesa correta = o tipo do próprio valor (com a armadilha char/String
## resolvida por identificar_tipo, igual ao Nível 1).
static func _inimigo_valor(texto: String, velocidade: float, atraso: float, pontos := 60, dano := 12.0) -> Dictionary:
	var identificado := TypeChecker.identificar_tipo(texto)
	return {
		"categoria": "VALOR",
		"texto": texto,
		"defesa_correta": identificado["tipo"],
		"velocidade": velocidade,
		"atraso": atraso,
		"pontos_recompensa": pontos,
		"dano_escape": dano,
	}

## Nível 3: uma atribuição completa anda até a torre (ex.: "float = 7",
## "int = 20.5"). Defesa correta = defesa do tipo declarado SE
## verificar_atribuicao() disser que é compatível; senão, é a defesa
## "Erro de Tipo" — nunca a defesa do tipo declarado nem a do tipo do
## valor, porque a linha simplesmente não compila.
static func _inimigo_atribuicao(tipo_declarado: int, texto_valor: String, velocidade: float, atraso: float, pontos := 80, dano := 15.0) -> Dictionary:
	var tipo_valor: int = TypeChecker.identificar_tipo(texto_valor)["tipo"]
	var resultado := TypeChecker.verificar_atribuicao(tipo_declarado, tipo_valor)
	var defesa = tipo_declarado if resultado["compativel"] else TowerDefenseSystem.DEFESA_ERRO
	return {
		"categoria": "ATRIBUICAO",
		"texto": "%s = %s" % [DataTypes.nome_tipo(tipo_declarado), texto_valor],
		"defesa_correta": defesa,
		"velocidade": velocidade,
		"atraso": atraso,
		"pontos_recompensa": pontos,
		"dano_escape": dano,
	}

## Nível 4: uma expressão "A op B" anda até a torre (ex.: "5 + 3.5",
## "\"oi\" - 2"). Defesa correta = defesa do TIPO RESULTANTE da operação
## (ensina que int + float = float) se verificar_operador() disser que é
## válida; senão, defesa "Erro de Tipo" (expressão inválida, GDD 6.3).
static func _inimigo_expressao(texto_esq: String, operador: String, texto_dir: String, velocidade: float, atraso: float, pontos := 100, dano := 18.0) -> Dictionary:
	var tipo_esq: int = TypeChecker.identificar_tipo(texto_esq)["tipo"]
	var tipo_dir: int = TypeChecker.identificar_tipo(texto_dir)["tipo"]
	var resultado := TypeChecker.verificar_operador(operador, tipo_esq, tipo_dir)
	var defesa = resultado["tipo_resultante"] if resultado["compativel"] else TowerDefenseSystem.DEFESA_ERRO
	return {
		"categoria": "EXPRESSAO",
		"texto": "%s %s %s" % [texto_esq, operador, texto_dir],
		"defesa_correta": defesa,
		"velocidade": velocidade,
		"atraso": atraso,
		"pontos_recompensa": pontos,
		"dano_escape": dano,
	}

static func _onda(inimigos: Array) -> Dictionary:
	return {"inimigos": inimigos}


# ---------------------------------------------------------------------------
# Nível 2 — Reconhecimento de Tipos: valores simples, 5 torres básicas.
# ---------------------------------------------------------------------------
static func nivel_2() -> DefenseLevelData:
	var dados := DefenseLevelData.new()
	dados.numero = 2
	dados.nome = "NÍVEL 2"
	dados.pontos_iniciais = 300

	dados.tipos_disponiveis = [
		DataTypes.Tipo.INT, DataTypes.Tipo.FLOAT, DataTypes.Tipo.STRING,
		DataTypes.Tipo.BOOLEAN, DataTypes.Tipo.CHAR,
	]
	dados.custo_defesa = {
		DataTypes.Tipo.INT: 80, DataTypes.Tipo.FLOAT: 80, DataTypes.Tipo.STRING: 80,
		DataTypes.Tipo.BOOLEAN: 80, DataTypes.Tipo.CHAR: 80,
	}
	dados.slots = [
		{"posicao": 0.15, "alcance": 0.11}, {"posicao": 0.32, "alcance": 0.11},
		{"posicao": 0.5, "alcance": 0.11}, {"posicao": 0.68, "alcance": 0.11},
		{"posicao": 0.85, "alcance": 0.11},
	]

	dados.ondas = [
		_onda([
			_inimigo_valor("18", 0.05, 0.0), _inimigo_valor("\"Ana\"", 0.05, 2.5),
			_inimigo_valor("true", 0.05, 5.0), _inimigo_valor("3.14", 0.05, 7.5),
			_inimigo_valor("'X'", 0.05, 10.0),
		]),
		_onda([
			_inimigo_valor("7", 0.06, 0.0), _inimigo_valor("\"A\"", 0.06, 2.0), # armadilha char/String
			_inimigo_valor("'A'", 0.06, 4.0), _inimigo_valor("false", 0.06, 6.0),
			_inimigo_valor("7.5", 0.06, 8.0), _inimigo_valor("42", 0.06, 10.0),
			_inimigo_valor("\"gato\"", 0.06, 12.0), _inimigo_valor("'z'", 0.06, 14.0),
		]),
		_onda([
			_inimigo_valor("100", 0.07, 0.0), _inimigo_valor("2.5", 0.07, 1.6),
			_inimigo_valor("\"João\"", 0.07, 3.2), _inimigo_valor("'A'", 0.07, 4.8),
			_inimigo_valor("true", 0.07, 6.4), _inimigo_valor("\"A\"", 0.07, 8.0), # armadilha de novo
			_inimigo_valor("23", 0.07, 9.6), _inimigo_valor("false", 0.07, 11.2),
			_inimigo_valor("\"Pedro\"", 0.07, 12.8), _inimigo_valor("'X'", 0.07, 14.4),
		]),
	]

	return dados


# ---------------------------------------------------------------------------
# Nível 3 — Compatibilidade e Conversão: atribuições, +1 torre "Erro de
# Tipo", 1 slot a menos que tipos disponíveis (força escolha).
# ---------------------------------------------------------------------------
static func nivel_3() -> DefenseLevelData:
	var dados := DefenseLevelData.new()
	dados.numero = 3
	dados.nome = "NÍVEL 3"
	dados.pontos_iniciais = 350

	dados.tipos_disponiveis = [
		DataTypes.Tipo.INT, DataTypes.Tipo.FLOAT, DataTypes.Tipo.STRING,
		DataTypes.Tipo.BOOLEAN, DataTypes.Tipo.CHAR, TowerDefenseSystem.DEFESA_ERRO,
	]
	dados.custo_defesa = {
		DataTypes.Tipo.INT: 90, DataTypes.Tipo.FLOAT: 90, DataTypes.Tipo.STRING: 90,
		DataTypes.Tipo.BOOLEAN: 90, DataTypes.Tipo.CHAR: 90, TowerDefenseSystem.DEFESA_ERRO: 130,
	}
	dados.slots = [
		{"posicao": 0.15, "alcance": 0.11}, {"posicao": 0.32, "alcance": 0.11},
		{"posicao": 0.5, "alcance": 0.11}, {"posicao": 0.68, "alcance": 0.11},
		{"posicao": 0.85, "alcance": 0.11},
	]

	dados.ondas = [
		_onda([
			_inimigo_atribuicao(DataTypes.Tipo.INT, "18", 0.05, 0.0),
			_inimigo_atribuicao(DataTypes.Tipo.FLOAT, "7", 0.05, 3.0), # widening válido
			_inimigo_atribuicao(DataTypes.Tipo.STRING, "\"Ana\"", 0.05, 6.0),
			_inimigo_atribuicao(DataTypes.Tipo.BOOLEAN, "true", 0.05, 9.0),
		]),
		_onda([
			_inimigo_atribuicao(DataTypes.Tipo.INT, "20.5", 0.055, 0.0), # ERRO: perda de precisão
			_inimigo_atribuicao(DataTypes.Tipo.CHAR, "\"A\"", 0.055, 2.5), # ERRO: armadilha char/String
			_inimigo_atribuicao(DataTypes.Tipo.FLOAT, "3.14", 0.055, 5.0),
			_inimigo_atribuicao(DataTypes.Tipo.STRING, "'A'", 0.055, 7.5), # ERRO: armadilha inversa
			_inimigo_atribuicao(DataTypes.Tipo.INT, "42", 0.055, 10.0),
		]),
		_onda([
			_inimigo_atribuicao(DataTypes.Tipo.FLOAT, "99.9", 0.06, 0.0),
			_inimigo_atribuicao(DataTypes.Tipo.BOOLEAN, "\"sim\"", 0.06, 2.2), # ERRO
			_inimigo_atribuicao(DataTypes.Tipo.INT, "7", 0.06, 4.4),
			_inimigo_atribuicao(DataTypes.Tipo.FLOAT, "5", 0.06, 6.6), # widening válido
			_inimigo_atribuicao(DataTypes.Tipo.INT, "0.5", 0.06, 8.8), # ERRO: perda de precisão
			_inimigo_atribuicao(DataTypes.Tipo.CHAR, "'z'", 0.06, 11.0),
		]),
		_onda([
			_inimigo_atribuicao(DataTypes.Tipo.STRING, "\"gato\"", 0.065, 0.0),
			_inimigo_atribuicao(DataTypes.Tipo.INT, "3.14", 0.065, 2.0), # ERRO
			_inimigo_atribuicao(DataTypes.Tipo.CHAR, "'X'", 0.065, 4.0),
			_inimigo_atribuicao(DataTypes.Tipo.BOOLEAN, "false", 0.065, 6.0),
			_inimigo_atribuicao(DataTypes.Tipo.FLOAT, "100", 0.065, 8.0), # widening válido
			_inimigo_atribuicao(DataTypes.Tipo.STRING, "'A'", 0.065, 10.0), # ERRO
			_inimigo_atribuicao(DataTypes.Tipo.INT, "23", 0.065, 12.0),
		]),
	]

	return dados


# ---------------------------------------------------------------------------
# Nível 4 — Expressões e Operadores: char fica de fora (GDD 6.3), 4 slots
# pra 5 tipos de defesa disponíveis (int/float/String/boolean/Erro).
# ---------------------------------------------------------------------------
static func nivel_4() -> DefenseLevelData:
	var dados := DefenseLevelData.new()
	dados.numero = 4
	dados.nome = "NÍVEL 4"
	dados.pontos_iniciais = 400

	dados.tipos_disponiveis = [
		DataTypes.Tipo.INT, DataTypes.Tipo.FLOAT, DataTypes.Tipo.STRING,
		DataTypes.Tipo.BOOLEAN, TowerDefenseSystem.DEFESA_ERRO,
	]
	dados.custo_defesa = {
		DataTypes.Tipo.INT: 100, DataTypes.Tipo.FLOAT: 100, DataTypes.Tipo.STRING: 100,
		DataTypes.Tipo.BOOLEAN: 100, TowerDefenseSystem.DEFESA_ERRO: 150,
	}
	dados.slots = [
		{"posicao": 0.2, "alcance": 0.14}, {"posicao": 0.42, "alcance": 0.14},
		{"posicao": 0.64, "alcance": 0.14}, {"posicao": 0.85, "alcance": 0.14},
	]

	dados.ondas = [
		_onda([
			_inimigo_expressao("5", "+", "3", 0.045, 0.0), # int
			_inimigo_expressao("2.5", "+", "1", 0.045, 3.0), # float (contamina)
			_inimigo_expressao("true", "&&", "false", 0.045, 6.0), # boolean
			_inimigo_expressao("\"Ana\"", "+", "\"Bem\"", 0.045, 9.0), # String (concatenação)
		]),
		_onda([
			_inimigo_expressao("10", "-", "4", 0.05, 0.0),
			_inimigo_expressao("\"!\"", "-", "2", 0.05, 2.5), # ERRO: String não aceita "-"
			_inimigo_expressao("8", "*", "2.5", 0.05, 5.0), # float
			_inimigo_expressao("true", "+", "1", 0.05, 7.5), # ERRO: boolean não é numérico
			_inimigo_expressao("3", "/", "2", 0.05, 10.0),
		]),
		_onda([
			_inimigo_expressao("4.0", "*", "2", 0.055, 0.0), # float
			_inimigo_expressao("false", "||", "true", 0.055, 2.2),
			_inimigo_expressao("5", "&&", "3", 0.055, 4.4), # ERRO: && exige boolean
			_inimigo_expressao("2", "+", "8", 0.055, 6.6),
			_inimigo_expressao("\"Ana\"", "*", "2", 0.055, 8.8), # ERRO: String só aceita "+"
			_inimigo_expressao("1.5", "/", "3", 0.055, 11.0), # float
		]),
		_onda([
			_inimigo_expressao("10", "+", "2.5", 0.06, 0.0), # float
			_inimigo_expressao("true", "-", "false", 0.06, 2.0), # ERRO
			_inimigo_expressao("3", "*", "3", 0.06, 4.0),
			_inimigo_expressao("\"Bem\"", "+", "\"!\"", 0.06, 6.0),
			_inimigo_expressao("8", "/", "2.0", 0.06, 8.0), # float
			_inimigo_expressao("2", "-", "\"!\"", 0.06, 10.0), # ERRO
		]),
		_onda([
			_inimigo_expressao("5", "+", "2", 0.065, 0.0),
			_inimigo_expressao("4.0", "-", "1.5", 0.065, 1.8),
			_inimigo_expressao("true", "&&", "true", 0.065, 3.6),
			_inimigo_expressao("\"Ana\"", "&&", "true", 0.065, 5.4), # ERRO
			_inimigo_expressao("2", "*", "4.0", 0.065, 7.2), # float
			_inimigo_expressao("10", "/", "3", 0.065, 9.0),
			_inimigo_expressao("false", "+", "2", 0.065, 10.8), # ERRO
		]),
	]

	return dados
