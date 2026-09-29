## test_tower_defense_system.gd
##
## Testes da simulação do TowerDefenseSystem (GDD seção 5-B, versão 2.0) —
## sem cena, sem engine gráfica: monta configs pequenas e determinísticas
## na mão (não usa o DefenseLevelDataFactory, pra não depender de dados que
## podem mudar) e avança o "tempo" chamando avancar(delta) direto.
##
## Como rodar (na pasta do projeto):
##   godot --headless --script res://scripts/tests/test_tower_defense_system.gd
extends SceneTree

const DataTypes = preload("res://scripts/fase7_verificacaoTipos/data_types.gd")
const TowerDefenseSystem = preload("res://scripts/fase7_verificacaoTipos/tower_defense_system.gd")

var _total := 0
var _falhas := 0


func _check(descricao: String, condicao: bool) -> void:
	_total += 1
	if condicao:
		print("  ✓ %s" % descricao)
	else:
		_falhas += 1
		print("  ✗ FALHOU: %s" % descricao)


## Config mínima: 1 slot bem no meio do caminho (posição 0.5), 1 onda com
## 1 inimigo INT que anda a 1.0 de velocidade (chega ao slot em ~0.5s e ao
## fim do caminho em ~1s se não for destruído).
func _config_basica(defesa_correta: int = DataTypes.Tipo.INT, dano_escape: float = 20.0) -> DefenseLevelData:
	var dados := DefenseLevelData.new()
	dados.numero = 99
	dados.nome = "TESTE"
	dados.pontos_iniciais = 200
	dados.tipos_disponiveis = [DataTypes.Tipo.INT, DataTypes.Tipo.FLOAT, TowerDefenseSystem.DEFESA_ERRO]
	dados.custo_defesa = {DataTypes.Tipo.INT: 100, DataTypes.Tipo.FLOAT: 100, TowerDefenseSystem.DEFESA_ERRO: 150}
	dados.slots = [{"posicao": 0.5, "alcance": 0.1}]
	dados.ondas = [{"inimigos": [
		{"categoria": "VALOR", "texto": "7", "defesa_correta": defesa_correta, "velocidade": 1.0, "atraso": 0.0, "pontos_recompensa": 50, "dano_escape": dano_escape},
	]}]
	return dados


func _init() -> void:
	print("=== Testes: TowerDefenseSystem (mecânica Tower Defense, GDD 5-B) ===\n")

	_testar_inicializacao()
	_testar_construir_defesa_sucesso_e_falhas()
	_testar_trocar_defesa_sucesso_e_falhas()
	_testar_inimigo_e_morto_pela_defesa_certa()
	_testar_inimigo_ignora_defesa_errada()
	_testar_inimigo_escapa_sem_defesa()
	_testar_derrota_barra_zerada()
	_testar_vitoria_apos_ultima_onda()
	_testar_ondas_sequenciais()

	print("")
	if _falhas == 0:
		print("✓ TODOS OS %d TESTES PASSARAM" % _total)
	else:
		print("✗ %d de %d TESTES FALHARAM" % [_falhas, _total])

	quit(1 if _falhas > 0 else 0)


func _testar_inicializacao() -> void:
	print("-- inicializar() arma slots, pontos e a primeira onda --")
	var sistema := TowerDefenseSystem.new()
	sistema.inicializar(_config_basica())

	_check("pontos = pontos_iniciais", sistema.pontos == 200)
	_check("barra do compilador começa em 100%%", sistema.barra_compilador == 100.0)
	_check("1 slot armado, desocupado", sistema.slots.size() == 1 and sistema.slots[0]["ocupado"] == false)
	_check("jogo ativo", sistema.jogo_ativo == true)
	_check("ninguém spawnou ainda (spawn só depois de avancar())", sistema.inimigos_ativos.is_empty())


