## test_tower_defense_level_scene.gd
##
## Teste de integração das cenas de verdade dos Níveis 2 e 3 (Torre de
## Defesa, GDD 5-B) — instancia scenes/levels/Level2.tscn e Level3.tscn tal
## como o jogo faz, e confere que o controller monta a paleta/slots certos,
## que _process() avança a simulação real (TowerDefenseSystem por trás), e
## que clicar (via chamada direta, igual ao padrão já usado nos outros
## testes de cena) numa defesa/slot funciona fim-a-fim, incluindo vitória.
##
## Como rodar (na pasta do projeto):
##   godot --headless --script res://scripts/tests/test_tower_defense_level_scene.gd
##
## Nota: como --headless --script sai antes de qualquer frame real passar,
## o _ready() da cena (que resolve as vars @onready e cria o
## TowerDefenseSystem) nunca dispara sozinho — _instanciar() chama na mão,
## igual test_level1_scene.gd.
extends SceneTree

const DataTypes = preload("res://scripts/fase7_verificacaoTipos/data_types.gd")
const TowerDefenseSystem = preload("res://scripts/fase7_verificacaoTipos/tower_defense_system.gd")
const DefenseVisualAssets = preload("res://scripts/fase7_verificacaoTipos/defense_visual_assets.gd")

var _total := 0
var _falhas := 0


func _check(descricao: String, condicao: bool) -> void:
	_total += 1
	if condicao:
		print("  ✓ %s" % descricao)
	else:
		_falhas += 1
		print("  ✗ FALHOU: %s" % descricao)


func _init() -> void:
	# Autoloads (GameManager) só ficam registrados como identificador global
	# depois do primeiro ciclo de inicialização da SceneTree — adiamos a
	# carga/execução real com call_deferred() pra evitar erro de compilação
	# "Identifier not found: GameManager" ao dar load() nas cenas da Fase 7
	# (mesmo padrão já usado pelo harness de teste do resto do projeto, ver
	# tests/headless_fase6_test.gd).
	call_deferred("_executar")


func _executar() -> void:
	print("=== Teste: cenas de verdade da Torre de Defesa (Níveis 2 e 3) ===\n")

	_testar_montagem_basica("res://scenes/fase7_verificacaoTipos/Level2.tscn", "Nível 2")
	_testar_montagem_basica("res://scenes/fase7_verificacaoTipos/Level3.tscn", "Nível 3")
	_testar_montagem_basica("res://scenes/fase7_verificacaoTipos/Level4.tscn", "Nível 4")
	_testar_inimigo_corrompido_para_defesa_erro()
	_testar_construir_e_matar_inimigo()
	_testar_recusa_slot_ocupado()
	_testar_derrota_por_fuga()
	_testar_vitoria_nivel_2_completo()
	_testar_vitoria_nivel_4()
	_testar_arrastar_e_soltar_constroi_defesa()
	_testar_arrastar_e_soltar_fora_do_alcance_cancela()
	_testar_trocar_torre_por_clique()
	_testar_trocar_torre_mesmo_tipo_recusa()
	_testar_trocar_torre_por_arraste()
	_testar_trocar_torre_pontos_insuficientes_mantem_antiga()
	_testar_explosao_ao_matar_inimigo()
	_testar_multiplas_explosoes_sao_instancias_independentes()
	_testar_animacao_ataque_torre()
	_testar_escala_torre_normalizada_entre_resolucoes()
	_testar_painel_explicacao_minimiza()

	print("")
	if _falhas == 0:
		print("✓ TODOS OS %d TESTES PASSARAM" % _total)
	else:
		print("✗ %d de %d TESTES FALHARAM" % [_falhas, _total])

	quit(1 if _falhas > 0 else 0)


func _instanciar(caminho_cena: String) -> Control:
	var cena: PackedScene = load(caminho_cena)
	var raiz := cena.instantiate()
	root.add_child(raiz)
	# Em --headless --script não passa nenhum frame antes do quit(), então o
	# _ready() (que resolve as vars @onready e cria o TowerDefenseSystem)
	# nunca dispara sozinho — chamamos na mão, igual test_level1_scene.gd.
	raiz._ready()
	return raiz


