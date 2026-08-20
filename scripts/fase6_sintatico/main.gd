extends Node2D
## Fase 6 - Erro Sintático ("Estoura Balão").
## Regras (conforme planejamento):
## 1. Existe uma expressão-objetivo (ex: x = 20 + 5), quebrada em tokens
##    (números com 2+ dígitos são quebrados em dígitos individuais).
## 2. Balões caem com símbolos aleatórios.
## 3. Se o balão é o próximo token da expressão -> jogador deve deixar cair.
## 4. Se o balão NÃO é a vez dele (lixo ou fora de ordem) -> jogador deve
##    alinhar o canhão e estourá-lo com projéteis.
## 5. Erros que tiram vida:
##    a) deixar cair um balão que não pertence à expressão
##    b) deixar cair um balão que pertence à expressão mas não é a vez dele
##    c) estourar um balão que era o próximo token correto
##
## Esta é a ÚNICA cena da fase 6 (Main.tscn). As 3 sub-fases progressivas
## (dificuldade crescente) não duplicam a UI: cada uma é só um arquivo de
## dados ConfigFase (.tres) com expressão/paleta/dificuldade diferentes,
## atribuído ao @export var config abaixo.
##
## Pontos/vidas/combo são controlados pelo autoload GameManager (o mesmo
## sistema usado pelas fases 1/2/4), não por um contador próprio.
## GameManager.complete_phase(6, ...) só é chamado ao vencer a ÚLTIMA
## sub-fase (config.proxima_fase_config_path == ""); as sub-fases 1 e 2
## dão bônus de pontos ao avançar mas não marcam a Fase 6 como concluída
## no menu — isso só acontece ao terminar a fase3.


@export var config: ConfigFase

const HUD_SCENE := preload("res://scenes/common/game_hud.tscn")

@onready var gerenciador: GerenciadorExpressao = $GerenciadorExpressao
@onready var spawner: SpawnerBaloes = $SpawnerBaloes
@onready var label_expressao: RichTextLabel = $UI/LabelExpressao
@onready var label_vidas: Label = $UI/LabelVidas
@onready var label_progresso: Label = $UI/LabelProgresso
@onready var label_fase: Label = $UI/LabelFase
@onready var label_mensagem: Label = $UI/LabelMensagem
@onready var painel_fim: Control = $UI/PainelFimDeJogo
@onready var label_fim_titulo: Label = $UI/PainelFimDeJogo/CentroFim/LabelFimTitulo
@onready var botao_reiniciar: Button = $UI/PainelFimDeJogo/CentroFim/BotaoReiniciar
@onready var botao_proxima_fase: Button = $UI/PainelFimDeJogo/CentroFim/BotaoProximaFase
@onready var canhao: CanhaoFase6 = $Canhao

var hud


# ==========================================
# VARIÁVEIS DE DEBUG (PODE APAGAR DEPOIS) e apagar a função _input  na linha 217
# Substitua pelo caminho real dos arquivos .tres no seu projeto
const DEBUG_PATH_FASE_1 = "res://resources/fase6_sintatico/fase1.tres"
const DEBUG_PATH_FASE_2 = "res://resources/fase6_sintatico/fase2.tres"
const DEBUG_PATH_FASE_3 = "res://resources/fase6_sintatico/fase3.tres"
# ==========================================


const PHASE_ID := 6

## Trava geral: quando true, nenhum evento de balão (estouro/queda) altera
## mais vidas, progresso ou spawns. Evita processar eventos após o fim de
## jogo/vitória (o GameManager também tem sua própria trava interna, esta
## é a trava local desta cena).
var jogo_acabou := false
var pausado := false
var fase_concluida := false

func _ready() -> void:
	var config_pendente := Fase6Estado.consumir_config_pendente()
	if config_pendente != null:
		config = config_pendente

	if config == null:
		push_warning("Main.tscn sem ConfigFase atribuído — usando valores padrão.")
		config = ConfigFase.new()

	jogo_acabou = false
	pausado = false
	fase_concluida = false

	if not GameManager.game_over.is_connected(_on_game_manager_game_over):
		GameManager.game_over.connect(_on_game_manager_game_over)
	if not GameManager.lives_changed.is_connected(_on_lives_changed):
		GameManager.lives_changed.connect(_on_lives_changed)

	GameManager.begin_phase(PHASE_ID)
	_criar_hud()

	gerenciador.definir_expressao(config.expressao_objetivo)
	gerenciador.token_correto_coletado.connect(_on_token_correto_coletado)
	gerenciador.expressao_completa.connect(_on_expressao_completa)

	spawner.aplicar_config(config)
	spawner.iniciar(gerenciador)
	spawner.balao_criado.connect(_on_balao_criado)

	if painel_fim:
		painel_fim.hide() # substituído pelo diálogo visual do GameHud comum
	if label_fase:
		label_fase.text = config.rotulo_fase

	_atualizar_ui()