func _testar_construir_defesa_sucesso_e_falhas() -> void:
	print("\n-- construir_defesa(): sucesso, custo, slot ocupado, tipo indisponível --")
	var sistema := TowerDefenseSystem.new()
	sistema.inicializar(_config_basica())

	var r1 := sistema.construir_defesa(0, DataTypes.Tipo.INT)
	_check("constrói com sucesso no slot vazio", r1["sucesso"] == true)
	_check("custo foi descontado dos pontos (200 - 100 = 100)", sistema.pontos == 100)
	_check("slot ficou ocupado com o tipo certo", sistema.slots[0]["ocupado"] == true and sistema.slots[0]["tipo_defesa"] == DataTypes.Tipo.INT)

	var r2 := sistema.construir_defesa(0, DataTypes.Tipo.FLOAT)
	_check("falha ao construir em slot já ocupado", r2["sucesso"] == false)

	var r3 := sistema.construir_defesa(5, DataTypes.Tipo.INT)
	_check("falha com índice de slot inválido", r3["sucesso"] == false)

	var sistema_pobre := TowerDefenseSystem.new()
	sistema_pobre.inicializar(_config_basica())
	sistema_pobre.pontos = 10
	var r4 := sistema_pobre.construir_defesa(0, DataTypes.Tipo.INT)
	_check("falha por pontos insuficientes", r4["sucesso"] == false)
	_check("pontos não mudam numa tentativa que falhou", sistema_pobre.pontos == 10)

	var dados_sem_char := _config_basica()
	var sistema_tipo_errado := TowerDefenseSystem.new()
	sistema_tipo_errado.inicializar(dados_sem_char)
	var r5 := sistema_tipo_errado.construir_defesa(0, DataTypes.Tipo.CHAR) # não está em tipos_disponiveis
	_check("falha ao tentar construir um tipo indisponível neste nível", r5["sucesso"] == false)


func _testar_trocar_defesa_sucesso_e_falhas() -> void:
	print("\n-- trocar_defesa(): sucesso (sem reembolso), slot vazio, mesmo tipo, tipo indisponível, pontos insuficientes --")

	var sistema := TowerDefenseSystem.new()
	sistema.inicializar(_config_basica())
	sistema.construir_defesa(0, DataTypes.Tipo.INT) # custa 100, sobra 100
	var trocada_sinal: Array = []
	sistema.defesa_trocada.connect(func(indice, antigo, novo): trocada_sinal.append([indice, antigo, novo]))

	var r1 := sistema.trocar_defesa(0, DataTypes.Tipo.FLOAT)
	_check("troca com sucesso pra um tipo diferente", r1["sucesso"] == true)
	_check("custo do tipo NOVO foi descontado (100 - 100 = 0), sem reembolso do antigo", sistema.pontos == 0)
	_check("slot continua ocupado, agora com o tipo novo", sistema.slots[0]["ocupado"] == true and sistema.slots[0]["tipo_defesa"] == DataTypes.Tipo.FLOAT)
	_check("sinal defesa_trocada disparou com slot/tipo antigo/tipo novo certos", trocada_sinal == [[0, DataTypes.Tipo.INT, DataTypes.Tipo.FLOAT]])

	var sistema_vazio := TowerDefenseSystem.new()
	sistema_vazio.inicializar(_config_basica())
	var r2 := sistema_vazio.trocar_defesa(0, DataTypes.Tipo.INT)
	_check("falha ao trocar num slot vazio (precisa construir primeiro)", r2["sucesso"] == false)

	var sistema_mesmo_tipo := TowerDefenseSystem.new()
	sistema_mesmo_tipo.inicializar(_config_basica())
	sistema_mesmo_tipo.construir_defesa(0, DataTypes.Tipo.INT)
	var pontos_antes_mesmo_tipo := sistema_mesmo_tipo.pontos
	var r3 := sistema_mesmo_tipo.trocar_defesa(0, DataTypes.Tipo.INT)
	_check("falha ao trocar pro mesmo tipo que já está construído", r3["sucesso"] == false)
	_check("pontos não mudam numa troca recusada", sistema_mesmo_tipo.pontos == pontos_antes_mesmo_tipo)

	var sistema_tipo_indisponivel := TowerDefenseSystem.new()
	sistema_tipo_indisponivel.inicializar(_config_basica())
	sistema_tipo_indisponivel.construir_defesa(0, DataTypes.Tipo.INT)
	var r4 := sistema_tipo_indisponivel.trocar_defesa(0, DataTypes.Tipo.CHAR) # não está em tipos_disponiveis
	_check("falha ao trocar pra um tipo indisponível neste nível", r4["sucesso"] == false)

	var sistema_pobre := TowerDefenseSystem.new()
	sistema_pobre.inicializar(_config_basica())
	sistema_pobre.construir_defesa(0, DataTypes.Tipo.INT) # gasta 100 de 200, sobra 100
	sistema_pobre.pontos = 10 # simula ter gasto o resto em outra coisa
	var r5 := sistema_pobre.trocar_defesa(0, DataTypes.Tipo.FLOAT)
	_check("falha por pontos insuficientes pra trocar (custo do novo tipo)", r5["sucesso"] == false)
	_check("torre antiga continua lá depois de uma troca recusada por falta de pontos", sistema_pobre.slots[0]["tipo_defesa"] == DataTypes.Tipo.INT)

	var sistema_indice_invalido := TowerDefenseSystem.new()
	sistema_indice_invalido.inicializar(_config_basica())
	var r6 := sistema_indice_invalido.trocar_defesa(5, DataTypes.Tipo.INT)
	_check("falha com índice de slot inválido", r6["sucesso"] == false)

	var sistema_jogo_encerrado := TowerDefenseSystem.new()
	sistema_jogo_encerrado.inicializar(_config_basica())
	sistema_jogo_encerrado.construir_defesa(0, DataTypes.Tipo.INT)
	sistema_jogo_encerrado.jogo_ativo = false
	var r7 := sistema_jogo_encerrado.trocar_defesa(0, DataTypes.Tipo.FLOAT)
	_check("falha ao trocar com o jogo já encerrado", r7["sucesso"] == false)


