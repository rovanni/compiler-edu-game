## tower_defense_level_controller.gd
##
## Script ÚNICO compartilhado pelos Níveis 2, 3 (e futuramente 4) da
## mecânica Tower Defense (GDD seção 5-B, v2.0+) — a única diferença entre
## eles é o `level_data` (DefenseLevelData, ver defense_level_data.gd /
## defense_level_data_factory.gd), igual ao padrão já usado no
## typetris_level_controller.gd (mecânica antiga, substituída). Toda a
## simulação (ondas, movimento, combate, fuga, vitória/derrota) mora no
## `tower_defense_system.gd`, um componente puro de dados — este script só
## traduz o estado dele pra nós visuais e o input do jogador pra chamadas
## nele. Nunca duplica regra de jogo aqui.
##
## v2.5 (melhorias de jogabilidade pedidas pelo Anibal, mantendo o visual e
## os assets já existentes): torres agora se posicionam por arrastar e
## soltar (além do clique antigo, que continua funcionando), nome do tipo
## embaixo de cada torre na paleta, correção do alinhamento do caminho
## (bug real na geração da cena — CaminhoVisual tinha sido salvo no
## tamanho nativo da textura, 1672x941, em vez de escalado pro canvas,
## fazendo os inimigos andarem fora da faixa de terra visível), painel de
## explicação da fase que minimiza sozinho, explosão por inimigo eliminado
## (reaproveita `explosao_falha_anim.tres`) e um portão visual do
## compilador no fim do caminho.
##
## v2.6 (mecânica de troca de torre, pedida pelo Anibal — GDD 5-B.2): dá
## pra substituir uma torre já construída por outra de tipo diferente,
## clicando nela (com outro tipo selecionado na paleta) ou arrastando um
## novo tipo até um slot já ocupado. Cobra o custo cheio do tipo novo, sem
## reembolso do que já foi gasto na torre antiga.
##
## v2.8 (Nível 4 montado, variante "corrompida" do inimigo finalmente
## usada): todo inimigo cuja `defesa_correta` é `DEFESA_ERRO` (expressão ou
## atribuição inválida — Níveis 3 e 4) agora usa a arte "corrompida" de
## verdade (núcleo vermelho/rachado, garras, `!`/`{ }` soltos — recebida na
## v2.4, só sentada até agora) em vez do inimigo base recolorido de
## vermelho via `modulate`. Como essa arte já vem com a cor de erro
## própria, ela NÃO é recolorida (só o inimigo base é). Isso também deixa
## os inimigos de erro do Nível 3 mais nítidos, de graça, por ser o mesmo
## controller compartilhado.
##
## Nós esperados na cena (ver _gen_level23_td_scenes.gd):
##   Fundo — TextureRect com o fundo da Torre
##   CaminhoVisual — TextureRect com a trilha (GDD 5-B.5), sobreposta ao fundo
##   PainelExplicacao — explicação curta da fase, minimiza sozinha
##   HUD/Info, HUD/BarraCompilador, HUD/Feedback
##   Slots — Control vazio; os marcadores "+" e as torres construídas são
##     criados em código a partir de level_data.slots
##   Portao — marcador visual do "portão do compilador" no fim do caminho
##   Inimigos — Control vazio; um AnimatedSprite2D + Label por inimigo
##     ativo, sincronizado a cada frame com TowerDefenseSystem.inimigos_ativos
##   Explosoes — Control vazio; uma explosão por inimigo eliminado, some
##     sozinha depois de tocar uma vez
##   Paleta — Control vazio; um botão + nome do tipo por defesa disponível
##     nesse nível — clicável (seleciona o tipo, clique no slot constrói)
##     OU arrastável (segurar e soltar num slot vazio constrói direto)
##   ExplosaoDerrota, TextoDerrota — mesmo padrão dos outros níveis (derrota
##     E vitória reaproveitam TextoDerrota, só muda texto/cor)
extends Control

const DataTypes = preload("res://scripts/fase7_verificacaoTipos/data_types.gd")
const TowerDefenseSystem = preload("res://scripts/fase7_verificacaoTipos/tower_defense_system.gd")
const DefenseVisualAssets = preload("res://scripts/fase7_verificacaoTipos/defense_visual_assets.gd")
const INIMIGO_FRAMES := preload("res://assets/fase7_verificacaoTipos/sprites/enemies/inimigo_base_flutuar.tres")
const INIMIGO_CORROMPIDO_FRAMES := preload("res://assets/fase7_verificacaoTipos/sprites/enemies/inimigo_corrompido_flutuar.tres")
## Explosão ao eliminar um inimigo (v2.13 — trocado de AnimatedTexture pra
## SpriteFrames, ver comentário grande perto de _spawnar_explosao() mais
## abaixo pro motivo). O tamanho original (visual, GDD/histórico) era de um
## TextureRect de 90x90 encaixando a arte de 1254x1254 — ESCALA_EXPLOSAO_INIMIGO
## reproduz o mesmo tamanho final na tela com AnimatedSprite2D.scale.
const EXPLOSAO_INIMIGO_FRAMES := preload("res://assets/fase7_verificacaoTipos/sprites/effects/explosao_inimigo_flutuar.tres")
const ESCALA_EXPLOSAO_INIMIGO := 90.0 / 1254.0

## Qual nível esta instância representa — definido no Inspector (ou por
## quem instancia a cena) ANTES do _ready() rodar. Ver defense_level_data_factory.gd.
@export var level_data: DefenseLevelData

