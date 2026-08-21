extends Node2D
## Tutorial da Fase 6 — funciona como uma "fase 0" própria, separada da
## Main.tscn real. É acessada ANTES da fase1 sempre que o jogador entra
## na Fase 6 pelo menu (não é um overlay dentro do jogo real).
##
## Totalmente scriptado, SEM RNG: cada passo spawna manualmente o único
## balão que precisa, na velocidade normal do jogo (mesmo default de
## balao.gd), e nunca existe mais de um balão do tutorial na tela ao
## mesmo tempo.
##
## Avanço de estado: nos passos com balão (BALAO_CERTO, BALAO_ERRADO,
## VIDA_PERDIDA) o botão "Próximo" começa ESCONDIDO e só é liberado
## depois que o jogador realiza a ação correta pelo menos uma vez —
## assim ele não pode pular a etapa clicando sem entender. Depois de
## liberado, o jogador pode continuar "treinando" a mesma ação (outro
## balão igual é spawnado a cada acerto) até decidir clicar Próximo.
##
## Usa sua PRÓPRIA instância de GerenciadorExpressao com uma expressão
## de exemplo simples ("y = 1"), e a expressão REALMENTE avança quando
## o balão certo é coletado pela primeira vez (registrar_coleta_correta),
## para refletir de verdade a mecânica "complete a expressão inteira" —
## não toca na expressão real da fase1, é uma instância isolada.
##
## Ao terminar (Concluir) ou pular, carrega a Main.tscn real da fase 6
## com o config da fase1 (mesmo destino nos dois casos).

const CAMINHO_MAIN := "res://scenes/fase6_sintatico/Main.tscn"
const HUD_SCENE := preload("res://scenes/common/game_hud.tscn")

enum Estado {
	INTRO,         # passo 1: expressão em destaque (maior), sem balão
	TIRO,          # passo 2: jogador precisa disparar uma vez com Espaço
	APONTAR_ALVO,  # passo 3: destaca o caractere atual da expressão
	BALAO_CERTO,   # passo 4: balão "y" cai; jogador precisa deixar cair
	BALAO_ERRADO,  # passo 5: balão errado cai; jogador precisa alvejá-lo
	VIDA_PERDIDA,  # só quando erra o passo 4 (deixou o errado cair)
	FINAL,         # mensagem final, sempre passa por aqui antes de sair
}

# Velocidade normal do jogo real: o mesmo valor default de balao.gd. A
# queda mais lenta equilibra o controle por teclado em relação ao mouse.
const VELOCIDADE_NORMAL := 65.0
const COR_BALAO_TUTORIAL := Color(0.55, 0.6, 0.75)
const SIMBOLO_CERTO := "y"
const SIMBOLO_ERRADO := "@"
const EXPRESSAO_EXEMPLO: Array[String] = ["y", "=", "1"]

const TEXTOS := {
	Estado.INTRO: "Bem-vindo! Sua missão: montar a expressão no topo, na ordem certa, caractere por caractere.",
	Estado.TIRO: "Este é o seu canhão. Mova-o com mouse, A/D ou setas e atire com Espaço ou M1.",
	Estado.APONTAR_ALVO: "O caractere em destaque na expressão é o que você precisa capturar agora.",
	Estado.BALAO_CERTO: "Quando o balão CERTO cair, não atire nele: deixe-o chegar ao chão para coletar.",
	Estado.BALAO_ERRADO: "Balões ERRADOS devem ser atingidos! Alinhe o canhão e atire com Espaço ou M1.",
	Estado.VIDA_PERDIDA: "Deixar cair um balão errado custa uma vida! Alinhe o canhão e use Espaço ou M1.",
	Estado.FINAL: "Cuidado: deixar cair o errado custa uma vida. A cor do balão é só enfeite. Boa sorte!",
}

@onready var label_expressao_exemplo: RichTextLabel = $UI/LabelExpressaoExemplo
@onready var label_vida_perdida: Label = $UI/LabelVidaPerdida
@onready var label_texto: Label = $UI/Caixa/VBoxCaixa/LabelTexto
@onready var label_dica_acao: Label = $UI/Caixa/VBoxCaixa/LabelDicaAcao
@onready var botao_proximo: Button = $UI/Caixa/VBoxCaixa/HBoxBotoes/BotaoProximo
@onready var botao_pular: Button = $UI/BotaoPular
@onready var area_baloes: Node2D = $AreaBaloes
@onready var canhao: CanhaoFase6 = $Canhao