func _testar_inimigo_e_morto_pela_defesa_certa() -> void:
	print("\n-- inimigo é destruído quando passa no alcance de uma defesa do tipo certo --")
	var sistema := TowerDefenseSystem.new()
	sistema.inicializar(_config_basica(DataTypes.Tipo.INT))
	sistema.construir_defesa(0, DataTypes.Tipo.INT)

	var pontos_antes := sistema.pontos
	# Inimigo começa em progresso 0.0, velocidade 1.0 -> chega em 0.5 (dentro do alcance 0.4-0.6) em ~0.45s.
	for i in 10:
		sistema.avancar(0.05)

	_check("inimigo foi destruído (lista de ativos vazia)", sistema.inimigos_ativos.is_empty())
	_check("pontos subiram com a recompensa do inimigo (+50)", sistema.pontos == pontos_antes + 50)
	_check("barra do compilador não foi tocada (inimigo não chegou a escapar)", sistema.barra_compilador == 100.0)


func _testar_inimigo_ignora_defesa_errada() -> void:
	print("\n-- defesa do tipo errado não mata o inimigo (ele continua e escapa) --")
	var sistema := TowerDefenseSystem.new()
	sistema.inicializar(_config_basica(DataTypes.Tipo.INT)) # inimigo é INT
	sistema.construir_defesa(0, DataTypes.Tipo.FLOAT) # defesa é FLOAT: não combina

	for i in 25: # tempo de sobra pra passar dos 2 slots e chegar no fim (progresso >= 1.0)
		sistema.avancar(0.05)

	_check("inimigo NÃO foi destruído pela defesa errada, escapou", sistema.inimigos_ativos.is_empty())
	_check("barra do compilador caiu (o inimigo chegou ao fim do caminho)", sistema.barra_compilador < 100.0)


func _testar_inimigo_escapa_sem_defesa() -> void:
	print("\n-- sem nenhuma defesa construída, inimigo sempre escapa e reduz a barra --")
	var sistema := TowerDefenseSystem.new()
	sistema.inicializar(_config_basica(DataTypes.Tipo.INT, 20.0))

	for i in 25:
		sistema.avancar(0.05)

	_check("barra caiu exatamente o dano_escape do inimigo (100 - 20 = 80)", is_equal_approx(sistema.barra_compilador, 80.0))