## Integração com o jogo principal (adicionada na integração desta fase ao
## `compiler-edu-game`): no projeto isolado cada Level2/3/4.tscn era aberto
## na mão pelo editor (F6), sem nenhuma transição entre eles. `_ao_vencer()`
## e `_ao_falhar()` agora criam botões em runtime pra navegar — "PRÓXIMO
## NÍVEL →" (usa level_data.numero pra saber a próxima cena; no Nível 4
## marca a Fase 7 como concluída no GameManager em vez de avançar) e
## "TENTAR NOVAMENTE" na derrota — sem alterar nenhuma regra de
## `tower_defense_system.gd`.
##
## Botões "Sair"/"Reiniciar" (pedido do Anibal): o "☰" sempre visível no
## canto superior esquerdo abre um painel de pausa — mesma ideia do
## `show_pause()` do HUD compartilhado (`scripts/common/game_hud.gd`,
## usado por fase1/fase2/fase5/fase6: fundo escurecido + painel central
## com CONTINUAR/VOLTAR AO MENU) — mas escrito à mão aqui, sem instanciar
## o GameHud, porque a Fase 7 já tem o próprio HUD (barra do
## compilador/pontos) e depender dos painéis internos do GameHud
## (privados, pensados pro layout dele) seria frágil. "REINICIAR"
## recarrega a cena atual; "SAIR PARA O MENU" chama
## `GameManager.abandon_phase()` (mesmo padrão de
## `fase1_tokens/main.gd:_voltar_menu()`) só quando a fase ainda não foi
## concluída de verdade, e volta pro menu.
const PHASE_ID := 7
const CENA_MENU := "res://scenes/menu/menu.tscn"

# Geometria do caminho dentro do canvas fixo de 1280x720 (mesma resolução
# do resto do jogo — GDD 11 / project.godot). CAMINHO_Y_CENTRO é o centro
# vertical da FAIXA DE TERRA de verdade dentro da textura do caminho
# (medido com a textura já escalada certinho pro canvas — ver changelog
# v2.5; antes da correção, CaminhoVisual tinha o bug de tamanho nativo, e
# os inimigos acabavam andando bem mais acima da terra visível).
const CANVAS_LARGURA := 1280.0
const CAMINHO_Y_CENTRO := 420.0
const CAMINHO_MARGEM_X := 60.0
const TORRE_OFFSET_Y := -110.0
const TAMANHO_SLOT := 100.0
const ESCALA_TORRE := 0.11
const ESCALA_INIMIGO := 0.085

# v2.12 (animação das torres): ESCALA_TORRE acima foi calibrado a olho pra
# arte de 1254x1254 (o tamanho de todos os `torre_<tipo>.png` estáticos
# originais). Os quadros de animação recebidos do Anibal vieram em dois
# tamanhos (boolean/String/char em 700x700, int/float/Erro de Tipo em
# 1254x1254) — sem normalizar, a torre boolean/String/char apareceria
# visivelmente menor no campo que as outras 3. `_escala_torre_para()`
# corrige isso, escalando pelo tamanho real do quadro "parado" de cada
# tipo em vez de aplicar ESCALA_TORRE cru — deixa qualquer arte futura
# (de qualquer resolução) do mesmo tamanho final na tela.
const TAMANHO_REFERENCIA_TORRE := 1254.0

# Arraste de torres (seção "posicionamento por arrastar e soltar").
const RAIO_SNAP_DEFESA := 90.0

# Painel de explicação da fase (seção "explicação resumida da fase").
const DURACAO_PAINEL_EXPLICACAO := 6.0
const TITULO_PAINEL_EXPLICACAO := "TORRE DA VERIFICAÇÃO"
const TEXTO_PAINEL_EXPLICACAO := "As variáveis, atribuições e expressões estão avançando pelo caminho. Analise cada elemento e posicione as torres dos tipos corretos para impedir que cheguem ao portão da compilação. Cada torre consegue eliminar apenas elementos compatíveis com o seu tipo."
const ALTURA_PAINEL_EXPLICACAO_CHEIO := 96.0
const ALTURA_PAINEL_EXPLICACAO_MINI := 26.0

# Explosão por inimigo eliminado (reaproveita explosao_falha_anim.tres).
#
# v2.10 (correção real de bug — animação de explosão cortada antes da hora):
# o AnimatedTexture da explosão avança sozinho por tempo REAL de parede
# (a engine atualiza `current_frame` via um sinal global da RenderingServer,
# independente do _process()/delta do jogo — confirmado empiricamente com
# um diagnóstico ao vivo sob renderização real). Já a remoção da explosão
# (_atualizar_explosoes) sempre dependeu só do `delta` acumulado, pra
# continuar 100% testável sem tela (mesmo padrão de sempre evitar
# Timer/Tween). O problema: com DURACAO_EXPLOSAO_INIMIGO batendo EXATAMENTE
# com a duração da animação (8 quadros / 12 fps, sem folga nenhuma), um
# único frame mais pesado (comum logo que a fase carrega, numa onda cheia
# de inimigos, ou em qualquer engasgo momentâneo) faz o `delta` acumulado
# passar da marca ANTES do current_frame (que anda no próprio ritmo real)
# terminar de mostrar os 8 quadros — a explosão some com a animação cortada
# no meio. Corrigido com duas mudanças, as duas só aqui (não tocam
# TowerDefenseSystem.avancar()/combate/pontuação/remoção de inimigo —
# GDD/pedido do Anibal): DURACAO_EXPLOSAO_INIMIGO ganha uma margem de
# segurança (a explosão só some um pouco DEPOIS de ela já ter congelado no
# último quadro, nunca antes), e DELTA_MAXIMO_EXPLOSAO trava quanto um único
# frame pesado pode "comer" do cronômetro da explosão.
const QUADROS_EXPLOSAO_INIMIGO := 8.0
const FPS_EXPLOSAO_INIMIGO := 12.0
const MARGEM_SEGURANCA_EXPLOSAO := 0.25 # segundos de folga além da duração "nominal" da animação
const DURACAO_EXPLOSAO_INIMIGO := QUADROS_EXPLOSAO_INIMIGO / FPS_EXPLOSAO_INIMIGO + MARGEM_SEGURANCA_EXPLOSAO
const DELTA_MAXIMO_EXPLOSAO := 0.1 # nenhum frame isolado conta mais que isso pro cronômetro da explosão

