## test_type_checker.gd
##
## Bateria de testes standalone para type_checker.gd — sem depender de
## nenhuma cena, nenhum framework externo (GUT etc.) e nenhuma UI.
##
## Como rodar (linha de comando, na pasta do projeto):
##   godot --headless --script res://scripts/tests/test_type_checker.gd
##
## Imprime cada caso com ✓/✗ e termina com um resumo. Sai com código de
## erro != 0 se algum teste falhar, pra poder ser usado em CI depois.
extends SceneTree

const DataTypes = preload("res://scripts/fase7_verificacaoTipos/data_types.gd")
const TypeChecker = preload("res://scripts/fase7_verificacaoTipos/type_checker.gd")

var _total := 0
var _falhas := 0


func _init() -> void:
	print("=== Testes: type_checker.gd (GDD seção 6) ===\n")

	_testar_atribuicoes()
	_testar_operadores()
	_testar_identificacao()

	print("")
	if _falhas == 0:
		print("✓ TODOS OS %d TESTES PASSARAM" % _total)
	else:
		print("✗ %d de %d testes FALHARAM" % [_falhas, _total])

	quit(1 if _falhas > 0 else 0)


func _check(descricao: String, condicao: bool) -> void:
	_total += 1
	if condicao:
		print("  ✓ %s" % descricao)
	else:
		_falhas += 1
		print("  ✗ FALHOU: %s" % descricao)


func _testar_atribuicoes() -> void:
	print("-- Atribuições (GDD 6.2) --")

	_check(
		"int idade = 25 -> compatível",
		TypeChecker.verificar_atribuicao(DataTypes.Tipo.INT, DataTypes.Tipo.INT)["compativel"] == true
	)
	_check(
		"float nota = 25 -> compatível (promoção int -> float)",
		TypeChecker.verificar_atribuicao(DataTypes.Tipo.FLOAT, DataTypes.Tipo.INT)["compativel"] == true
	)

	var erro_precisao: Dictionary = TypeChecker.verificar_atribuicao(
		DataTypes.Tipo.INT, DataTypes.Tipo.FLOAT, "idade", "3.14"
	)
	_check("int idade = 3.14 -> INCOMPATÍVEL (perda de precisão)", erro_precisao["compativel"] == false)
	_check("  código de erro é PERDA_PRECISAO", erro_precisao["codigo_erro"] == TypeChecker.ERRO_PERDA_PRECISAO)

	_check(
		"float nota = 3.14 -> compatível",
		TypeChecker.verificar_atribuicao(DataTypes.Tipo.FLOAT, DataTypes.Tipo.FLOAT)["compativel"] == true
	)
	_check(
		"String nome = \"Ana\" -> compatível",
		TypeChecker.verificar_atribuicao(DataTypes.Tipo.STRING, DataTypes.Tipo.STRING)["compativel"] == true
	)
	_check(
		"int idade = \"Ana\" -> INCOMPATÍVEL",
		TypeChecker.verificar_atribuicao(DataTypes.Tipo.INT, DataTypes.Tipo.STRING)["compativel"] == false
	)
	_check(
		"boolean ativo = true -> compatível",
		TypeChecker.verificar_atribuicao(DataTypes.Tipo.BOOLEAN, DataTypes.Tipo.BOOLEAN)["compativel"] == true
	)
	_check(
		"boolean ativo = \"true\" -> INCOMPATÍVEL (String não é boolean)",
		TypeChecker.verificar_atribuicao(DataTypes.Tipo.BOOLEAN, DataTypes.Tipo.STRING)["compativel"] == false
	)
	_check(
		"char inicial = 'A' -> compatível",
		TypeChecker.verificar_atribuicao(DataTypes.Tipo.CHAR, DataTypes.Tipo.CHAR)["compativel"] == true
	)

	# A armadilha mais importante da fase (GDD 6.2.1): char vs String.
	var erro_char_string: Dictionary = TypeChecker.verificar_atribuicao(
		DataTypes.Tipo.CHAR, DataTypes.Tipo.STRING, "inicial", "\"A\""
	)
	_check("char inicial = \"A\" -> INCOMPATÍVEL (aspas duplas viram String)", erro_char_string["compativel"] == false)
	_check(
		"  código de erro é CHAR_STRING_CONFUSAO",
		erro_char_string["codigo_erro"] == TypeChecker.ERRO_CHAR_STRING_CONFUSAO
	)

	var erro_string_char: Dictionary = TypeChecker.verificar_atribuicao(
		DataTypes.Tipo.STRING, DataTypes.Tipo.CHAR, "nome", "'A'"
	)
	_check("String nome = 'A' -> INCOMPATÍVEL (aspas simples viram char)", erro_string_char["compativel"] == false)
	_check(
		"  código de erro é CHAR_STRING_CONFUSAO (sentido invertido)",
		erro_string_char["codigo_erro"] == TypeChecker.ERRO_CHAR_STRING_CONFUSAO
	)