func _testar_montagem_basica(caminho_cena: String, rotulo: String) -> void:
	print("--- %s: montagem básica ---" % rotulo)
	var raiz := _instanciar(caminho_cena)

	_check("%s: controller tem level_data definido" % rotulo, raiz.level_data != null)
	_check("%s: sistema de simulação foi criado" % rotulo, raiz._sistema != null)
	_check("%s: paleta tem 1 botão por tipo disponível" % rotulo, raiz._botoes_paleta.size() == raiz.level_data.tipos_disponiveis.size())
	_check("%s: slots visuais batem com level_data.slots" % rotulo, raiz._nos_slots.size() == raiz.level_data.slots.size())
	_check("%s: onda 0 já está ativa (spawnada em inicializar())" % rotulo, raiz._sistema.jogo_ativo)
	_check("%s: HUD mostra o nome do nível" % rotulo, raiz._label_info.text.findn(raiz.level_data.nome) != -1)
	_check("%s: TextoDerrota começa invisível" % rotulo, not raiz._texto_derrota.visible)

	raiz.queue_free()


func _testar_inimigo_corrompido_para_defesa_erro() -> void:
	print("--- Nível 3: inimigo de 'Erro de Tipo' usa a arte corrompida de verdade, não recolore o base (v2.8) ---")
	var raiz := _instanciar("res://scenes/fase7_verificacaoTipos/Level3.tscn")

	# Chama _criar_no_inimigo() direto (em vez de esperar a onda de verdade
	# gerar um caso de erro) — testa exatamente a decisão visual que mudou,
	# sem depender de tempo de simulação de onda.
	var inimigo_erro := {
		"id": 9001, "categoria": "ATRIBUICAO", "texto": "int = 20.5",
		"defesa_correta": TowerDefenseSystem.DEFESA_ERRO, "progresso": 0.0,
		"velocidade": 0.05, "pontos_recompensa": 80, "dano_escape": 15.0, "_removido": false,
	}
	raiz._criar_no_inimigo(inimigo_erro)
	var sprite_erro: AnimatedSprite2D = raiz._nos_inimigos[9001]["sprite"]

	_check("inimigo de erro usa o SpriteFrames corrompido (não o base)", sprite_erro.sprite_frames == raiz.INIMIGO_CORROMPIDO_FRAMES)
	_check("inimigo de erro NÃO é recolorido (a arte já vem com a cor própria)", sprite_erro.modulate == Color(1, 1, 1))
	_check("a animação 'flutuar' está tocando", sprite_erro.is_playing() and sprite_erro.animation == "flutuar")

	# Em contraste, um inimigo de tipo normal continua usando o base
	# recolorido, exatamente como antes desta mudança.
	var inimigo_normal := {
		"id": 9002, "categoria": "VALOR", "texto": "42",
		"defesa_correta": DataTypes.Tipo.INT, "progresso": 0.0,
		"velocidade": 0.05, "pontos_recompensa": 60, "dano_escape": 12.0, "_removido": false,
	}
	raiz._criar_no_inimigo(inimigo_normal)
	var sprite_normal: AnimatedSprite2D = raiz._nos_inimigos[9002]["sprite"]

	_check("inimigo de tipo normal continua usando o SpriteFrames base", sprite_normal.sprite_frames == raiz.INIMIGO_FRAMES)
	_check("inimigo de tipo normal continua recolorido por tipo", sprite_normal.modulate == DefenseVisualAssets.cor_defesa(DataTypes.Tipo.INT))

	raiz.queue_free()