# Animação de ataque das torres (v2.12, pedido do Anibal — GDD 5-B.5). Hoje
# o combate não tem "disparo" isolado nem taxa de ataque própria por torre
# (TowerDefenseSystem._resolver_combate() mata o inimigo assim que ele
# entra no alcance, a cada frame, sem cooldown — ver
# docs/Lista_Efeitos_Sonoros.md, seção 2.3, mesma observação vale aqui).
# Então a "velocidade de ataque" com que sincronizar a animação é uma só,
# igual pra todas as torres: QUADROS_ATAQUE_TORRE a
# VELOCIDADE_ATAQUE_TORRE_FPS por segundo, tocada do zero a cada inimigo
# eliminado por aquele tipo de torre. Mesma técnica de margem de segurança
# usada na correção da explosão (v2.10) — a torre só volta a ficar "parada"
# depois da animação de ataque já ter terminado visualmente, nunca antes,
# mesmo com engasgo momentâneo da engine.
const QUADROS_ATAQUE_TORRE := 5.0
const VELOCIDADE_ATAQUE_TORRE_FPS := 10.0
const MARGEM_SEGURANCA_ATAQUE_TORRE := 0.15
const DURACAO_ANIMACAO_ATAQUE_TORRE := QUADROS_ATAQUE_TORRE / VELOCIDADE_ATAQUE_TORRE_FPS + MARGEM_SEGURANCA_ATAQUE_TORRE
const DELTA_MAXIMO_ANIMACAO_TORRE := 0.1

var _sistema: TowerDefenseSystem
var _tipo_selecionado = null
var _onda_atual: int = 0

var _nos_inimigos: Dictionary = {} # id -> {"sprite": AnimatedSprite2D, "label": Label}
var _nos_slots: Array = [] # {"marcador": Button (fica vivo, só invisível quando ocupado), "torre_sprite": Sprite2D|null, "x": float, "y": float}
var _botoes_paleta: Array = []
var _explosoes_ativas: Array = [] # {"no": TextureRect, "tempo": float}

var _arrastando: bool = false
var _tipo_arrastado = null
var _ghost_arraste: Control = null

var _painel_minimizado: bool = false
var _tempo_painel_explicacao: float = 0.0

var _pausado: bool = false
var _painel_pausa: Control = null

@onready var _label_info: Label = $HUD/Info
@onready var _barra_compilador: ProgressBar = $HUD/BarraCompilador
@onready var _label_feedback: Label = $HUD/Feedback
@onready var _slots_container: Control = $Slots
@onready var _inimigos_container: Control = $Inimigos
@onready var _paleta_container: Control = $Paleta
@onready var _explosao_derrota: TextureRect = $ExplosaoDerrota
@onready var _texto_derrota: Label = $TextoDerrota
@onready var _explosoes_container: Control = $Explosoes
@onready var _painel_explicacao: Control = $PainelExplicacao
@onready var _painel_fundo: ColorRect = $PainelExplicacao/Fundo
@onready var _painel_titulo: Label = $PainelExplicacao/Titulo
@onready var _painel_corpo: Label = $PainelExplicacao/Corpo
@onready var _painel_dica: Label = $PainelExplicacao/Dica


func _ready() -> void:
	if level_data == null:
		push_error("tower_defense_level_controller: level_data não foi definido antes do _ready().")
		return

	if GameManager.current_phase_id != PHASE_ID:
		if GameManager.session_active:
			GameManager.begin_phase(PHASE_ID)
		else:
			GameManager.start_new_session(PHASE_ID)

	_sistema = TowerDefenseSystem.new()
	_sistema.defesa_recusada.connect(_ao_recusar_defesa)
	_sistema.defesa_trocada.connect(_ao_trocar_defesa)
	_sistema.onda_iniciada.connect(_ao_iniciar_onda)
	_sistema.inimigo_destruido.connect(_ao_inimigo_destruido)
	_sistema.compilacao_falhou.connect(_ao_falhar)
	_sistema.vitoria.connect(_ao_vencer)
	_sistema.inicializar(level_data)

	_montar_paleta()
	_montar_slots()
	_montar_painel_explicacao()
	_label_feedback.text = ""
	_atualizar_hud_info()
	_criar_botao_pausa()
	_criar_painel_pausa()


func _process(delta: float) -> void:
	if _pausado:
		return
	_atualizar_painel_explicacao(delta)
	_atualizar_ghost_arraste()
	_atualizar_explosoes(delta)
	_atualizar_animacoes_torres(delta)

	if _sistema == null or not _sistema.jogo_ativo:
		return
	_sistema.avancar(delta)
	_sincronizar_inimigos()
	_atualizar_hud_info()


# ---------------------------------------------------------------------------
# Geometria: posição X na tela pra um progresso 0.0-1.0 ao longo do caminho.
# Usada tanto pros slots (posição fixa) quanto pros inimigos (progresso muda
# a cada frame) — mesma escala pros dois, GDD 5-B.1.
# ---------------------------------------------------------------------------
func _x_da_posicao(progresso: float) -> float:
	return CAMINHO_MARGEM_X + progresso * (CANVAS_LARGURA - 2.0 * CAMINHO_MARGEM_X)


# ---------------------------------------------------------------------------
# Paleta de construção (escolher o tipo antes de clicar num slot, OU
# arrastar direto até um slot vazio — os dois jeitos funcionam).
# ---------------------------------------------------------------------------
func _montar_paleta() -> void:
	_botoes_paleta.clear()
	var tipos: Array = level_data.tipos_disponiveis
	var largura_total := 700.0
	var espaco := largura_total / tipos.size()
	var inicio_x := (CANVAS_LARGURA - largura_total) / 2.0 + espaco / 2.0

	for i in tipos.size():
		var tipo = tipos[i]
		var centro_x := inicio_x + i * espaco

		var botao := TextureButton.new()
		# ignore_texture_size é obrigatório ANTES de mexer em custom_minimum_size
		# /size: sem ele, o TextureButton usa o tamanho da própria textura
		# (1254x1254) como mínimo e ignora o tamanho pedido, estourando a
		# paleta pra fora da tela (bug real pego só no screenshot, v2.4).
		botao.ignore_texture_size = true
		botao.texture_normal = DefenseVisualAssets.textura_torre(tipo)
		botao.custom_minimum_size = Vector2(60, 60)
		botao.size = Vector2(60, 60)
		botao.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		botao.position = Vector2(centro_x - 30, 596)
		botao.modulate = Color(0.55, 0.55, 0.62, 0.9)
		botao.pressed.connect(_ao_selecionar_tipo.bind(tipo))
		# Arraste manual (não usa o drag-and-drop nativo do Control — mais
		# simples de testar sem mouse de verdade, ver _iniciar_arraste()):
		# segurar dispara o arraste, soltar em qualquer lugar da tela
		# resolve o drop, esteja ele em cima de um slot válido ou não.
		botao.button_down.connect(_iniciar_arraste.bind(tipo))
		botao.button_up.connect(_ao_soltar_arraste)
		_paleta_container.add_child(botao)

		var rotulo_nome := Label.new()
		rotulo_nome.text = _nome_tipo_defesa(tipo).to_upper()
		rotulo_nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rotulo_nome.position = Vector2(centro_x - 45, 658)
		rotulo_nome.size = Vector2(90, 18)
		_estilizar_label(rotulo_nome, Color(1, 0.95, 0.6), 13)
		_paleta_container.add_child(rotulo_nome)

		var rotulo_custo := Label.new()
		rotulo_custo.text = str(_sistema.custo_de(tipo)) if _sistema != null else str(level_data.custo_defesa.get(tipo, 0))
		rotulo_custo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rotulo_custo.position = Vector2(centro_x - 45, 676)
		rotulo_custo.size = Vector2(90, 18)
		_estilizar_label(rotulo_custo, Color(0.8, 0.9, 1.0), 13)
		_paleta_container.add_child(rotulo_custo)

		_botoes_paleta.append({"tipo": tipo, "botao": botao})


