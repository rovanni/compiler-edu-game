## test_level1_logic.gd
##
## Testes standalone para level1_logic.gd — sem cena, sem GUT.
##
## Como rodar (na pasta do projeto):
##   godot --headless --script res://scripts/tests/test_level1_logic.gd
extends SceneTree

const DataTypes = preload("res://scripts/fase7_verificacaoTipos/data_types.gd")
const Level1Logic = preload("res://scripts/fase7_verificacaoTipos/level1_logic.gd")

var _total := 0
var _falhas := 0


func _init() -> void:
	print("=== Testes: level1_logic.gd (GDD Nível 1, seção 7) ===\n")

	_testar_acertos()
	_testar_erros()
	_testar_barra_e_falha()
	_testar_colunas()

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


func _testar_acertos() -> void:
	print("-- Acertos (peça na coluna certa) --")

	var logica := Level1Logic.new()

	var r1 := logica.julgar(DataTypes.Tipo.INT, "18")
	_check("18 -> coluna INT: acertou", r1["acertou"] == true)
	_check("pontuação foi pra 100", logica.pontuacao == 100)

	var r2 := logica.julgar(DataTypes.Tipo.STRING, "\"Maria\"")
	_check("\"Maria\" -> coluna String: acertou", r2["acertou"] == true)

	var r3 := logica.julgar(DataTypes.Tipo.BOOLEAN, "true")
	_check("true -> coluna BOOLEAN: acertou", r3["acertou"] == true)

	var r4 := logica.julgar(DataTypes.Tipo.FLOAT, "7.5")
	_check("7.5 -> coluna FLOAT: acertou", r4["acertou"] == true)

	var r5 := logica.julgar(DataTypes.Tipo.CHAR, "'A'")
	_check("'A' -> coluna CHAR: acertou", r5["acertou"] == true)

	_check("5 acertos seguidos = 500 pontos", logica.pontuacao == 500)
	_check("barra ficou travada em 100%% (não passa do teto)", logica.percentual_barra == 100.0)


func _testar_erros() -> void:
	print("\n-- Erros (peça na coluna errada, ou coluna certa mas peça inválida) --")

	var logica := Level1Logic.new()

	var r1 := logica.julgar(DataTypes.Tipo.INT, "\"Maria\"")
	_check("\"Maria\" solto em INT -> errou", r1["acertou"] == false)
	_check("tipo_correto identificado corretamente como STRING", r1["tipo_correto"] == DataTypes.Tipo.STRING)
	_check("pontuação não mudou", logica.pontuacao == 0)
	_check("barra caiu pra 80%%", logica.percentual_barra == 80.0)

	# Armadilha char/String também vale no Nível 1: "A" com aspas duplas é
	# String, não char, mesmo sendo 1 letra só.
	var r2 := logica.julgar(DataTypes.Tipo.CHAR, "\"A\"")
	_check("\"A\" (aspas duplas) solto em CHAR -> errou (é String)", r2["acertou"] == false)
	_check("tipo_correto é STRING, não CHAR", r2["tipo_correto"] == DataTypes.Tipo.STRING)

	var r3 := logica.julgar(DataTypes.Tipo.CHAR, "'AB'")
	_check("'AB' (2 letras) -> inválido, então errou também", r3["acertou"] == false)
	_check("tipo_correto fica -1 (não identificado)", r3["tipo_correto"] == -1)


func _testar_barra_e_falha() -> void:
	print("\n-- Barra do compilador e COMPILATION FAILED (GDD 8.2/8.3) --")

	var logica := Level1Logic.new()
	var falhou := [false]
	logica.compilacao_falhou.connect(func(): falhou[0] = true)

	var percentuais: Array = []
	logica.compilador_atualizado.connect(func(p): percentuais.append(p))

	# 5 erros seguidos de 20% cada = 100% -> 0%.
	for i in 5:
		logica.julgar(DataTypes.Tipo.INT, "\"errado %d\"" % i)

	_check("depois de 5 erros a barra chegou a 0%%", logica.percentual_barra == 0.0)
	_check("5 atualizações de barra foram emitidas", percentuais.size() == 5)
	_check("compilacao_falhou disparou", falhou[0] == true)

	# Não deve ficar negativa se continuar errando.
	logica.julgar(DataTypes.Tipo.INT, "\"mais um erro\"")
	_check("barra não fica negativa, trava em 0%%", logica.percentual_barra == 0.0)


func _testar_colunas() -> void:
	print("\n-- Colunas disponíveis (ordem da tabela do GDD seção 7) --")

	var logica := Level1Logic.new()
	var colunas := logica.colunas_disponiveis()
	_check("são 5 colunas", colunas.size() == 5)
	_check(
		"ordem é INT, FLOAT, String, BOOLEAN, CHAR",
		colunas == [DataTypes.Tipo.INT, DataTypes.Tipo.FLOAT, DataTypes.Tipo.STRING, DataTypes.Tipo.BOOLEAN, DataTypes.Tipo.CHAR]
	)