func _testar_construir_e_matar_inimigo() -> void:
	print("--- Nível 2: construir defesa e matar um inimigo de verdade ---")
	var raiz := _instanciar("res://scenes/fase7_verificacaoTipos/Level2.tscn")

	# Constrói a defesa "int" no slot 0 ANTES de qualquer inimigo nascer
	# (custo sai dos 300 pontos iniciais do Nível 2).
	raiz._ao_selecionar_tipo(DataTypes.Tipo.INT)
	_check("seleção de tipo na paleta atualiza _tipo_selecionado", raiz._tipo_selecionado == DataTypes.Tipo.INT)

	var pontos_antes: int = raiz._sistema.pontos
	raiz._ao_clicar_slot(0)
	_check("construir defesa gasta pontos (via clique real na cena)", raiz._sistema.pontos == pontos_antes - raiz._sistema.custo_de(DataTypes.Tipo.INT))
	_check("marcador '+' do slot 0 foi substituído pela torre", raiz._nos_slots[0]["torre_sprite"] != null)

	# Onda 0 do Nível 2 começa com "18" (int, atraso 0.0) — avança até ele
	# nascer, andar até o alcance do slot 0 (posição 0.15) e morrer, e o
	# nó visual correspondente (AnimatedSprite2D + Label) some da cena.
	var pontos_com_defesa: int = raiz._sistema.pontos
	var morreu := false
	for i in 40:
		raiz._process(0.05)
		if raiz._sistema.pontos > pontos_com_defesa:
			morreu = true
			break

	_check("o inimigo 'int' real foi destruído pela torre (pontos aumentaram)", morreu)
	_check("_sincronizar_inimigos() não deixou nó visual órfão do inimigo morto", raiz._nos_inimigos.size() == raiz._sistema.inimigos_ativos.size())

	raiz.queue_free()


func _testar_recusa_slot_ocupado() -> void:
	print("--- Nível 2: clique num slot ocupado é recusado (via feedback real) ---")
	var raiz := _instanciar("res://scenes/fase7_verificacaoTipos/Level2.tscn")

	raiz._ao_selecionar_tipo(DataTypes.Tipo.INT)
	raiz._ao_clicar_slot(0)
	raiz._ao_clicar_slot(0) # segunda vez no mesmo slot

	_check("feedback mostra o motivo da recusa", raiz._label_feedback.text.begins_with("✗"))

	raiz.queue_free()


func _testar_derrota_por_fuga() -> void:
	print("--- Nível 2: derrota real (nenhuma defesa construída) mostra TextoDerrota ---")
	var raiz := _instanciar("res://scenes/fase7_verificacaoTipos/Level2.tscn")

	# Sem construir nada, deixa toda a simulação correr até esvaziar a
	# barra do compilador (10 fugas de 10 de dano cada = 100).
	var passos := 0
	while raiz._sistema.jogo_ativo and passos < 2000:
		raiz._process(0.05)
		passos += 1

	_check("jogo termina (não fica girando pra sempre)", passos < 2000)
	_check("barra do compilador zerou", raiz._sistema.barra_compilador <= 0.0)
	_check("TextoDerrota real fica visível", raiz._texto_derrota.visible)
	_check("texto de derrota é o esperado", raiz._texto_derrota.text.findn("GAME OVER") != -1)

	raiz.queue_free()


func _testar_vitoria_nivel_2_completo() -> void:
	print("--- Nível 2: vitória real, construindo as 5 defesas conforme os pontos permitem ---")
	var raiz := _instanciar("res://scenes/fase7_verificacaoTipos/Level2.tscn")

	# 300 pontos iniciais não pagam as 5 defesas de uma vez (5 x 80 = 400,
	# GDD 5-B.2 — a economia É a estratégia); um jogador de verdade constrói
	# o que dá e completa a paleta conforme ganha pontos matando inimigos.
	# Cada slot i recebe o tipo tipos[i] (cobre o caminho inteiro em conjunto).
	var tipos: Array = raiz.level_data.tipos_disponiveis
	var passos := 0
	while raiz._sistema.jogo_ativo and passos < 6000:
		for i in tipos.size():
			if raiz._nos_slots[i]["torre_sprite"] == null and raiz._sistema.pontos >= raiz._sistema.custo_de(tipos[i]):
				raiz._ao_selecionar_tipo(tipos[i])
				raiz._ao_clicar_slot(i)
		raiz._process(0.05)
		passos += 1

	_check("nível termina (vitória ou derrota, não trava)", passos < 6000)
	_check("Nível 2 é vencível construindo defesas assim que os pontos permitem", raiz._sistema.venceu)
	_check("TextoDerrota real mostra vitória", raiz._texto_derrota.visible and raiz._texto_derrota.text.findn("CONCLUÍDO") != -1)
	_check("todos os 5 slots acabam com uma torre construída", raiz._nos_slots.all(func(s): return s["torre_sprite"] != null))

	raiz.queue_free()