func _ao_selecionar_tipo(tipo) -> void:
	_tipo_selecionado = tipo
	for entrada in _botoes_paleta:
		var selecionado: bool = entrada["tipo"] == tipo
		entrada["botao"].modulate = Color(1, 1, 1, 1) if selecionado else Color(0.55, 0.55, 0.62, 0.9)
		entrada["botao"].scale = Vector2(1.15, 1.15) if selecionado else Vector2(1, 1)
	_label_feedback.text = "Selecionado: %s — clique num slot vazio, ou arraste a torre até lá" % _nome_tipo_defesa(tipo)


func _nome_tipo_defesa(tipo) -> String:
	if tipo == TowerDefenseSystem.DEFESA_ERRO:
		return "Erro de Tipo"
	return DataTypes.nome_tipo(tipo)


# ---------------------------------------------------------------------------
# Arrastar e soltar: segurar uma torre na paleta a faz acompanhar o mouse;
# soltar perto de um slot vazio constrói ali (mesma _sistema.construir_defesa
# de sempre); soltar em qualquer outro lugar cancela sem custo nenhum.
# Separado em duas funções pra ficar testável sem mouse de verdade:
# _iniciar_arraste()/_finalizar_arraste_em_posicao() tomam a posição como
# parâmetro; só _ao_soltar_arraste() (ligado ao clique real) lê o mouse.
# ---------------------------------------------------------------------------
func _iniciar_arraste(tipo) -> void:
	if _sistema == null or not _sistema.jogo_ativo:
		return
	_cancelar_arraste()
	_arrastando = true
	_tipo_arrastado = tipo

	var ghost := TextureRect.new()
	ghost.texture = DefenseVisualAssets.textura_torre(tipo)
	ghost.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ghost.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ghost.size = Vector2(72, 72)
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ghost.modulate = Color(1, 1, 1, 0.85)
	add_child(ghost)
	_ghost_arraste = ghost

	_label_feedback.text = "Arraste até uma área livre perto do caminho e solte pra construir"


func _atualizar_ghost_arraste() -> void:
	if _arrastando and _ghost_arraste != null:
		_ghost_arraste.position = get_local_mouse_position() - _ghost_arraste.size / 2.0


func _ao_soltar_arraste() -> void:
	if not _arrastando:
		return
	_finalizar_arraste_em_posicao(get_local_mouse_position())


## Resolve o drop na posição dada (coordenadas locais da cena, iguais às de
## `_nos_slots[i].x/y`) — usado tanto pelo mouse de verdade quanto pelos
## testes de integração. Retorna true se construiu OU trocou uma defesa
## (o mesmo `_ao_clicar_slot()` do clique cuida de decidir qual dos dois,
## conforme o slot já esteja ocupado ou não — GDD 5-B.2).
func _finalizar_arraste_em_posicao(pos: Vector2) -> bool:
	var sucesso := false
	if _tipo_arrastado != null:
		var indice := _indice_slot_proximo(pos, _tipo_arrastado)
		if indice != -1:
			_ao_selecionar_tipo(_tipo_arrastado)
			sucesso = _ao_clicar_slot(indice)
	_cancelar_arraste()
	return sucesso


func _cancelar_arraste() -> void:
	_arrastando = false
	_tipo_arrastado = null
	if _ghost_arraste != null:
		_ghost_arraste.queue_free()
		_ghost_arraste = null


## Slot mais próximo de `pos`, dentro do raio de snap — vazio OU já
## construído (soltar em cima de uma torre existente é como clicar nela:
## troca pelo tipo arrastado, GDD 5-B.2). Não filtra por tipo (qualquer
## defesa pode ir/trocar em qualquer slot, GDD 5-B.1), só por estar perto
## o bastante. -1 se nenhum slot estiver perto o bastante.
func _indice_slot_proximo(pos: Vector2, _tipo) -> int:
	var melhor_indice := -1
	var melhor_dist := RAIO_SNAP_DEFESA
	for i in _nos_slots.size():
		var alvo := Vector2(_nos_slots[i]["x"], _nos_slots[i]["y"])
		var dist := pos.distance_to(alvo)
		if dist <= melhor_dist:
			melhor_dist = dist
			melhor_indice = i
	return melhor_indice


# ---------------------------------------------------------------------------
# Slots de construção ao longo do caminho — sempre fora da faixa de terra
# (TORRE_OFFSET_Y levanta a torre pra área livre acima do caminho, GDD 5-B.1).
# ---------------------------------------------------------------------------
func _montar_slots() -> void:
	_nos_slots.clear()
	for i in level_data.slots.size():
		var slot: Dictionary = level_data.slots[i]
		var x := _x_da_posicao(slot["posicao"])
		var y := CAMINHO_Y_CENTRO + TORRE_OFFSET_Y

		var marcador := Button.new()
		marcador.text = "+"
		marcador.custom_minimum_size = Vector2(TAMANHO_SLOT, TAMANHO_SLOT)
		marcador.position = Vector2(x - TAMANHO_SLOT / 2.0, y - TAMANHO_SLOT / 2.0)
		marcador.add_theme_font_size_override("font_size", 30)
		marcador.modulate = Color(1, 1, 1, 0.55)
		marcador.pressed.connect(_ao_clicar_slot.bind(i))
		_slots_container.add_child(marcador)

		_nos_slots.append({
			"marcador": marcador, "torre_sprite": null, "x": x, "y": y,
			"atacando": false, "tempo_ataque": 0.0,
		})