var hud
var pausado := false
var _estado: int = Estado.INTRO
var _balao_atual: Balao = null
var _ja_acertou_no_passo_atual := false
var _cena_balao: PackedScene = preload("res://scenes/fase6_sintatico/balao.tscn")
var _gerenciador_exemplo := GerenciadorExpressao.new()

func _ready() -> void:
	Fase6Estado.iniciar_execucao()
	_criar_hud()
	add_child(_gerenciador_exemplo)
	_gerenciador_exemplo.definir_expressao(EXPRESSAO_EXEMPLO)

	botao_proximo.pressed.connect(_on_botao_proximo_pressed)
	botao_pular.pressed.connect(_on_botao_pular_pressed)
	canhao.disparou.connect(_on_canhao_disparou)
	if label_vida_perdida:
		label_vida_perdida.hide()

	_ir_para(Estado.INTRO)

## Enter avança qualquer passo já concluído. Isso evita depender do mouse
## para clicar no botão e mantém Espaço livre exclusivamente para disparar.
func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.is_action_pressed(&"pause"):
		if pausado:
			_retomar()
		else:
			_pausar()
		get_viewport().set_input_as_handled()
		return
	if pausado:
		return
	if event.keycode not in [KEY_ENTER, KEY_KP_ENTER]:
		return
	if botao_proximo.visible and not botao_proximo.disabled:
		get_viewport().set_input_as_handled()
		_on_botao_proximo_pressed()

## --- Transição central de estado ---
## IMPORTANTE: esta função pode ser chamada de dentro de um callback de
## física do próprio balão (estourado/chegou_ao_chao, que por sua vez
## vêm de chao.gd::_on_area_entered, disparado durante o flush de
## queries de física do Godot). Trocar de estado ali dentro implica
## instanciar/mexer em CollisionShape de um novo balão NO MESMO FRAME,
## o que o motor de física proíbe ("Can't change this state while
## flushing queries"). Por isso os callers que vêm de sinais de balão
## chamam esta função via call_deferred (ver _on_balao_tutorial_caiu /
## _on_balao_tutorial_estourado).
func _ir_para(novo_estado: int) -> void:
	_limpar_baloes()
	canhao.limpar_projeteis()
	if label_vida_perdida:
		label_vida_perdida.hide()

	_estado = novo_estado
	canhao.definir_ativo(_estado in [Estado.TIRO, Estado.BALAO_CERTO, Estado.BALAO_ERRADO, Estado.VIDA_PERDIDA])
	_ja_acertou_no_passo_atual = false
	label_texto.text = TEXTOS[_estado]

	match _estado:
		Estado.INTRO:
			_mostrar_expressao_exemplo(true)
			_liberar_proximo(true)

		Estado.TIRO:
			_mostrar_expressao_exemplo(false)
			label_dica_acao.text = "Pressione Espaço ou M1 (botão esquerdo do mouse) para realizar um tiro."
			_liberar_proximo(false)

		Estado.APONTAR_ALVO:
			_mostrar_expressao_exemplo(false)
			_liberar_proximo(true)

		Estado.BALAO_CERTO:
			_mostrar_expressao_exemplo(false)
			label_dica_acao.text = "Deixe o balão cair até o chão..."
			_liberar_proximo(false)
			_spawnar_balao(SIMBOLO_CERTO)

		Estado.BALAO_ERRADO:
			_mostrar_expressao_exemplo(false)
			label_dica_acao.text = "Alinhe o canhão para estourar o balão!"
			_liberar_proximo(false)
			_spawnar_balao(SIMBOLO_ERRADO)

		Estado.VIDA_PERDIDA:
			_mostrar_expressao_exemplo(false)
			_mostrar_enfase_vida_perdida()
			_liberar_proximo(false)
			# Pequena pausa visual antes de spawnar outro balão errado, para
			# dar tempo do jogador ler a mensagem e ver a ênfase de vida.
			await get_tree().create_timer(1.1).timeout
			while pausado:
				await get_tree().process_frame
			if _estado != Estado.VIDA_PERDIDA:
				return # o jogador avançou/pulou o tutorial nesse meio tempo
			label_dica_acao.text = "Alinhe o canhão para estourar o balão!"
			_spawnar_balao(SIMBOLO_ERRADO)

		Estado.FINAL:
			_mostrar_expressao_exemplo(false)
			_liberar_proximo(true)
			botao_proximo.text = "Concluir (Enter)"

func _liberar_proximo(liberado: bool) -> void:
	label_dica_acao.visible = not liberado
	botao_proximo.visible = liberado
	if liberado and _estado != Estado.FINAL:
		botao_proximo.text = "Próximo (Enter)"