func _testar_vitoria_nivel_4() -> void:
	print("--- Nível 4: vencível mesmo com 4 slots pra 5 tipos, usando troca de torre pra cobrir todos (v2.8) ---")
	var raiz := _instanciar("res://scenes/fase7_verificacaoTipos/Level4.tscn")

	# 4 slots, 5 tipos disponíveis (int/float/String/boolean/"Erro de
	# Tipo") — o aperto intencional do Nível 4 (GDD 5-B.4). Estratégia:
	# reserva 3 slots fixos pros tipos mais recorrentes (int/float, a
	# cadeia de widening, e "Erro de Tipo", que sozinho responde por 8 das
	# expressões inválidas das 5 ondas — o maior risco de dano de fuga) e
	# usa o 4º slot de forma adaptativa, trocando entre string/boolean
	# conforme o que está andando pelo caminho no momento — só possível
	# gastando pouco graças à mecânica de troca de torre (GDD 5-B.2/v2.6);
	# sem ela, teria que vender+reconstruir, que nem existe no MVP.
	raiz._ao_selecionar_tipo(DataTypes.Tipo.INT)
	raiz._ao_clicar_slot(0)
	raiz._ao_selecionar_tipo(DataTypes.Tipo.FLOAT)
	raiz._ao_clicar_slot(1)
	raiz._ao_selecionar_tipo(TowerDefenseSystem.DEFESA_ERRO)
	raiz._ao_clicar_slot(2)

	var tipo_flex_atual = null
	var passos := 0
	while raiz._sistema.jogo_ativo and passos < 8000:
		for inimigo in raiz._sistema.inimigos_ativos:
			var tipo = inimigo["defesa_correta"]
			if (tipo == DataTypes.Tipo.STRING or tipo == DataTypes.Tipo.BOOLEAN) and tipo != tipo_flex_atual:
				if raiz._sistema.pontos >= raiz._sistema.custo_de(tipo):
					raiz._ao_selecionar_tipo(tipo)
					raiz._ao_clicar_slot(3)
					tipo_flex_atual = tipo
				break
		raiz._process(0.05)
		passos += 1

	_check("nível termina (vitória ou derrota, não trava)", passos < 8000)
	_check("Nível 4 é vencível cobrindo int/float/erro fixos e alternando string/boolean no 4º slot", raiz._sistema.venceu)
	_check("jogando bem, nem um inimigo escapa (barra do compilador continua em 100%%)", raiz._sistema.barra_compilador == 100.0)

	raiz.queue_free()


func _testar_arrastar_e_soltar_constroi_defesa() -> void:
	print("--- Nível 2: arrastar uma torre da paleta e soltar num slot vazio constrói ---")
	var raiz := _instanciar("res://scenes/fase7_verificacaoTipos/Level2.tscn")

	_check("antes do arraste, nenhum slot está ocupado", raiz._nos_slots.all(func(s): return s["torre_sprite"] == null))

	raiz._iniciar_arraste(DataTypes.Tipo.FLOAT)
	_check("_iniciar_arraste() liga o estado de arraste", raiz._arrastando and raiz._tipo_arrastado == DataTypes.Tipo.FLOAT)
	_check("_iniciar_arraste() cria o ícone-fantasma que acompanha o mouse", raiz._ghost_arraste != null)

	var slot2: Dictionary = raiz._nos_slots[2]
	var pontos_antes: int = raiz._sistema.pontos
	var sucesso: bool = raiz._finalizar_arraste_em_posicao(Vector2(slot2["x"], slot2["y"]))

	_check("soltar em cima de um slot vazio constrói a defesa", sucesso)
	_check("a torre certa (float) aparece no slot 2", raiz._nos_slots[2]["torre_sprite"] != null)
	_check("construir por arraste também gasta pontos, igual ao clique", raiz._sistema.pontos == pontos_antes - raiz._sistema.custo_de(DataTypes.Tipo.FLOAT))
	_check("o arraste termina depois de soltar (estado limpo)", not raiz._arrastando and raiz._ghost_arraste == null)

	raiz.queue_free()