func _on_balao_criado(balao: Balao) -> void:
	balao.add_to_group("baloes")
	balao.estourado.connect(_on_balao_estourado)
	balao.chegou_ao_chao.connect(_on_balao_chegou_ao_chao)
	if pausado:
		balao.set_process(false)

func _on_balao_estourado(simbolo: String) -> void:
	if jogo_acabou:
		return
	if gerenciador.eh_a_vez_dele(simbolo):
		# Estourou o balão certo -> NÃO perde vida mais.
		# O spawner já entende que o balão foi destruído e enviará outro em breve.
		# Vamos apenas exibir um aviso inofensivo ao jogador.
		_mostrar_mensagem("Cuidado! Você estourou o '%s'. Espere o próximo!" % simbolo)
		_atualizar_ui()
	else:
		# Estourou um símbolo que não é a vez dele (lixo ou fora de ordem) -> correto.
		GameManager.register_correct_action()
		_mostrar_mensagem("Símbolo '%s' eliminado corretamente!" % simbolo)
		_atualizar_ui()

func _on_balao_chegou_ao_chao(simbolo: String, posicao: Vector2) -> void:
	if jogo_acabou:
		return
	if gerenciador.eh_a_vez_dele(simbolo):
		gerenciador.registrar_coleta_correta(simbolo)
		GameManager.register_correct_action()
		EfeitoEstouro.tocar_em(self, posicao)
		_mostrar_mensagem("Token '%s' coletado!" % simbolo)
		_atualizar_ui()
	elif gerenciador.pertence_a_expressao(simbolo):
		_registrar_erro("'%s' pertence à expressão, mas não era a vez dele." % simbolo)
	else:
		_registrar_erro("'%s' não pertence à expressão e não foi eliminado." % simbolo)

func _on_token_correto_coletado(_simbolo: String, _indice: int) -> void:
	_atualizar_ui()

func _on_expressao_completa() -> void:
	if jogo_acabou:
		return
	jogo_acabou = true
	fase_concluida = true
	spawner.pausar(true)
	canhao.definir_ativo(false)
	_remover_baloes_vivos()

	var eh_ultima_sub_fase := config.proxima_fase_config_path == ""
	if eh_ultima_sub_fase:
		# Só a última sub-fase (fase3) marca a Fase 6 como concluída no
		# GameManager — isso ativa o "✓" no card do menu e dá o bônus de
		# fase completa (+ bônus "sem erros" se aplicável).
		GameManager.complete_phase(PHASE_ID, true)
	else:
		# Sub-fases intermediárias (1 e 2): dão o mesmo bônus de pontos que
		# uma fase completa, mas SEM marcar completed_phases (o carimbo
		# "✓ Fase 6 concluída" só deve aparecer ao vencer a fase3).
		GameManager.award_sub_phase_bonus()

	_mostrar_mensagem("Expressão completa! Fase concluída.")
	var tem_proxima := config.proxima_fase_config_path != ""
	hud.show_completion(
		"FASE 6 CONCLUÍDA!" if not tem_proxima else "SUB-FASE CONCLUÍDA!",
		"Você preservou os tokens esperados e eliminou os símbolos incorretos.",
		tem_proxima
	)

func _registrar_erro(motivo: String) -> void:
	if jogo_acabou:
		return
	GameManager.register_mistake(motivo)
	_mostrar_mensagem(motivo)
	_atualizar_ui()
	# GameManager.game_over já cobre lives == 0 via sinal (_on_game_manager_game_over).

func _on_lives_changed(_current: int, _maximum: int) -> void:
	_atualizar_ui()

func _on_game_manager_game_over(phase_id: int) -> void:
	if phase_id != PHASE_ID or jogo_acabou:
		return
	jogo_acabou = true
	spawner.pausar(true)
	canhao.definir_ativo(false)
	_remover_baloes_vivos()
	_mostrar_mensagem("Fim de jogo! Tente novamente.")
	hud.show_game_over("Proteja o próximo token da expressão e atire apenas nos balões incorretos. Os pontos provisórios desta fase serão removidos.")

## Remove imediatamente todos os balões que ainda estão caindo, para que
## nenhum deles gere mais eventos (estouro/queda) após o fim de jogo.
func _remover_baloes_vivos() -> void:
	for balao in get_tree().get_nodes_in_group("baloes"):
		if is_instance_valid(balao):
			balao.queue_free()