## --- Expressão de exemplo (reaproveita o BBCode do GerenciadorExpressao) ---
func _mostrar_expressao_exemplo(em_destaque_grande: bool) -> void:
	if not label_expressao_exemplo:
		return
	var tamanho_base := 22
	var tamanho_atual := 44 if em_destaque_grande else 30
	label_expressao_exemplo.bbcode_enabled = true
	label_expressao_exemplo.text = _gerenciador_exemplo.expressao_como_bbcode(
		Color(0.2, 0.7, 0.3),
		Color(1, 0.85, 0.2), # caractere atual em amarelo, tipo "circulado"
		Color(0.6, 0.6, 0.6),
		tamanho_base,
		tamanho_atual
	)

## --- Spawn único e controlado (nunca mais de um balão do tutorial vivo) ---
func _spawnar_balao(simbolo: String) -> void:
	_limpar_baloes()
	_balao_atual = _cena_balao.instantiate()
	_balao_atual.simbolo = simbolo
	_balao_atual.velocidade_queda = VELOCIDADE_NORMAL
	_balao_atual.vidas = 1 # garante um só impacto, mesmo que balao.gd suporte fortificados
	_balao_atual.position = Vector2(300, -40)
	area_baloes.add_child(_balao_atual)
	_balao_atual.definir_cor(COR_BALAO_TUTORIAL)

	_balao_atual.estourado.connect(_on_balao_tutorial_estourado)
	_balao_atual.chegou_ao_chao.connect(_on_balao_tutorial_caiu)

## --- Reações do balão CERTO (passo 3) e ERRADO (passo 4 / VIDA_PERDIDA) ---
## Chamado a partir do sinal `estourado` do Balao após o impacto do projétil.
## Usamos call_deferred nos casos que re-spawnam balão por consistência com
## o handler de queda, que acontece durante o passo de física.
func _on_balao_tutorial_estourado(_simbolo: String) -> void:
	if _estado == Estado.BALAO_CERTO:
		# Estourou o certo sem querer: reforça a mensagem e spawna outro igual.
		# (Isso pode acontecer mesmo depois de já ter acertado uma vez, se o
		# jogador estiver treinando e errar dessa vez — não desfaz o Próximo
		# já liberado, só reforça a instrução.)
		label_dica_acao.text = "Esse é o caractere esperado — deixe cair, não estoure! Tente de novo."
		call_deferred("_spawnar_balao", SIMBOLO_CERTO)
	elif _estado == Estado.BALAO_ERRADO or _estado == Estado.VIDA_PERDIDA:
		_registrar_acerto_e_treinar(SIMBOLO_ERRADO)

## --- Reações de balão chegando ao chão (passos 3, 4 e VIDA_PERDIDA) ---
## Chamado a partir do sinal `chegou_ao_chao`, emitido de dentro de
## chao.gd::_on_area_entered (callback de física, durante flush de
## queries). Trocar de estado aqui precisa ser adiado com call_deferred,
## senão o Godot lança "Can't change this state while flushing queries"
## ao tentarmos instanciar/configurar o próximo balão no mesmo frame.
func _on_balao_tutorial_caiu(simbolo: String, _pos: Vector2) -> void:
	if _estado == Estado.BALAO_CERTO:
		# Avança a expressão de verdade (mesma mecânica do jogo real) só na
		# PRIMEIRA vez que acerta neste passo — repetições de treino não
		# devem avançar o índice da expressão de exemplo de novo.
		if not _ja_acertou_no_passo_atual:
			_gerenciador_exemplo.registrar_coleta_correta(simbolo)
		_registrar_acerto_e_treinar(SIMBOLO_CERTO)
	elif _estado == Estado.BALAO_ERRADO:
		call_deferred("_ir_para", Estado.VIDA_PERDIDA)
	elif _estado == Estado.VIDA_PERDIDA:
		# Deixou cair de novo dentro da tela de vida perdida: já mostrou a
		# ênfase uma vez, não repete a penalidade visual — só spawna outro
		# balão errado para ele poder tentar de novo.
		call_deferred("_spawnar_balao", SIMBOLO_ERRADO)

