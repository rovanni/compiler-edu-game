## test_defense_level_data_factory.gd
##
## Testes de dados (sem cena, sem engine gráfica) pra DefenseLevelDataFactory
## — confere que os 3 níveis da mecânica Tower Defense (GDD seção 5-B/7,
## versão 2.0) estão bem formados e que a "defesa correta" de cada inimigo
## bate com o que o type_checker.gd de verdade diria.
##
## Como rodar (na pasta do projeto):
##   godot --headless --script res://scripts/tests/test_defense_level_data_factory.gd
extends SceneTree

const DataTypes = preload("res://scripts/fase7_verificacaoTipos/data_types.gd")
const TypeChecker = preload("res://scripts/fase7_verificacaoTipos/type_checker.gd")
const TowerDefenseSystem = preload("res://scripts/fase7_verificacaoTipos/tower_defense_system.gd")
const DefenseLevelDataFactory = preload("res://scripts/fase7_verificacaoTipos/defense_level_data_factory.gd")

var _total := 0
var _falhas := 0


func _check(descricao: String, condicao: bool) -> void:
	_total += 1
	if condicao:
		print("  ✓ %s" % descricao)
	else:
		_falhas += 1
		print("  ✗ FALHOU: %s" % descricao)


func _todos_inimigos(dados: DefenseLevelData) -> Array:
	var todos: Array = []
	for onda in dados.ondas:
		for inimigo in onda["inimigos"]:
			todos.append(inimigo)
	return todos


func _init() -> void:
	print("=== Testes: DefenseLevelDataFactory (Tower Defense, GDD 5-B) ===\n")

	_testar_nivel_2()
	_testar_nivel_3()
	_testar_nivel_4()
	_testar_slots_vs_tipos_disponiveis()

	print("")
	if _falhas == 0:
		print("✓ TODOS OS %d TESTES PASSARAM" % _total)
	else:
		print("✗ %d de %d TESTES FALHARAM" % [_falhas, _total])

	quit(1 if _falhas > 0 else 0)


func _testar_nivel_2() -> void:
	print("-- Nível 2: valores simples, defesa = tipo do valor --")
	var dados := DefenseLevelDataFactory.nivel_2()

	_check("número certo", dados.numero == 2)
	_check("5 tipos de defesa disponíveis (sem Erro ainda)", dados.tipos_disponiveis.size() == 5)
	_check("Erro de Tipo NÃO disponível no Nível 2", not dados.tipos_disponiveis.has(TowerDefenseSystem.DEFESA_ERRO))
	_check("tem 3 ondas", dados.ondas.size() == 3)
	_check("5 slots de construção", dados.slots.size() == 5)

	var viu_armadilha := false
	for inimigo in _todos_inimigos(dados):
		# Recalcula com o type_checker de verdade e confere que bate.
		var esperado: int = TypeChecker.identificar_tipo(inimigo["texto"])["tipo"]
		_check("defesa de '%s' é o tipo certo (%s)" % [inimigo["texto"], DataTypes.nome_tipo(esperado)], inimigo["defesa_correta"] == esperado)
		if inimigo["texto"] == "\"A\"":
			viu_armadilha = true
			_check("armadilha 'A'/\"A\": defesa correta é String, não char", inimigo["defesa_correta"] == DataTypes.Tipo.STRING)
	_check("a armadilha char/String apareceu pelo menos uma vez", viu_armadilha)