## Clique num slot: constrói se ele estiver vazio, ou TROCA a torre já
## construída ali pelo tipo selecionado na paleta (mecânica de troca de
## torre pedida pelo Anibal, GDD 5-B.2) — o marcador continua vivo (só
## invisível) embaixo da torre construída justamente pra isso, já que um
## Sprite2D sozinho nunca receberia o clique de volta. Retorna true se
## construiu ou trocou com sucesso (usado pelo arrastar-e-soltar também).
func _ao_clicar_slot(indice: int) -> bool:
	if _tipo_selecionado == null:
		_label_feedback.text = "Escolha uma defesa na paleta antes de construir"
		return false

	var slot: Dictionary = _sistema.slots[indice]
	if slot["ocupado"]:
		var resultado := _sistema.trocar_defesa(indice, _tipo_selecionado)
		if resultado["sucesso"]:
			_label_feedback.text = "✓ Torre trocada para %s" % _nome_tipo_defesa(_tipo_selecionado)
		return resultado["sucesso"]
	else:
		var resultado := _sistema.construir_defesa(indice, _tipo_selecionado)
		if resultado["sucesso"]:
			_trocar_marcador_por_torre(indice, _tipo_selecionado)
			_label_feedback.text = "✓ Defesa construída"
		return resultado["sucesso"]


func _ao_recusar_defesa(_indice: int, motivo: String) -> void:
	_label_feedback.text = "✗ %s" % motivo


## Chamada quando `trocar_defesa()` dá certo (sinal defesa_trocada) — só
## precisa atualizar a arte/animação da torre já existente pro tipo novo; o
## texto de feedback já foi setado em `_ao_clicar_slot()`, que é sempre
## quem dispara a troca (por clique OU por arrastar-e-soltar). v2.12:
## também interrompe uma animação de ataque em andamento (não faz sentido
## a torre antiga continuar "atacando" depois de virar outro tipo).
func _ao_trocar_defesa(indice: int, _tipo_antigo, tipo_novo) -> void:
	var info: Dictionary = _nos_slots[indice]
	if info["torre_sprite"] != null:
		_aplicar_animacao_torre(info["torre_sprite"], tipo_novo)
	info["atacando"] = false
	info["tempo_ataque"] = 0.0


## Monta o AnimatedSprite2D de uma torre construída (ou trocada) com o
## SpriteFrames do `tipo` (animações "parado"/"ataque", v2.12 — GDD 5-B.5),
## sempre voltando a tocar "parado". A escala é recalculada a partir do
## tamanho real do quadro "parado" (ver TAMANHO_REFERENCIA_TORRE acima) —
## os quadros recebidos vieram em duas resoluções diferentes (700x700 e
## 1254x1254) e sem isso as torres apareceriam em tamanhos inconsistentes.
func _aplicar_animacao_torre(sprite: AnimatedSprite2D, tipo) -> void:
	var frames := DefenseVisualAssets.sprite_frames_torre(tipo)
	sprite.sprite_frames = frames
	sprite.animation = &"parado"
	sprite.play(&"parado")
	sprite.scale = Vector2.ONE * _escala_torre_para(sprite)


## Escala final da torre pra ficar do mesmo tamanho na tela não importa a
## resolução do quadro "parado" atual (ver nota em TAMANHO_REFERENCIA_TORRE).
func _escala_torre_para(sprite: AnimatedSprite2D) -> float:
	if sprite.sprite_frames == null or not sprite.sprite_frames.has_animation(&"parado"):
		return ESCALA_TORRE
	var textura: Texture2D = sprite.sprite_frames.get_frame_texture(&"parado", 0)
	if textura == null or textura.get_width() <= 0:
		return ESCALA_TORRE
	return ESCALA_TORRE * (TAMANHO_REFERENCIA_TORRE / float(textura.get_width()))


func _trocar_marcador_por_torre(indice: int, tipo) -> void:
	var info: Dictionary = _nos_slots[indice]
	if info["marcador"] != null:
		# Mantém o Button do marcador vivo, só escondido (texto vazio +
		# alpha 0) em vez de removê-lo: um AnimatedSprite2D não participa do
		# sistema de GUI input do Godot (só nós Control recebem clique),
		# então é esse Button que continua sendo o alvo real do
		# clique/arraste em cima da torre já construída — sem ele, a torre
		# nunca mais receberia input nenhum e a troca (GDD 5-B.2) seria
		# impossível.
		info["marcador"].text = ""
		info["marcador"].modulate = Color(1, 1, 1, 0)

	var sprite := AnimatedSprite2D.new()
	sprite.position = Vector2(info["x"], info["y"])
	_slots_container.add_child(sprite)
	_aplicar_animacao_torre(sprite, tipo)
	info["torre_sprite"] = sprite


# ---------------------------------------------------------------------------
# Inimigos: reconciliação a cada frame com TowerDefenseSystem.inimigos_ativos
# (mais simples e seguro do que tentar casar por evento — igual à
# _redesenhar_grade() do tabuleiro antigo). A animação "flutuar" (loop
# contínuo) toca desde a criação do nó e segue tocando sozinha enquanto o
# inimigo anda — não precisa de nada extra pra "manter a caminhada".
# ---------------------------------------------------------------------------
func _sincronizar_inimigos() -> void:
	var ids_vivos := {}
	for inimigo in _sistema.inimigos_ativos:
		var id: int = inimigo["id"]
		ids_vivos[id] = true
		if not _nos_inimigos.has(id):
			_criar_no_inimigo(inimigo)
		var no: Dictionary = _nos_inimigos[id]
		var pos := Vector2(_x_da_posicao(inimigo["progresso"]), CAMINHO_Y_CENTRO)
		no["sprite"].position = pos
		no["label"].position = pos + Vector2(-70, 40)

	for id in _nos_inimigos.keys():
		if not ids_vivos.has(id):
			_nos_inimigos[id]["sprite"].queue_free()
			_nos_inimigos[id]["label"].queue_free()
			_nos_inimigos.erase(id)