func _testar_derrota_barra_zerada() -> void:
	print("\n-- barra do compilador chega a 0%%: compilacao_falhou, jogo trava (GDD 8.3) --")
	var dados := _config_basica(DataTypes.Tipo.INT, 60.0)
	# 2 inimigos que escapam (60 de dano cada) já derruba a barra a 0.
	dados.ondas = [{"inimigos": [
		{"categoria": "VALOR", "texto": "7", "defesa_correta": DataTypes.Tipo.INT, "velocidade": 1.0, "atraso": 0.0, "pontos_recompensa": 50, "dano_escape": 60.0},
		{"categoria": "VALOR", "texto": "8", "defesa_correta": DataTypes.Tipo.INT, "velocidade": 1.0, "atraso": 0.0, "pontos_recompensa": 50, "dano_escape": 60.0},
	]}]
	var sistema := TowerDefenseSystem.new()
	var falhou_sinal := [false]
	sistema.compilacao_falhou.connect(func(): falhou_sinal[0] = true)
	sistema.inicializar(dados)

	for i in 25:
		sistema.avancar(0.05)

	_check("barra do compilador não fica negativa (piso em 0)", sistema.barra_compilador == 0.0)
	_check("sinal compilacao_falhou disparou", falhou_sinal[0] == true)
	_check("jogo_ativo virou false", sistema.jogo_ativo == false)
	_check("venceu continua false", sistema.venceu == false)

	# Depois de falhar, avancar() não deve mais fazer nada (jogo travado).
	var pontos_apos_falha := sistema.pontos
	sistema.avancar(1.0)
	_check("avancar() depois da derrota é no-op (pontos não mudam)", sistema.pontos == pontos_apos_falha)


func _testar_vitoria_apos_ultima_onda() -> void:
	print("\n-- todas as ondas resolvidas (sem escapar), sem derrota: vitória (GDD 8.4) --")
	var dados := _config_basica(DataTypes.Tipo.INT, 5.0)
	dados.ondas = [
		{"inimigos": [{"categoria": "VALOR", "texto": "1", "defesa_correta": DataTypes.Tipo.INT, "velocidade": 1.0, "atraso": 0.0, "pontos_recompensa": 50, "dano_escape": 5.0}]},
		{"inimigos": [{"categoria": "VALOR", "texto": "2", "defesa_correta": DataTypes.Tipo.INT, "velocidade": 1.0, "atraso": 0.0, "pontos_recompensa": 50, "dano_escape": 5.0}]},
	]
	var sistema := TowerDefenseSystem.new()
	var venceu_sinal := [false]
	sistema.vitoria.connect(func(): venceu_sinal[0] = true)
	sistema.inicializar(dados)
	sistema.construir_defesa(0, DataTypes.Tipo.INT) # mata os dois inimigos, nenhum escapa

	for i in 40: # tempo de sobra pras 2 ondas serem processadas
		sistema.avancar(0.05)

	_check("sinal vitoria disparou", venceu_sinal[0] == true)
	_check("venceu == true", sistema.venceu == true)
	_check("jogo_ativo virou false (nível concluído)", sistema.jogo_ativo == false)
	_check("barra do compilador continua em 100%% (nenhum inimigo escapou)", sistema.barra_compilador == 100.0)


func _testar_ondas_sequenciais() -> void:
	print("\n-- a 2ª onda só começa depois que a 1ª termina (spawn + resolução) --")
	var dados := _config_basica(DataTypes.Tipo.INT, 5.0)
	dados.ondas = [
		{"inimigos": [{"categoria": "VALOR", "texto": "1", "defesa_correta": DataTypes.Tipo.INT, "velocidade": 1.0, "atraso": 0.0, "pontos_recompensa": 50, "dano_escape": 5.0}]},
		{"inimigos": [{"categoria": "VALOR", "texto": "2", "defesa_correta": DataTypes.Tipo.FLOAT, "velocidade": 1.0, "atraso": 0.0, "pontos_recompensa": 50, "dano_escape": 5.0}]},
	]
	var sistema := TowerDefenseSystem.new()
	var ondas_iniciadas: Array = []
	var ondas_concluidas: Array = []
	sistema.onda_iniciada.connect(func(i): ondas_iniciadas.append(i))
	sistema.onda_concluida.connect(func(i): ondas_concluidas.append(i))
	sistema.inicializar(dados)

	_check("onda 0 já foi anunciada na inicialização", ondas_iniciadas == [0])
	_check("nenhum inimigo da onda 1 (FLOAT) existe ainda logo no início", sistema.inimigos_ativos.size() <= 1)

	for i in 60:
		sistema.avancar(0.05)

	_check("as 2 ondas foram concluídas, em ordem", ondas_concluidas == [0, 1])
	_check("as 2 ondas foram iniciadas, em ordem", ondas_iniciadas == [0, 1])
