## level1_controller.gd
##
## Script da cena scenes/levels/Level1.tscn — o Nível 1 jogável
## (Reconhecimento de Tipos, GDD seção 7). Cuida só da parte visual/input:
## mover a peça entre colunas, fazê-la cair, e chamar level1_logic.gd
## quando ela chega embaixo. Toda decisão de "acertou ou não" mora no
## Level1Logic — este script só lê o resultado e atualiza a tela.
##
## Nós esperados na cena (ver scenes/levels/Level1.tscn):
##   Colunas/Coluna0..Coluna4  — 5 ColorRect, na mesma ordem de Level1Logic.COLUNAS
##   PecaCaindo (+ PecaCaindo/Texto) — o valor caindo
##   HUD/Pontuacao, HUD/BarraCompilador, HUD/Feedback
##   ExplosaoDerrota — TextureRect escondido, toca a animação de explosão
##     (8 quadros, res://assets/fase7_verificacaoTipos/sprites/effects/explosao_falha_anim.tres)
##     quando a barra do compilador chega a 0% (GDD seção 10)
##   TextoDerrota — Label escondido, "A compilação falhou / GAME OVER"
##     centralizado na tela, por cima da explosão (entra depois dela na
##     árvore de nós, então desenha na frente)
##
## Integração com o jogo principal (adicionada na integração desta fase ao
## `compiler-edu-game`): o Nível 1 nunca teve uma condição de vitória
## própria (GDD seção 7 — é o nível de "aquecimento", sem tabuleiro de
## linhas nem ondas) e, no projeto isolado, cada nível era aberto na mão
## pelo editor (F6). Pra caber na navegação do menu principal, este script
## agora chama `GameManager.begin_phase(7)` ao entrar (mesmo padrão de
## fase1_tokens/fase4_ast) e cria botões em runtime — "☰" (pausa, sempre
## visível, canto superior esquerdo) e "PRÓXIMO NÍVEL →" (sempre
## clicável, já que não há vitória própria neste nível) — sem alterar
## nenhuma regra de jogo existente.
##
## Botões "Sair"/"Reiniciar" (pedido do Anibal): clicar em "☰" abre um
## painel de pausa — mesma ideia do `show_pause()` do HUD compartilhado
## (`scripts/common/game_hud.gd`, usado por fase1/fase2/fase5/fase6:
## fundo escurecido + painel central com CONTINUAR/VOLTAR AO MENU) — mas
## escrito à mão aqui, sem instanciar o GameHud, porque a Fase 7 já tem o
## próprio HUD (barra do compilador/pontos) e depender dos painéis
## internos do GameHud (privados, pensados pro layout dele) seria frágil.
## "REINICIAR" recarrega a cena atual; "SAIR PARA O MENU" chama
## `GameManager.abandon_phase()` (mesmo padrão de
## `fase1_tokens/main.gd:_voltar_menu()`) — só quando a fase ainda não foi
## concluída de verdade — e volta pro menu.
extends Control

const DataTypes = preload("res://scripts/fase7_verificacaoTipos/data_types.gd")
const Level1Logic = preload("res://scripts/fase7_verificacaoTipos/level1_logic.gd")

const PHASE_ID := 7
const CENA_MENU := "res://scenes/menu/menu.tscn"
const CENA_NIVEL_2 := "res://scenes/fase7_verificacaoTipos/Level2.tscn"

## Velocidade de queda em pixels/segundo — GDD 12: "velocidade de queda
## inicial baixa". Exposto no Inspector pra facilitar balancear por nível.
@export var velocidade_queda: float = 140.0

## Valores de exemplo pro Nível 1 (GDD seção 7: 18, "Maria", true, 7.5 — e
## 'A' porque char entrou no escopo, GDD 6.1). Inclui de propósito um caso
## de armadilha (\"A\" com aspas duplas é String, não char — GDD 6.2.1).
const POOL_VALORES := [
	"18", "7", "42", "100", "23",
	"3.14", "7.5", "2.5", "9.99", "0.5",
	"\"Maria\"", "\"João\"", "\"Ana\"", "\"Pedro\"", "\"gato\"",
	"true", "false",
	"'A'", "'z'", "'X'",
	"\"A\"",
]

var _logica: Level1Logic
var _colunas_nodes: Array = []
var _lane_atual: int = 2
var _peca_texto_atual: String = ""
var _y_alvo: float = 0.0
var _jogo_ativo: bool = true
var _pausado: bool = false
var _painel_pausa: Control = null

@onready var _peca_caindo: ColorRect = $PecaCaindo
@onready var _peca_texto_label: Label = $PecaCaindo/Texto
@onready var _colunas_container: Control = $Colunas
@onready var _label_pontuacao: Label = $HUD/Pontuacao
@onready var _barra_compilador: ProgressBar = $HUD/BarraCompilador
@onready var _label_feedback: Label = $HUD/Feedback
@onready var _explosao_derrota: TextureRect = $ExplosaoDerrota
@onready var _texto_derrota: Label = $TextoDerrota