func _criar_no_inimigo(inimigo: Dictionary) -> void:
	var sprite := AnimatedSprite2D.new()
	sprite.scale = Vector2(ESCALA_INIMIGO, ESCALA_INIMIGO)
	# Expressão/atribuição inválida (Níveis 3 e 4, GDD 6.3) usa a arte
	# "corrompida" de verdade em vez do inimigo base recolorido de
	# vermelho — ela já vem com a própria cor de erro, então não recolore.
	if inimigo["defesa_correta"] == TowerDefenseSystem.DEFESA_ERRO:
		sprite.sprite_frames = INIMIGO_CORROMPIDO_FRAMES
		sprite.modulate = Color(1, 1, 1)
	else:
		sprite.sprite_frames = INIMIGO_FRAMES
		sprite.modulate = DefenseVisualAssets.cor_defesa(inimigo["defesa_correta"])
	sprite.play("flutuar")
	_inimigos_container.add_child(sprite)

	var rotulo := Label.new()
	rotulo.text = inimigo["texto"]
	rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rotulo.size = Vector2(140, 24)
	_estilizar_label(rotulo, Color(1, 1, 1), 15)
	_inimigos_container.add_child(rotulo)

	_nos_inimigos[inimigo["id"]] = {
		"sprite": sprite, "label": rotulo,
		"defesa_correta": inimigo["defesa_correta"], # v2.12: pra saber qual tipo de torre "atacou" ao eliminar
	}


# ---------------------------------------------------------------------------
# Explosão ao eliminar um inimigo (mesmos 8 quadros da explosão de derrota,
# ver assets/sprites/effects/) — dura DURACAO_EXPLOSAO_INIMIGO e some
# sozinha.
#
# v2.13 (bug real corrigido — animação só aparecia na 1ª explosão, todas as
# seguintes apareciam como um quadrado branco liso; reportado pelo Anibal
# depois da v2.10): a versão anterior usava TextureRect + um
# AnimatedTexture.duplicate() por explosão (pra cada instância ter seu
# próprio current_frame, já que current_frame é propriedade do Resource,
# não do nó — current_frame de verdade avançava certinho em CADA duplicata,
# conferido quadro a quadro). O bug estava na RENDERIZAÇÃO, não nos dados:
# reproduzido com screenshots reais de partidas inteiras — a 1ª explosão de
# cada cena sempre desenhava certo, a 2ª em diante desenhava um quadrado
# branco vazio (o "proxy" interno que o AnimatedTexture usa pra desenhar o
# quadro atual não fica correto pra instâncias criadas via duplicate() no
# Godot 4.7, aparentemente só pra segunda em diante). Resolvido trocando
# TextureRect+AnimatedTexture.duplicate() por AnimatedSprite2D+SpriteFrames
# — o MESMO padrão já usado (e comprovadamente confiável com várias
# instâncias simultâneas) pros inimigos ("flutuar") e pras torres
# ("parado"/"ataque", v2.12): o SpriteFrames é um recurso ÚNICO
# compartilhado (nunca duplicado — sem custo de duplicar nada), e cada
# AnimatedSprite2D guarda seu PRÓPRIO quadro atual no NÓ, não no recurso,
# então múltiplas instâncias nunca colidem nem têm o bug de renderização
# acima. Conferido com um teste ao vivo específico (várias explosões reais
# ao longo de uma partida inteira, screenshot de cada uma no pico) — todas
# renderizam certinho agora, não só a primeira.
# ---------------------------------------------------------------------------
func _ao_inimigo_destruido(id: int, _pontos: int) -> void:
	if not _nos_inimigos.has(id):
		return
	var pos: Vector2 = _nos_inimigos[id]["sprite"].position
	var tipo_derrotado = _nos_inimigos[id]["defesa_correta"]
	_spawnar_explosao(pos)
	_disparar_ataque_torres(tipo_derrotado)


func _spawnar_explosao(pos: Vector2) -> void:
	var no := AnimatedSprite2D.new()
	no.sprite_frames = EXPLOSAO_INIMIGO_FRAMES
	no.scale = Vector2.ONE * ESCALA_EXPLOSAO_INIMIGO
	no.position = pos
	_explosoes_container.add_child(no)
	no.play(&"explodir")

	_explosoes_ativas.append({"no": no, "tempo": 0.0})


func _atualizar_explosoes(delta: float) -> void:
	var i := _explosoes_ativas.size() - 1
	while i >= 0:
		var entrada: Dictionary = _explosoes_ativas[i]
		entrada["tempo"] += min(delta, DELTA_MAXIMO_EXPLOSAO)
		if entrada["tempo"] >= DURACAO_EXPLOSAO_INIMIGO:
			entrada["no"].queue_free()
			_explosoes_ativas.remove_at(i)
		i -= 1


# ---------------------------------------------------------------------------
# Animação de ataque das torres (v2.12, GDD 5-B.5). TowerDefenseSystem não
# tem um evento de "disparo" isolado (mata o inimigo assim que ele entra no
# alcance, sem cooldown — mesma observação de docs/Lista_Efeitos_Sonoros.md
# seção 2.3), então o gatilho é o mesmo instante da explosão: toda torre
# construída CUJO TIPO bate com o tipo do inimigo que acabou de ser
# eliminado toca a animação "ataque" uma vez (não filtra por alcance de
# novo — se o inimigo morreu daquele tipo, alguma torre daquele tipo já
# estava no alcance certo, é a mesma regra de TowerDefenseSystem
# ._resolver_combate(), só não duplicada aqui). Mesma técnica de margem de
# segurança da correção da explosão (v2.10): a torre só volta a "parado"
# depois da animação já ter terminado visualmente, nunca antes.
# ---------------------------------------------------------------------------
func _disparar_ataque_torres(tipo_derrotado) -> void:
	for i in _nos_slots.size():
		if not _sistema.slots[i]["ocupado"]:
			continue
		if _sistema.slots[i]["tipo_defesa"] != tipo_derrotado:
			continue
		var info: Dictionary = _nos_slots[i]
		var sprite: AnimatedSprite2D = info["torre_sprite"]
		if sprite == null:
			continue
		sprite.play(&"ataque")
		info["atacando"] = true
		info["tempo_ataque"] = 0.0