func _testar_nivel_3() -> void:
	print("\n-- Nível 3: atribuições, defesa = tipo declarado OU Erro --")
	var dados := DefenseLevelDataFactory.nivel_3()

	_check("número certo", dados.numero == 3)
	_check("6 tipos de defesa disponíveis (5 + Erro)", dados.tipos_disponiveis.size() == 6)
	_check("Erro de Tipo disponível a partir do Nível 3", dados.tipos_disponiveis.has(TowerDefenseSystem.DEFESA_ERRO))
	_check("5 slots pra 6 tipos possíveis (força escolha)", dados.slots.size() == 5)

	var viu_erro := false
	var viu_widening := false
	for inimigo in _todos_inimigos(dados):
		_check("inimigo é categoria ATRIBUICAO", inimigo["categoria"] == "ATRIBUICAO")
		if inimigo["defesa_correta"] == TowerDefenseSystem.DEFESA_ERRO:
			viu_erro = true
		if inimigo["texto"] == "float = 7":
			viu_widening = true
			_check("'float = 7' (widening int->float) é compatível, defesa = FLOAT", inimigo["defesa_correta"] == DataTypes.Tipo.FLOAT)
		if inimigo["texto"] == "int = 20.5":
			_check("'int = 20.5' (perda de precisão) é erro de tipo", inimigo["defesa_correta"] == TowerDefenseSystem.DEFESA_ERRO)
	_check("pelo menos uma atribuição incompatível no nível (usa a torre Erro)", viu_erro)
	_check("o caso de widening válido (int -> float) apareceu", viu_widening)


func _testar_nivel_4() -> void:
	print("\n-- Nível 4: expressões, defesa = tipo resultante OU Erro, sem char --")
	var dados := DefenseLevelDataFactory.nivel_4()

	_check("número certo", dados.numero == 4)
	_check("5 tipos de defesa disponíveis (4 + Erro)", dados.tipos_disponiveis.size() == 5)
	_check("char NÃO é uma defesa disponível no Nível 4 (GDD 6.3)", not dados.tipos_disponiveis.has(DataTypes.Tipo.CHAR))
	_check("4 slots pra 5 tipos possíveis (o mais apertado dos 3 níveis)", dados.slots.size() == 4)

	var viu_erro := false
	var viu_int_mais_float_vira_float := false
	var viu_concatenacao_string := false
	for inimigo in _todos_inimigos(dados):
		_check("inimigo é categoria EXPRESSAO", inimigo["categoria"] == "EXPRESSAO")
		_check("nenhum inimigo usa char (fora de escopo no Nível 4)", not inimigo["texto"].contains("'"))
		if inimigo["defesa_correta"] == TowerDefenseSystem.DEFESA_ERRO:
			viu_erro = true
		if inimigo["texto"] == "2.5 + 1":
			viu_int_mais_float_vira_float = true
			_check("'2.5 + 1' resulta em FLOAT (contamina)", inimigo["defesa_correta"] == DataTypes.Tipo.FLOAT)
		if inimigo["texto"] == "\"Ana\" + \"Bem\"":
			viu_concatenacao_string = true
			_check("concatenação de String resulta em STRING", inimigo["defesa_correta"] == DataTypes.Tipo.STRING)
	_check("pelo menos uma expressão inválida no nível (usa a torre Erro)", viu_erro)
	_check("o caso int+float->float apareceu", viu_int_mais_float_vira_float)
	_check("a concatenação de String apareceu", viu_concatenacao_string)


func _testar_slots_vs_tipos_disponiveis() -> void:
	print("\n-- Progressão: menos slots relativos a tipos, níveis mais avançados --")
	var d2 := DefenseLevelDataFactory.nivel_2()
	var d3 := DefenseLevelDataFactory.nivel_3()
	var d4 := DefenseLevelDataFactory.nivel_4()

	_check("Nível 2: slots == tipos disponíveis (sem aperto ainda)", d2.slots.size() == d2.tipos_disponiveis.size())
	_check("Nível 3: 1 slot a menos que tipos disponíveis", d3.slots.size() == d3.tipos_disponiveis.size() - 1)
	_check("Nível 4: 1 slot a menos que tipos disponíveis", d4.slots.size() == d4.tipos_disponiveis.size() - 1)

	for dados in [d2, d3, d4]:
		var sistema := TowerDefenseSystem.new()
		sistema.inicializar(dados)
		_check("Nível %d: TowerDefenseSystem aceita a config sem erro (slots armados)" % dados.numero, sistema.slots.size() == dados.slots.size())
