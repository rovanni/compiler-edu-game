## type_checker.gd
##
## O "cérebro" da fase de Verificação de Tipos (TypeTris) — GDD seção 6.
##
## É uma classe utilitária pura: todas as funções são `static`, não leem
## nem escrevem estado de nenhum nó de cena, e não sabem nada sobre o
## tabuleiro, sobre peças caindo ou sobre UI. Isso é de propósito — dá
## pra chamar e testar essa lógica isolada (ver scripts/tests/test_type_checker.gd),
## e garante que a mesma regra vale em todos os níveis (1 a 4), sem
## duplicar código.
##
## Resumo das três coisas que este script sabe fazer:
##   1. identificar_tipo(texto)                    -> que tipo é esse literal?
##   2. verificar_atribuicao(tipo_var, tipo_valor)  -> "TIPO var = VALOR;" compila?
##   3. verificar_operador(op, tipo_esq, tipo_dir)  -> "A op B" compila, e dá que tipo?
class_name TypeChecker
extends RefCounted

const DataTypes = preload("res://scripts/fase7_verificacaoTipos/data_types.gd")

## Códigos de erro (usados pela UI pra decidir ícone/animação, e pelos
## testes pra conferir que o motivo do erro é o esperado — não só que
## deu erro, mas qual erro).
const ERRO_TIPO_INCOMPATIVEL := "TIPO_INCOMPATIVEL"
const ERRO_PERDA_PRECISAO := "PERDA_PRECISAO"
const ERRO_CHAR_STRING_CONFUSAO := "CHAR_STRING_CONFUSAO"
const ERRO_OPERADOR_INCOMPATIVEL := "OPERADOR_INCOMPATIVEL"

## GDD 6.2 — matriz de compatibilidade de atribuição.
## Chave = tipo da variável; valor = lista de tipos de valor aceitos.
## O único caso fora da diagonal é INT -> FLOAT (promoção/widening).
const _ATRIBUICOES_COMPATIVEIS := {
	DataTypes.Tipo.INT: [DataTypes.Tipo.INT],
	DataTypes.Tipo.FLOAT: [DataTypes.Tipo.INT, DataTypes.Tipo.FLOAT],
	DataTypes.Tipo.STRING: [DataTypes.Tipo.STRING],
	DataTypes.Tipo.BOOLEAN: [DataTypes.Tipo.BOOLEAN],
	DataTypes.Tipo.CHAR: [DataTypes.Tipo.CHAR],
}

## GDD 6.3 — operadores suportados nesta fase.
const _OPERADORES_ARITMETICOS := ["+", "-", "*", "/"]
const _OPERADORES_LOGICOS := ["&&", "||"]
const _TIPOS_NUMERICOS := [DataTypes.Tipo.INT, DataTypes.Tipo.FLOAT]


# ---------------------------------------------------------------------------
# 1. Identificação de tipo a partir do texto de um literal (GDD seção 6.2.1
#    e Nível 1). Cada peça de VALOR que cai no tabuleiro tem um texto
#    (ex.: "25", "3.14", "true", "\"Ana\"", "'A'") e essa função decide
#    a que tipo esse texto pertence — inclusive a armadilha char vs String,
#    que depende só de que aspas foram usadas.
# ---------------------------------------------------------------------------

## Retorna { "valido": bool, "tipo": DataTypes.Tipo, "erro": String (se inválido) }.
static func identificar_tipo(texto: String) -> Dictionary:
	var t := texto.strip_edges()

	if t == "true" or t == "false":
		return {"valido": true, "tipo": DataTypes.Tipo.BOOLEAN}

	# char: aspas simples, com EXATAMENTE um caractere dentro.
	if t.length() >= 2 and t.begins_with("'") and t.ends_with("'"):
		var conteudo_char := t.substr(1, t.length() - 2)
		if conteudo_char.length() == 1:
			return {"valido": true, "tipo": DataTypes.Tipo.CHAR}
		return {
			"valido": false,
			"tipo": DataTypes.Tipo.CHAR,
			"erro": "char só pode guardar 1 caractere — isso aqui tem %d" % conteudo_char.length(),
		}

	# String: aspas duplas, qualquer quantidade de caracteres dentro
	# (inclusive 1 só — "A" continua sendo String, nunca char).
	if t.length() >= 2 and t.begins_with("\"") and t.ends_with("\""):
		return {"valido": true, "tipo": DataTypes.Tipo.STRING}

	if t.is_valid_int():
		return {"valido": true, "tipo": DataTypes.Tipo.INT}

	if t.is_valid_float():
		return {"valido": true, "tipo": DataTypes.Tipo.FLOAT}

	return {"valido": false, "tipo": -1, "erro": "não reconheci esse valor: %s" % t}


# ---------------------------------------------------------------------------
# 2. Verificação de atribuição — "TIPO variavel = VALOR;" (GDD seção 6.2).
# ---------------------------------------------------------------------------