func _testar_arrastar_e_soltar_fora_do_alcance_cancela() -> void:
	print("--- Nível 2: soltar longe de qualquer slot cancela sem gastar pontos ---")
	var raiz := _instanciar("res://scenes/fase7_verificacaoTipos/Level2.tscn")

	var pontos_antes: int = raiz._sistema.pontos
	raiz._iniciar_arraste(DataTypes.Tipo.STRING)
	# Bem no meio do caminho (longe de todos os slots, que ficam acima dele).
	var sucesso: bool = raiz._finalizar_arraste_em_posicao(Vector2(640, 420))

	_check("soltar longe de um slot não constrói nada", not sucesso)
	_check("nenhum slot foi ocupado", raiz._nos_slots.all(func(s): return s["torre_sprite"] == null))
	_check("nenhum ponto foi gasto (posicionamento cancelado)", raiz._sistema.pontos == pontos_antes)
	_check("o ícone-fantasma some depois do cancelamento", raiz._ghost_arraste == null)

	raiz.queue_free()


func _testar_trocar_torre_por_clique() -> void:
	print("--- Nível 2: clicar numa torre já construída com outro tipo troca ela (GDD 5-B.2) ---")
	var raiz := _instanciar("res://scenes/fase7_verificacaoTipos/Level2.tscn")

	raiz._ao_selecionar_tipo(DataTypes.Tipo.INT)
	raiz._ao_clicar_slot(0)
	_check("torre int construída no slot 0", raiz._sistema.slots[0]["tipo_defesa"] == DataTypes.Tipo.INT)

	var sprite_antes: AnimatedSprite2D = raiz._nos_slots[0]["torre_sprite"]
	var frames_antes: SpriteFrames = sprite_antes.sprite_frames
	var pontos_antes: int = raiz._sistema.pontos

	raiz._ao_selecionar_tipo(DataTypes.Tipo.STRING)
	var sucesso: bool = raiz._ao_clicar_slot(0) # slot já ocupado -> troca, não constrói de novo

	_check("clicar na torre já construída com outro tipo selecionado troca com sucesso", sucesso)
	_check("slot 0 agora é do tipo novo (string)", raiz._sistema.slots[0]["tipo_defesa"] == DataTypes.Tipo.STRING)
	_check("continua sendo a MESMA instância de torre (só troca a arte, não duplica)", raiz._nos_slots[0]["torre_sprite"] == sprite_antes)
	_check("a arte/animação da torre mudou pro tipo novo", raiz._nos_slots[0]["torre_sprite"].sprite_frames != frames_antes)
	_check("a torre trocada volta a tocar 'parado' (não fica travada em 'ataque')", raiz._nos_slots[0]["torre_sprite"].animation == &"parado")
	_check("custo do tipo NOVO foi descontado, sem reembolso do antigo", raiz._sistema.pontos == pontos_antes - raiz._sistema.custo_de(DataTypes.Tipo.STRING))
	_check("feedback confirma a troca", raiz._label_feedback.text.begins_with("✓") and raiz._label_feedback.text.findn("trocada") != -1)

	raiz.queue_free()