func _atualizar_animacoes_torres(delta: float) -> void:
	for info in _nos_slots:
		if not info["atacando"]:
			continue
		info["tempo_ataque"] += min(delta, DELTA_MAXIMO_ANIMACAO_TORRE)
		if info["tempo_ataque"] >= DURACAO_ANIMACAO_ATAQUE_TORRE:
			info["atacando"] = false
			var sprite: AnimatedSprite2D = info["torre_sprite"]
			if sprite != null:
				sprite.play(&"parado")


# ---------------------------------------------------------------------------
# Painel de explicação da fase — aparece cheio no início, minimiza sozinho
# depois de DURACAO_PAINEL_EXPLICACAO segundos, e o jogador pode clicar
# nele a qualquer momento pra abrir/fechar de novo.
# ---------------------------------------------------------------------------
func _montar_painel_explicacao() -> void:
	_painel_titulo.text = TITULO_PAINEL_EXPLICACAO
	_painel_corpo.text = TEXTO_PAINEL_EXPLICACAO
	_painel_dica.text = "▾ %s — toque pra ver como jogar" % TITULO_PAINEL_EXPLICACAO
	# is_connected() evita erro se _ready() rodar mais de uma vez sobre o
	# mesmo nó de cena (acontece nos scripts de teste/diagnóstico que
	# chamam _ready() na mão — a engine já chama sozinha ao entrar na
	# árvore; a segunda chamada é redundante mas inofensiva pros outros
	# passos de _ready(), que recriam objetos do zero em vez de conectar
	# um sinal de nó fixo).
	if not _painel_explicacao.gui_input.is_connected(_ao_gui_input_painel_explicacao):
		_painel_explicacao.gui_input.connect(_ao_gui_input_painel_explicacao)
	_painel_minimizado = false
	_tempo_painel_explicacao = 0.0
	_atualizar_layout_painel_explicacao()


func _atualizar_painel_explicacao(delta: float) -> void:
	if _painel_minimizado:
		return
	_tempo_painel_explicacao += delta
	if _tempo_painel_explicacao >= DURACAO_PAINEL_EXPLICACAO:
		_painel_minimizado = true
		_atualizar_layout_painel_explicacao()


func _ao_gui_input_painel_explicacao(evento: InputEvent) -> void:
	if evento is InputEventMouseButton and evento.pressed and evento.button_index == MOUSE_BUTTON_LEFT:
		_painel_minimizado = not _painel_minimizado
		_atualizar_layout_painel_explicacao()


func _atualizar_layout_painel_explicacao() -> void:
	var altura := ALTURA_PAINEL_EXPLICACAO_MINI if _painel_minimizado else ALTURA_PAINEL_EXPLICACAO_CHEIO
	_painel_explicacao.size = Vector2(CANVAS_LARGURA, altura)
	_painel_fundo.size = Vector2(CANVAS_LARGURA, altura)
	_painel_titulo.visible = not _painel_minimizado
	_painel_corpo.visible = not _painel_minimizado
	_painel_dica.visible = _painel_minimizado


# ---------------------------------------------------------------------------
# HUD, ondas, fim de jogo (GDD 8.3/8.4, mesmo padrão dos outros níveis)
# ---------------------------------------------------------------------------
func _ao_iniciar_onda(indice: int) -> void:
	_onda_atual = indice


func _atualizar_hud_info() -> void:
	var total_ondas: int = level_data.ondas.size()
	_label_info.text = "%s   ·   PONTOS: %d   ·   ONDA %d/%d" % [
		level_data.nome, _sistema.pontos, _onda_atual + 1, total_ondas
	]
	_barra_compilador.value = _sistema.barra_compilador


func _ao_falhar() -> void:
	_label_feedback.text = ""
	_texto_derrota.text = "A compilação falhou\nGAME OVER"
	_texto_derrota.add_theme_color_override("font_color", Color(1.0, 0.35, 0.3))
	_texto_derrota.visible = true
	var anim := _explosao_derrota.texture as AnimatedTexture
	if anim != null:
		anim.current_frame = 0
	_explosao_derrota.visible = true
	_criar_botao_tentar_novamente()


func _ao_vencer() -> void:
	_label_feedback.text = ""
	_texto_derrota.text = "NÍVEL CONCLUÍDO!\n%d pontos" % _sistema.pontos
	_texto_derrota.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
	_texto_derrota.visible = true

	if level_data.numero < 4:
		GameManager.award_sub_phase_bonus()
		_criar_botao_avancar("PRÓXIMO NÍVEL →", "res://scenes/fase7_verificacaoTipos/Level%d.tscn" % (level_data.numero + 1))
	else:
		# Última etapa da fase (Nível 4) — só aqui a Fase 7 é marcada como
		# concluída no menu principal (mesmo padrão da Fase 6: sub-níveis
		# dão bônus de pontos, só o último chama complete_phase()).
		# "Sem erros" aqui é aproximado pela barra do compilador deste
		# nível não ter caído (não rastreia across os 4 níveis inteiros,
		# diferente do Fase6Estado — simplificação deliberada, documentada
		# no PR de integração).
		var sem_erros := _sistema.barra_compilador >= 100.0
		GameManager.complete_phase(PHASE_ID, sem_erros)
		_criar_botao_avancar("VOLTAR AO MENU", CENA_MENU)


func _estilizar_label(lbl: Label, cor: Color, tam_fonte: int) -> void:
	lbl.add_theme_color_override("font_color", cor)
	lbl.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.02))
	lbl.add_theme_constant_override("outline_size", 3)
	lbl.add_theme_font_size_override("font_size", tam_fonte)


## --- Navegação com o menu principal (ver nota de integração perto de level_data) ---