## Retorna:
##   {
##     "compativel": bool,
##     "mensagem": String,       (vazio quando compatível)
##     "codigo_erro": String,    (vazio quando compatível)
##     "tipo_variavel": DataTypes.Tipo,
##     "tipo_valor": DataTypes.Tipo,
##   }
##
## `nome_variavel` e `valor_literal` são opcionais e só deixam a mensagem
## de erro mais amigável (ex. citando "idade" e "3.14" em vez de só os
## nomes dos tipos) — a decisão de compatível/incompatível nunca depende
## deles, só dos dois tipos.
static func verificar_atribuicao(
	tipo_variavel: int,
	tipo_valor: int,
	nome_variavel: String = "",
	valor_literal: String = ""
) -> Dictionary:
	var aceitos: Array = _ATRIBUICOES_COMPATIVEIS.get(tipo_variavel, [])
	var compativel: bool = aceitos.has(tipo_valor)

	var codigo_erro := ""
	var mensagem := ""

	if not compativel:
		var erro := _gerar_erro_atribuicao(tipo_variavel, tipo_valor, nome_variavel, valor_literal)
		codigo_erro = erro[0]
		mensagem = erro[1]

	return {
		"compativel": compativel,
		"mensagem": mensagem,
		"codigo_erro": codigo_erro,
		"tipo_variavel": tipo_variavel,
		"tipo_valor": tipo_valor,
	}

## Monta [codigo_erro, mensagem] pra um caso de atribuição incompatível.
## Mensagens seguem o tom definido no GDD seção 6.4: curtas, sem jargão
## de compilador de verdade, focadas em explicar o "porquê".
static func _gerar_erro_atribuicao(
	tipo_variavel: int,
	tipo_valor: int,
	nome_variavel: String,
	valor_literal: String
) -> Array:
	var valor_texto := valor_literal if valor_literal != "" else "esse valor"

	# Armadilha char vs String (GDD 6.2.1) — o par de erros mais importante
	# desta fase, então tem mensagem dedicada nos dois sentidos.
	if tipo_variavel == DataTypes.Tipo.CHAR and tipo_valor == DataTypes.Tipo.STRING:
		return [
			ERRO_CHAR_STRING_CONFUSAO,
			"%s está entre aspas duplas — isso é String, não char! Char usa aspas simples, tipo 'A'." % valor_texto,
		]
	if tipo_variavel == DataTypes.Tipo.STRING and tipo_valor == DataTypes.Tipo.CHAR:
		return [
			ERRO_CHAR_STRING_CONFUSAO,
			"%s está entre aspas simples — isso é char, não String! String usa aspas duplas." % valor_texto,
		]

	# Perda de precisão: float caindo numa variável int (GDD 6.2).
	if tipo_variavel == DataTypes.Tipo.INT and tipo_valor == DataTypes.Tipo.FLOAT:
		return [
			ERRO_PERDA_PRECISAO,
			"%s tem casas decimais — int não guarda isso." % valor_texto,
		]

	# Caso genérico: qualquer outra combinação incompatível.
	var nome_alvo := nome_variavel if nome_variavel != "" else DataTypes.nome_tipo(tipo_variavel)
	return [
		ERRO_TIPO_INCOMPATIVEL,
		"%s não é compatível com %s (%s)." % [valor_texto, nome_alvo, DataTypes.nome_tipo(tipo_variavel)],
	]


# ---------------------------------------------------------------------------
# 3. Verificação de operador — "A op B" (GDD seção 6.3, a partir do Nível 4).
# ---------------------------------------------------------------------------

## Retorna:
##   {
##     "compativel": bool,
##     "tipo_resultante": DataTypes.Tipo (-1 se incompatível),
##     "mensagem": String (vazio quando compatível),
##   }
static func verificar_operador(operador: String, tipo_esquerda: int, tipo_direita: int) -> Dictionary:
	var compativel := false
	var tipo_resultante := -1

	if operador == "+" and tipo_esquerda == DataTypes.Tipo.STRING and tipo_direita == DataTypes.Tipo.STRING:
		# Concatenação de String (caso especial do "+", GDD 6.3).
		compativel = true
		tipo_resultante = DataTypes.Tipo.STRING
	elif (
		_OPERADORES_ARITMETICOS.has(operador)
		and _TIPOS_NUMERICOS.has(tipo_esquerda)
		and _TIPOS_NUMERICOS.has(tipo_direita)
	):
		compativel = true
		# int + int = int; qualquer float envolvido "contamina" pra float.
		if tipo_esquerda == DataTypes.Tipo.FLOAT or tipo_direita == DataTypes.Tipo.FLOAT:
			tipo_resultante = DataTypes.Tipo.FLOAT
		else:
			tipo_resultante = DataTypes.Tipo.INT
	elif (
		_OPERADORES_LOGICOS.has(operador)
		and tipo_esquerda == DataTypes.Tipo.BOOLEAN
		and tipo_direita == DataTypes.Tipo.BOOLEAN
	):
		compativel = true
		tipo_resultante = DataTypes.Tipo.BOOLEAN

	var mensagem := ""
	if not compativel:
		mensagem = _gerar_erro_operador(operador, tipo_esquerda, tipo_direita)

	return {
		"compativel": compativel,
		"tipo_resultante": tipo_resultante,
		"mensagem": mensagem,
	}

static func _gerar_erro_operador(operador: String, tipo_esquerda: int, tipo_direita: int) -> String:
	if _OPERADORES_LOGICOS.has(operador):
		return "Não dá pra usar %s aqui — os dois lados precisam ser boolean." % operador
	if operador == "+":
		return "Não dá pra somar/juntar %s com %s aqui." % [
			DataTypes.nome_tipo(tipo_esquerda), DataTypes.nome_tipo(tipo_direita)
		]
	return "Não dá pra usar %s entre %s e %s." % [
		operador, DataTypes.nome_tipo(tipo_esquerda), DataTypes.nome_tipo(tipo_direita)
	]