func _testar_trocar_torre_mesmo_tipo_recusa() -> void:
	print("--- Nível 2: clicar numa torre já construída com o MESMO tipo selecionado recusa ---")
	var raiz := _instanciar("res://scenes/fase7_verificacaoTipos/Level2.tscn")

	raiz._ao_selecionar_tipo(DataTypes.Tipo.INT)
	raiz._ao_clicar_slot(0)
	var pontos_antes: int = raiz._sistema.pontos

	var sucesso: bool = raiz._ao_clicar_slot(0) # mesmo tipo já selecionado, slot já ocupado

	_check("clicar de novo com o mesmo tipo já construído não conta como sucesso", not sucesso)
	_check("nenhum ponto foi gasto numa troca recusada", raiz._sistema.pontos == pontos_antes)
	_check("torre continua sendo do tipo original", raiz._sistema.slots[0]["tipo_defesa"] == DataTypes.Tipo.INT)
	_check("feedback mostra o motivo da recusa", raiz._label_feedback.text.begins_with("✗"))

	raiz.queue_free()


func _testar_trocar_torre_por_arraste() -> void:
	print("--- Nível 2: arrastar um tipo novo até um slot já ocupado também troca a torre ---")
	var raiz := _instanciar("res://scenes/fase7_verificacaoTipos/Level2.tscn")

	raiz._ao_selecionar_tipo(DataTypes.Tipo.FLOAT)
	raiz._ao_clicar_slot(2)
	_check("torre float construída no slot 2", raiz._sistema.slots[2]["tipo_defesa"] == DataTypes.Tipo.FLOAT)

	var slot2: Dictionary = raiz._nos_slots[2]
	var sprite_antes: AnimatedSprite2D = slot2["torre_sprite"]
	var pontos_antes: int = raiz._sistema.pontos

	raiz._iniciar_arraste(DataTypes.Tipo.BOOLEAN)
	var sucesso: bool = raiz._finalizar_arraste_em_posicao(Vector2(slot2["x"], slot2["y"]))

	_check("soltar um tipo novo em cima de uma torre já construída troca com sucesso", sucesso)
	_check("slot 2 agora é do tipo arrastado (boolean)", raiz._sistema.slots[2]["tipo_defesa"] == DataTypes.Tipo.BOOLEAN)
	_check("é a mesma instância de torre (arraste não duplica sprite)", raiz._nos_slots[2]["torre_sprite"] == sprite_antes)
	_check("custo do tipo novo foi descontado por arraste também, sem reembolso", raiz._sistema.pontos == pontos_antes - raiz._sistema.custo_de(DataTypes.Tipo.BOOLEAN))
	_check("o arraste termina depois de soltar (estado limpo)", not raiz._arrastando and raiz._ghost_arraste == null)

	raiz.queue_free()


func _testar_trocar_torre_pontos_insuficientes_mantem_antiga() -> void:
	print("--- Nível 2: troca recusada por falta de pontos mantém a torre antiga intacta ---")
	var raiz := _instanciar("res://scenes/fase7_verificacaoTipos/Level2.tscn")

	raiz._ao_selecionar_tipo(DataTypes.Tipo.INT)
	raiz._ao_clicar_slot(0) # gasta 80 dos 300 iniciais
	raiz._sistema.pontos = 10 # simula ter gasto o resto em outras torres

	var frames_antes: SpriteFrames = raiz._nos_slots[0]["torre_sprite"].sprite_frames
	raiz._ao_selecionar_tipo(DataTypes.Tipo.STRING)
	var sucesso: bool = raiz._ao_clicar_slot(0)

	_check("troca falha por falta de pontos pro custo do tipo novo", not sucesso)
	_check("torre antiga (int) continua no slot", raiz._sistema.slots[0]["tipo_defesa"] == DataTypes.Tipo.INT)
	_check("a arte/animação da torre não mudou", raiz._nos_slots[0]["torre_sprite"].sprite_frames == frames_antes)
	_check("feedback mostra o motivo da recusa", raiz._label_feedback.text.begins_with("✗"))

	raiz.queue_free()