func _testar_operadores() -> void:
	print("\n-- Operadores (GDD 6.3) --")

	var r1: Dictionary = TypeChecker.verificar_operador("+", DataTypes.Tipo.INT, DataTypes.Tipo.INT)
	_check(
		"idade + 1 (int + int) -> compatível, resultado int",
		r1["compativel"] == true and r1["tipo_resultante"] == DataTypes.Tipo.INT
	)

	var r2: Dictionary = TypeChecker.verificar_operador("+", DataTypes.Tipo.INT, DataTypes.Tipo.FLOAT)
	_check(
		"idade + 1.5 (int + float) -> compatível, resultado float",
		r2["compativel"] == true and r2["tipo_resultante"] == DataTypes.Tipo.FLOAT
	)

	var r3: Dictionary = TypeChecker.verificar_operador("+", DataTypes.Tipo.STRING, DataTypes.Tipo.STRING)
	_check(
		'nome + "!" (String + String) -> compatível, resultado String',
		r3["compativel"] == true and r3["tipo_resultante"] == DataTypes.Tipo.STRING
	)

	var r4: Dictionary = TypeChecker.verificar_operador("+", DataTypes.Tipo.INT, DataTypes.Tipo.STRING)
	_check('idade + "dez" -> INCOMPATÍVEL', r4["compativel"] == false)

	var r5: Dictionary = TypeChecker.verificar_operador("&&", DataTypes.Tipo.BOOLEAN, DataTypes.Tipo.BOOLEAN)
	_check(
		"ativo && true -> compatível, resultado boolean",
		r5["compativel"] == true and r5["tipo_resultante"] == DataTypes.Tipo.BOOLEAN
	)

	var r6: Dictionary = TypeChecker.verificar_operador("&&", DataTypes.Tipo.BOOLEAN, DataTypes.Tipo.INT)
	_check("ativo && 1 -> INCOMPATÍVEL (1 não é boolean)", r6["compativel"] == false)


func _testar_identificacao() -> void:
	print("\n-- Identificação de tipo a partir do texto (GDD Nível 1 / 6.2.1) --")

	_check("\"25\" -> int", TypeChecker.identificar_tipo("25")["tipo"] == DataTypes.Tipo.INT)
	_check("\"3.14\" -> float", TypeChecker.identificar_tipo("3.14")["tipo"] == DataTypes.Tipo.FLOAT)
	_check("\"true\" -> boolean", TypeChecker.identificar_tipo("true")["tipo"] == DataTypes.Tipo.BOOLEAN)
	_check("\"false\" -> boolean", TypeChecker.identificar_tipo("false")["tipo"] == DataTypes.Tipo.BOOLEAN)
	_check('\'"Ana"\' (aspas duplas) -> String', TypeChecker.identificar_tipo("\"Ana\"")["tipo"] == DataTypes.Tipo.STRING)
	_check("\"'A'\" (aspas simples) -> char", TypeChecker.identificar_tipo("'A'")["tipo"] == DataTypes.Tipo.CHAR)
	_check(
		'\'"A"\' (1 letra, mas aspas duplas) -> String, NUNCA char',
		TypeChecker.identificar_tipo("\"A\"")["tipo"] == DataTypes.Tipo.STRING
	)

	var invalido: Dictionary = TypeChecker.identificar_tipo("'AB'")
	_check("\"'AB'\" (2 caracteres entre aspas simples) -> inválido", invalido["valido"] == false)