func _on_botao_reiniciar_pressed() -> void:
	# Reinicia a MESMA sub-fase atual (o config já atribuído na cena
	# continua o mesmo; Fase6Estado não é tocado aqui).
	GameManager.rollback_to(0)
	GameManager.reset_lives()
	Fase6Estado.definir_proxima_config(config)
	get_tree().reload_current_scene()

func _on_botao_proxima_fase_pressed() -> void:
	if config.proxima_fase_config_path == "":
		return
	var proxima_config: ConfigFase = load(config.proxima_fase_config_path)
	if proxima_config == null:
		push_error("Não foi possível carregar ConfigFase em: " + config.proxima_fase_config_path)
		return
	Fase6Estado.definir_proxima_config(proxima_config)
	get_tree().reload_current_scene()

func _atualizar_ui() -> void:
	label_expressao.text = "[b]Expressão:[/b] " + gerenciador.expressao_como_bbcode(Color(0.2, 0.7, 0.3), Color(0.05, 0.05, 0.05), Color(0.6, 0.6, 0.6), 22, 34)
	label_vidas.text = "Vidas: %d" % GameManager.lives
	label_progresso.text = "Progresso: %d/%d" % [gerenciador.indice_atual, gerenciador.expressao.size()]

func _mostrar_mensagem(texto: String) -> void:
	if label_mensagem:
		label_mensagem.text = texto
	if hud:
		hud.set_feedback(texto)

func _criar_hud() -> void:
	hud = HUD_SCENE.instantiate()
	add_child(hud)
	hud.configure_phase("FASE 6 - ANÁLISE SINTÁTICA", config.rotulo_fase, false)
	hud.hide_scanner_interface()
	hud.pause_requested.connect(_pausar)
	hud.resume_requested.connect(_retomar)
	hud.menu_confirmed.connect(_voltar_ao_menu)
	hud.retry_requested.connect(_on_botao_reiniciar_pressed)
	hud.next_requested.connect(_on_botao_proxima_fase_pressed)
	hud.replay_requested.connect(_on_botao_reiniciar_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"pause"):
		return
	if pausado:
		_retomar()
	elif not jogo_acabou:
		_pausar()
	get_viewport().set_input_as_handled()

func _pausar() -> void:
	if pausado or jogo_acabou:
		return
	pausado = true
	_definir_simulacao_ativa(false)
	hud.show_pause()

func _retomar() -> void:
	if not pausado:
		return
	pausado = false
	_definir_simulacao_ativa(true)
	# Quando a retomada vem do Esc, não passa pelo botão "CONTINUAR" do
	# GameHud; portanto o diálogo precisa ser fechado explicitamente aqui.
	hud.hide_dialog()

func _definir_simulacao_ativa(ativa: bool) -> void:
	spawner.pausar(not ativa)
	canhao.set_physics_process(ativa)
	canhao.set_process_input(ativa)
	canhao.set_process_unhandled_input(ativa)
	for balao in get_tree().get_nodes_in_group("baloes"):
		if is_instance_valid(balao):
			balao.set_process(ativa)
	for projetil in get_tree().get_nodes_in_group("projeteis_fase6"):
		if is_instance_valid(projetil):
			projetil.set_physics_process(ativa)

func _voltar_ao_menu() -> void:
	if not fase_concluida:
		GameManager.abandon_phase()
	get_tree().change_scene_to_file("res://scenes/menu/menu.tscn")

# ==========================================
# FUNÇÃO DE DEBUG (PODE APAGAR DEPOIS)
# ==========================================
func _input(event: InputEvent) -> void:
	# Trava de segurança: só funciona no editor, nunca na versão final compilada do jogo
	if not OS.is_debug_build():
		return

	# Verifica se foi uma tecla pressionada e não um clique do mouse
	if event is InputEventKey and event.pressed:
		var caminho_config := ""

		# Verifica qual número foi pressionado no teclado (acima das letras)
		if event.keycode == KEY_1:
			caminho_config = DEBUG_PATH_FASE_1
		elif event.keycode == KEY_2:
			caminho_config = DEBUG_PATH_FASE_2
		elif event.keycode == KEY_3:
			caminho_config = DEBUG_PATH_FASE_3

		# Se um caminho válido foi selecionado, força a troca de fase
		if caminho_config != "":
			var proxima_config: ConfigFase = load(caminho_config)
			
			if proxima_config != null:
				print("--- DEBUG ---")
				print("Pulando para: ", caminho_config)
				# Utiliza o mesmo sistema que o botão "Próxima fase" usa para carregar a configuração
				Fase6Estado.definir_proxima_config(proxima_config)
				get_tree().reload_current_scene()
			else:
				push_error("DEBUG: Falha ao carregar configuração. Verifique se o caminho está correto: " + caminho_config)
# ==========================================