func _testar_explosao_ao_matar_inimigo() -> void:
	print("--- Nível 2: explosão real ao eliminar um inimigo, some sozinha depois ---")
	var raiz := _instanciar("res://scenes/fase7_verificacaoTipos/Level2.tscn")

	raiz._ao_selecionar_tipo(DataTypes.Tipo.INT)
	raiz._ao_clicar_slot(0)

	var morreu := false
	for i in 40:
		raiz._process(0.05)
		if raiz._explosoes_ativas.size() > 0:
			morreu = true
			break

	_check("matar um inimigo real cria uma explosão na cena", morreu)
	_check("a explosão fica no contêiner certo (Explosoes)", morreu and raiz._explosoes_container.get_child_count() > 0)
	_check("a explosão é um AnimatedSprite2D (v2.13 — não mais TextureRect+AnimatedTexture.duplicate())",
		morreu and raiz._explosoes_ativas[0]["no"] is AnimatedSprite2D)
	_check("a explosão usa o SpriteFrames compartilhado (nunca duplicado)",
		morreu and raiz._explosoes_ativas[0]["no"].sprite_frames == raiz.EXPLOSAO_INIMIGO_FRAMES)
	_check("a explosão já está tocando a animação 'explodir'",
		morreu and raiz._explosoes_ativas[0]["no"].animation == &"explodir")

	# Avança tempo suficiente pra explosão terminar sozinha (~0.67s).
	for i in 20:
		raiz._process(0.05)

	# queue_free() só remove de fato no próximo frame ocioso da engine, que
	# não passa sozinho em --headless --script; is_empty() em
	# _explosoes_ativas (nosso próprio rastreamento) já confirma que o
	# controller parou de contar a explosão como ativa.
	_check("a explosão some sozinha depois de tocar (não fica infinita)", raiz._explosoes_ativas.is_empty())

	raiz.queue_free()


func _testar_multiplas_explosoes_sao_instancias_independentes() -> void:
	print("--- Nível 3: várias explosões seguidas são nós/instâncias independentes (bug real v2.13) ---")
	print("    (a 2ª explosão em diante aparecia como um quadrado branco — TextureRect+AnimatedTexture.duplicate() tinha")
	print("     um bug de renderização real no Godot 4.7 pra duplicatas; corrigido trocando pra AnimatedSprite2D+SpriteFrames)")
	var raiz := _instanciar("res://scenes/fase7_verificacaoTipos/Level3.tscn")

	var tipos: Array = raiz.level_data.tipos_disponiveis.duplicate()
	for i in mini(tipos.size(), raiz._nos_slots.size()):
		raiz._ao_selecionar_tipo(tipos[i])
		raiz._ao_clicar_slot(i)

	var nos_vistos: Array = []
	for i in 400:
		raiz._process(0.05)
		for entrada in raiz._explosoes_ativas:
			if not nos_vistos.has(entrada["no"]):
				nos_vistos.append(entrada["no"])
		if nos_vistos.size() >= 3:
			break

	_check("pelo menos 3 explosões diferentes aconteceram nessa partida", nos_vistos.size() >= 3)
	for i in nos_vistos.size():
		_check("explosão #%d é um AnimatedSprite2D válido, tocando 'explodir'" % (i + 1),
			is_instance_valid(nos_vistos[i]) and nos_vistos[i].animation == &"explodir")

	raiz.queue_free()


func _testar_animacao_ataque_torre() -> void:
	print("--- Nível 2: torre construída toca animação 'ataque' ao eliminar, depois volta a 'parado' (v2.12) ---")
	var raiz := _instanciar("res://scenes/fase7_verificacaoTipos/Level2.tscn")

	raiz._ao_selecionar_tipo(DataTypes.Tipo.INT)
	raiz._ao_clicar_slot(0)

	var sprite: AnimatedSprite2D = raiz._nos_slots[0]["torre_sprite"]
	_check("torre recém-construída toca 'parado' (não estática)", sprite.animation == &"parado")
	_check("torre recém-construída não começa 'atacando'", not raiz._nos_slots[0]["atacando"])

	var atacou := false
	for i in 40:
		raiz._process(0.05)
		if raiz._nos_slots[0]["atacando"]:
			atacou = true
			break

	_check("eliminar um inimigo do tipo certo dispara a animação 'ataque' da torre", atacou)
	_check("a torre troca pra animação 'ataque' de verdade", sprite.animation == &"ataque")

	# Avança tempo suficiente pra animação de ataque terminar sozinha
	# (5 quadros / 10 fps + margem, ~0,65s) e a torre voltar a "parado".
	for i in 20:
		raiz._process(0.05)

	_check("a torre volta a 'parado' sozinha depois do ataque (não fica travada em 'ataque')", not raiz._nos_slots[0]["atacando"])
	_check("a animação da torre voltou a ser 'parado'", sprite.animation == &"parado")

	raiz.queue_free()