func _ready() -> void:
	if GameManager.current_phase_id != PHASE_ID:
		if GameManager.session_active:
			GameManager.begin_phase(PHASE_ID)
		else:
			GameManager.start_new_session(PHASE_ID)

	_logica = Level1Logic.new()
	_logica.peca_avaliada.connect(_ao_avaliar_peca)
	_logica.compilador_atualizado.connect(_ao_atualizar_barra)
	_logica.compilacao_falhou.connect(_ao_falhar)

	_colunas_nodes = _colunas_container.get_children()
	_y_alvo = _colunas_container.position.y

	_label_feedback.text = ""
	_atualizar_hud()
	_gerar_nova_peca()
	_criar_botao_pausa()
	_criar_botao_avancar()
	_criar_painel_pausa()


func _process(delta: float) -> void:
	if _pausado or not _jogo_ativo:
		return
	_peca_caindo.position.y += velocidade_queda * delta
	_atualizar_posicao_x()
	if _peca_caindo.position.y >= _y_alvo:
		_pousar_peca()


func _unhandled_input(event: InputEvent) -> void:
	if _pausado or not _jogo_ativo:
		return
	if event.is_action_pressed("ui_left"):
		_mover_lane(-1)
	elif event.is_action_pressed("ui_right"):
		_mover_lane(1)
	elif event.is_action_pressed("ui_down"):
		# Soft/hard drop simplificado (GDD 5.3): manda a peça direto pro chão.
		_peca_caindo.position.y = _y_alvo


func _mover_lane(direcao: int) -> void:
	if _colunas_nodes.is_empty():
		return
	_lane_atual = clampi(_lane_atual + direcao, 0, _colunas_nodes.size() - 1)
	_atualizar_posicao_x()


func _atualizar_posicao_x() -> void:
	if _colunas_nodes.is_empty():
		return
	var coluna: Control = _colunas_nodes[_lane_atual]
	var centro_x: float = coluna.position.x + coluna.size.x / 2.0
	_peca_caindo.position.x = centro_x - _peca_caindo.size.x / 2.0


func _pousar_peca() -> void:
	var tipo_coluna: int = Level1Logic.COLUNAS[_lane_atual]
	_logica.julgar(tipo_coluna, _peca_texto_atual)
	if _jogo_ativo:
		_gerar_nova_peca()


func _gerar_nova_peca() -> void:
	_peca_texto_atual = POOL_VALORES[randi() % POOL_VALORES.size()]
	_peca_texto_label.text = _peca_texto_atual
	_peca_caindo.position.y = 0.0
	_atualizar_posicao_x()


func _ao_avaliar_peca(resultado: Dictionary) -> void:
	_label_feedback.text = resultado["mensagem"]
	if resultado["acertou"]:
		_label_feedback.modulate = Color(0.3, 1.0, 0.3)
	else:
		_label_feedback.modulate = Color(1.0, 0.3, 0.3)
	_atualizar_hud()


func _ao_atualizar_barra(percentual: float) -> void:
	_barra_compilador.value = percentual


func _ao_falhar() -> void:
	_jogo_ativo = false
	# A mensagem de derrota agora aparece grande, centralizada e por cima da
	# explosão (_texto_derrota) — não duplica mais no aviso pequeno do HUD.
	_label_feedback.text = ""
	_texto_derrota.visible = true
	_tocar_explosao_derrota()
	_criar_botao_tentar_novamente()


func _tocar_explosao_derrota() -> void:
	# Barra do compilador chegou a 0% -> toca a animação de explosão (8
	# quadros, GDD seção 10) uma vez só, começando do quadro 0.
	var anim := _explosao_derrota.texture as AnimatedTexture
	if anim != null:
		anim.current_frame = 0
	_explosao_derrota.visible = true


func _atualizar_hud() -> void:
	_label_pontuacao.text = "PONTOS: %d" % _logica.pontuacao


## --- Navegação com o menu principal (ver nota de integração no topo) ---

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


## Painel de pausa (ver nota de integração no topo do arquivo) — some da
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
	# criado depois dele (ex: "TENTAR NOVAMENTE", só existe depois de uma
	# derrota) — sem isso, um botão mais novo desenharia por cima do
	# fundo escurecido e continuaria clicável com o jogo "pausado".
	_painel_pausa.move_to_front()
	_painel_pausa.visible = true


func _fechar_pausa() -> void:
	_pausado = false
	_painel_pausa.visible = false


func _sair_para_menu() -> void:
	if not GameManager.is_phase_completed(PHASE_ID):
		GameManager.abandon_phase()
	get_tree().change_scene_to_file(CENA_MENU)


func _criar_botao_avancar() -> void:
	var botao := _criar_botao("PRÓXIMO NÍVEL →", Color("34a853"))
	botao.anchor_left = 1.0
	botao.anchor_right = 1.0
	botao.anchor_top = 0.0
	botao.anchor_bottom = 0.0
	botao.offset_left = -190
	botao.offset_right = -12
	botao.offset_top = 12
	botao.offset_bottom = 46
	botao.pressed.connect(func():
		GameManager.award_sub_phase_bonus()
		get_tree().change_scene_to_file(CENA_NIVEL_2)
	)


func _criar_botao_tentar_novamente() -> void:
	var botao := _criar_botao("TENTAR NOVAMENTE", Color("34a853"))
	botao.anchor_left = 0.5
	botao.anchor_right = 0.5
	botao.anchor_top = 0.6
	botao.anchor_bottom = 0.6
	botao.offset_left = -110
	botao.offset_right = 110
	botao.offset_top = 0
	botao.offset_bottom = 40
	botao.pressed.connect(func():
		get_tree().reload_current_scene()
	)