func _criar_botao(texto: String, cor: Color, pai: Node = null) -> Button:
	var botao := Button.new()
	botao.text = texto
	botao.add_theme_font_size_override("font_size", 16)
	botao.add_theme_color_override("font_color", Color.WHITE)
	botao.add_theme_color_override("font_outline_color", Color.BLACK)
	botao.add_theme_constant_override("outline_size", 4)
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = cor
	estilo.border_color = Color.BLACK
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(8)
	estilo.content_margin_left = 10
	estilo.content_margin_right = 10
	estilo.content_margin_top = 6
	estilo.content_margin_bottom = 6
	botao.add_theme_stylebox_override("normal", estilo)
	(pai if pai != null else self).add_child(botao)
	return botao


## Nota: usamos anchor_*/offset_* explícitos em vez de set_anchors_preset()
## + position/size — com anchor_left == anchor_right (ponto de ancoragem
## fixo, não "faixa"), position/size viram ambíguos dependendo da ordem de
## chamada; anchor+offset direto é determinístico em qualquer canto da tela.

func _criar_botao_pausa() -> void:
	var botao := _criar_botao("☰", Color("1c2638"))
	botao.add_theme_font_size_override("font_size", 20)
	botao.anchor_left = 0.0
	botao.anchor_right = 0.0
	botao.anchor_top = 0.0
	botao.anchor_bottom = 0.0
	botao.offset_left = 8
	botao.offset_right = 48
	botao.offset_top = 10
	botao.offset_bottom = 46
	botao.tooltip_text = "Pausar"
	botao.pressed.connect(_abrir_pausa)


## Painel de pausa (ver nota de integração perto de level_data) — some da
## tela com "▶ CONTINUAR", reinicia a fase com "REINICIAR" ou volta pro
## menu com "SAIR PARA O MENU". Criado uma única vez em _ready() e só
## fica visível quando pausado.
func _criar_painel_pausa() -> void:
	_painel_pausa = Control.new()
	_painel_pausa.set_anchors_preset(Control.PRESET_FULL_RECT)
	_painel_pausa.visible = false
	_painel_pausa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_painel_pausa)

	var fundo := ColorRect.new()
	fundo.color = Color(0.01, 0.03, 0.06, 0.82)
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fundo.mouse_filter = Control.MOUSE_FILTER_STOP
	_painel_pausa.add_child(fundo)

	var titulo := Label.new()
	titulo.text = "JOGO PAUSADO"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 30)
	titulo.add_theme_color_override("font_color", Color("ffc43d"))
	titulo.add_theme_color_override("font_outline_color", Color.BLACK)
	titulo.add_theme_constant_override("outline_size", 4)
	titulo.anchor_left = 0.5
	titulo.anchor_right = 0.5
	titulo.anchor_top = 0.5
	titulo.anchor_bottom = 0.5
	titulo.offset_left = -160
	titulo.offset_right = 160
	titulo.offset_top = -130
	titulo.offset_bottom = -90
	_painel_pausa.add_child(titulo)

	var botao_continuar := _criar_botao("▶ CONTINUAR", Color("34a853"), _painel_pausa)
	botao_continuar.anchor_left = 0.5
	botao_continuar.anchor_right = 0.5
	botao_continuar.anchor_top = 0.5
	botao_continuar.anchor_bottom = 0.5
	botao_continuar.offset_left = -110
	botao_continuar.offset_right = 110
	botao_continuar.offset_top = -70
	botao_continuar.offset_bottom = -30
	botao_continuar.pressed.connect(_fechar_pausa)

	var botao_reiniciar := _criar_botao("REINICIAR", Color("2d6cdf"), _painel_pausa)
	botao_reiniciar.anchor_left = 0.5
	botao_reiniciar.anchor_right = 0.5
	botao_reiniciar.anchor_top = 0.5
	botao_reiniciar.anchor_bottom = 0.5
	botao_reiniciar.offset_left = -110
	botao_reiniciar.offset_right = 110
	botao_reiniciar.offset_top = -18
	botao_reiniciar.offset_bottom = 22
	botao_reiniciar.pressed.connect(func():
		get_tree().reload_current_scene()
	)

	var botao_sair := _criar_botao("SAIR PARA O MENU", Color("c0392b"), _painel_pausa)
	botao_sair.anchor_left = 0.5
	botao_sair.anchor_right = 0.5
	botao_sair.anchor_top = 0.5
	botao_sair.anchor_bottom = 0.5
	botao_sair.offset_left = -110
	botao_sair.offset_right = 110
	botao_sair.offset_top = 34
	botao_sair.offset_bottom = 74
	botao_sair.pressed.connect(_sair_para_menu)


func _abrir_pausa() -> void:
	_pausado = true
	# move_to_front() garante que o painel fica por cima de qualquer botão
	# criado depois dele (ex: "PRÓXIMO NÍVEL →"/"TENTAR NOVAMENTE", só
	# existem depois de vitória/derrota) — sem isso, um botão mais novo
	# desenharia por cima do fundo escurecido e continuaria clicável com o
	# jogo "pausado".
	_painel_pausa.move_to_front()
	_painel_pausa.visible = true


func _fechar_pausa() -> void:
	_pausado = false
	_painel_pausa.visible = false


func _sair_para_menu() -> void:
	if not GameManager.is_phase_completed(PHASE_ID):
		GameManager.abandon_phase()
	get_tree().change_scene_to_file(CENA_MENU)


## Botão único usado tanto pra "próximo nível" quanto pra "voltar ao menu"
## na vitória do Nível 4 — só muda o texto e a cena de destino.
func _criar_botao_avancar(texto: String, cena_destino: String) -> void:
	var botao := _criar_botao(texto, Color("34a853"))
	botao.anchor_left = 0.5
	botao.anchor_right = 0.5
	botao.anchor_top = 0.62
	botao.anchor_bottom = 0.62
	botao.offset_left = -100
	botao.offset_right = 100
	botao.offset_top = 0
	botao.offset_bottom = 40
	botao.pressed.connect(func():
		get_tree().change_scene_to_file(cena_destino)
	)


func _criar_botao_tentar_novamente() -> void:
	var botao := _criar_botao("TENTAR NOVAMENTE", Color("34a853"))
	botao.anchor_left = 0.5
	botao.anchor_right = 0.5
	botao.anchor_top = 0.62
	botao.anchor_bottom = 0.62
	botao.offset_left = -110
	botao.offset_right = 110
	botao.offset_top = 0
	botao.offset_bottom = 40
	botao.pressed.connect(func():
		get_tree().reload_current_scene()
	)