func _testar_escala_torre_normalizada_entre_resolucoes() -> void:
	print("--- Nível 4: torres de resoluções diferentes (700x700 e 1254x1254) aparecem do mesmo tamanho na tela (v2.12) ---")
	var raiz := _instanciar("res://scenes/fase7_verificacaoTipos/Level4.tscn")

	# Nível 4 tem os 5 tipos de defesa + Erro de Tipo disponíveis (GDD 6.3) —
	# boolean/string/char vieram em 700x700, int/float/Erro de Tipo em
	# 1254x1254 (ver assets/sprites/towers/). Constrói um de cada grupo.
	raiz._ao_selecionar_tipo(DataTypes.Tipo.BOOLEAN) # 700x700
	raiz._ao_clicar_slot(0)
	raiz._ao_selecionar_tipo(DataTypes.Tipo.INT) # 1254x1254
	raiz._ao_clicar_slot(1)

	var sprite_700: AnimatedSprite2D = raiz._nos_slots[0]["torre_sprite"]
	var sprite_1254: AnimatedSprite2D = raiz._nos_slots[1]["torre_sprite"]
	var largura_700: float = sprite_700.sprite_frames.get_frame_texture(&"parado", 0).get_width()
	var largura_1254: float = sprite_1254.sprite_frames.get_frame_texture(&"parado", 0).get_width()

	_check("os quadros de origem têm resoluções diferentes de verdade (senão o teste não prova nada)", largura_700 != largura_1254)

	var tamanho_final_700 := largura_700 * sprite_700.scale.x
	var tamanho_final_1254 := largura_1254 * sprite_1254.scale.x
	_check(
		"as duas torres acabam do mesmo tamanho na tela (diferença < 1px), mesmo com origem em resoluções diferentes",
		absf(tamanho_final_700 - tamanho_final_1254) < 1.0
	)

	raiz.queue_free()


func _testar_painel_explicacao_minimiza() -> void:
	print("--- Nível 2: painel de explicação da fase aparece cheio e minimiza sozinho ---")
	var raiz := _instanciar("res://scenes/fase7_verificacaoTipos/Level2.tscn")

	_check("painel começa expandido, mostrando o texto", not raiz._painel_minimizado and raiz._painel_corpo.visible)
	_check("título do painel é o esperado", raiz._painel_titulo.text.findn("TORRE DA VERIFICAÇÃO") != -1)
	_check("texto do painel menciona o portão da compilação", raiz._painel_corpo.text.findn("portão") != -1)

	# Avança mais tempo do que DURACAO_PAINEL_EXPLICACAO sem interação.
	for i in 200:
		raiz._process(0.05)

	_check("painel minimiza sozinho depois de um tempo sem interação", raiz._painel_minimizado)
	_check("corpo do texto fica escondido quando minimizado", not raiz._painel_corpo.visible)
	_check("dica minimizada fica visível", raiz._painel_dica.visible)

	# Clicar de novo reabre (toggle manual do jogador).
	raiz._ao_gui_input_painel_explicacao(InputEventMouseButton.new())
	_check("clicar num evento que não é botão esquerdo pressionado não muda nada", raiz._painel_minimizado)

	var clique := InputEventMouseButton.new()
	clique.button_index = MOUSE_BUTTON_LEFT
	clique.pressed = true
	raiz._ao_gui_input_painel_explicacao(clique)
	_check("clicar no painel minimizado reabre ele", not raiz._painel_minimizado and raiz._painel_corpo.visible)

	raiz.queue_free()