## Feedback de sucesso comum aos passos com balão: mostra a mensagem de
## "muito bem", libera o Próximo (se ainda não estava liberado) e spawna
## outro balão do mesmo tipo para o jogador poder treinar de novo à
## vontade, sem forçar avanço de estado — quem decide é o Próximo.
func _registrar_acerto_e_treinar(simbolo_para_treino: String) -> void:
	_ja_acertou_no_passo_atual = true
	label_dica_acao.text = "Muito bem! Você pode ir para o próximo passo — ou treine de novo."
	_liberar_proximo(true)
	call_deferred("_spawnar_balao", simbolo_para_treino)

func _on_canhao_disparou() -> void:
	if _estado != Estado.TIRO or _ja_acertou_no_passo_atual:
		return
	_ja_acertou_no_passo_atual = true
	label_dica_acao.text = "Muito bem! Cada toque no Espaço ou M1 dispara um projétil."
	_liberar_proximo(true)

## --- Ênfase visual de vida perdida ---
func _mostrar_enfase_vida_perdida() -> void:
	if not label_vida_perdida:
		return
	label_vida_perdida.text = "-1 VIDA"
	label_vida_perdida.show()
	label_vida_perdida.modulate = Color(1, 0.3, 0.3, 1)
	label_vida_perdida.scale = Vector2(0.6, 0.6)
	var tween := create_tween()
	tween.tween_property(label_vida_perdida, "scale", Vector2(1.3, 1.3), 0.15)
	tween.tween_property(label_vida_perdida, "scale", Vector2(1.0, 1.0), 0.15)
	tween.tween_interval(0.6)
	tween.tween_property(label_vida_perdida, "modulate:a", 0.0, 0.4)

func _limpar_baloes() -> void:
	if _balao_atual and is_instance_valid(_balao_atual):
		_balao_atual.queue_free()
	_balao_atual = null
	for filho in area_baloes.get_children():
		if filho is Balao and is_instance_valid(filho):
			filho.queue_free()

## --- Navegação via botão Próximo ---
## Nos passos INTRO/APONTAR_ALVO/FINAL o botão já vem liberado. Nos
## passos com balão (BALAO_CERTO/BALAO_ERRADO) e em VIDA_PERDIDA, o
## botão só aparece depois que o jogador realiza a ação correta pelo
## menos uma vez (ver _registrar_acerto_e_treinar) — até lá não é
## possível pular a etapa clicando em Próximo.
func _on_botao_proximo_pressed() -> void:
	match _estado:
		Estado.INTRO:
			_ir_para(Estado.TIRO)
		Estado.TIRO:
			_ir_para(Estado.APONTAR_ALVO)
		Estado.APONTAR_ALVO:
			_ir_para(Estado.BALAO_CERTO)
		Estado.BALAO_CERTO:
			_ir_para(Estado.BALAO_ERRADO)
		Estado.BALAO_ERRADO:
			_ir_para(Estado.FINAL)
		Estado.VIDA_PERDIDA:
			_ir_para(Estado.FINAL)
		Estado.FINAL:
			_ir_para_fase1()

func _on_botao_pular_pressed() -> void:
	_ir_para_fase1()

func _ir_para_fase1() -> void:
	_limpar_baloes()
	get_tree().change_scene_to_file(CAMINHO_MAIN)

func _criar_hud() -> void:
	hud = HUD_SCENE.instantiate()
	add_child(hud)
	hud.configure_phase("FASE 6 - TUTORIAL", "APRENDA A IDENTIFICAR E ELIMINAR SÍMBOLOS", false)
	hud.hide_scanner_interface()
	hud.pause_requested.connect(_pausar)
	hud.resume_requested.connect(_retomar)
	hud.menu_confirmed.connect(_voltar_ao_menu)

func _pausar() -> void:
	if pausado:
		return
	pausado = true
	_definir_simulacao_ativa(false)
	hud.show_pause()

func _retomar() -> void:
	if not pausado:
		return
	pausado = false
	_definir_simulacao_ativa(true)
	# Esc também deve fechar visualmente o diálogo, não apenas reativar a
	# simulação por trás dele.
	hud.hide_dialog()

func _definir_simulacao_ativa(ativa: bool) -> void:
	canhao.set_physics_process(ativa)
	canhao.set_process_input(ativa)
	canhao.set_process_unhandled_input(ativa)
	if _balao_atual and is_instance_valid(_balao_atual):
		_balao_atual.set_process(ativa)
	for projetil in get_tree().get_nodes_in_group("projeteis_fase6"):
		if is_instance_valid(projetil):
			projetil.set_physics_process(ativa)

func _voltar_ao_menu() -> void:
	Fase6Estado.encerrar_execucao()
	GameManager.abandon_phase()
	get_tree().change_scene_to_file("res://scenes/menu/menu.tscn")
