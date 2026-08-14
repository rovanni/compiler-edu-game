extends Node2D
## Fase 6 - Erro Sintático ("Estoura Balão").
## Regras (conforme planejamento):
## 1. Existe uma expressão-objetivo (ex: x = 20 + 5), quebrada em tokens
##    (números com 2+ dígitos são quebrados em dígitos individuais).
## 2. Balões caem com símbolos aleatórios.
## 3. Se o balão é o próximo token da expressão -> jogador deve deixar cair.
## 4. Se o balão NÃO é a vez dele (lixo ou fora de ordem) -> jogador deve estourar (clique).
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

const PHASE_ID := 6

## Trava geral: quando true, nenhum evento de balão (estouro/queda) altera
## mais vidas, progresso ou spawns. Evita processar eventos após o fim de
## jogo/vitória (o GameManager também tem sua própria trava interna, esta
## é a trava local desta cena).
var jogo_acabou := false

func _ready() -> void:
	var config_pendente := Fase6Estado.consumir_config_pendente()
	if config_pendente != null:
		config = config_pendente

	if config == null:
		push_warning("Main.tscn sem ConfigFase atribuído — usando valores padrão.")
		config = ConfigFase.new()

	jogo_acabou = false

	if not GameManager.game_over.is_connected(_on_game_manager_game_over):
		GameManager.game_over.connect(_on_game_manager_game_over)
	if not GameManager.lives_changed.is_connected(_on_lives_changed):
		GameManager.lives_changed.connect(_on_lives_changed)

	GameManager.begin_phase(PHASE_ID)

	gerenciador.definir_expressao(config.expressao_objetivo)
	gerenciador.token_correto_coletado.connect(_on_token_correto_coletado)
	gerenciador.expressao_completa.connect(_on_expressao_completa)

	spawner.aplicar_config(config)
	spawner.iniciar(gerenciador)
	spawner.balao_criado.connect(_on_balao_criado)

	if painel_fim:
		painel_fim.hide()
	if botao_reiniciar:
		botao_reiniciar.pressed.connect(_on_botao_reiniciar_pressed)
	if botao_proxima_fase:
		botao_proxima_fase.pressed.connect(_on_botao_proxima_fase_pressed)
		botao_proxima_fase.hide() # só aparece ao vencer, e só se houver próxima fase
	if label_fase:
		label_fase.text = config.rotulo_fase

	_atualizar_ui()

func _on_balao_criado(balao: Balao) -> void:
	balao.add_to_group("baloes")
	balao.estourado.connect(_on_balao_estourado)
	balao.chegou_ao_chao.connect(_on_balao_chegou_ao_chao)

func _on_balao_estourado(simbolo: String) -> void:
	if jogo_acabou:
		return
	if gerenciador.eh_a_vez_dele(simbolo):
		# Estourou o balão certo -> erro. Devia ter deixado cair.
		_registrar_erro("Ops! '%s' fazia parte da expressão. Devia deixar cair." % simbolo)
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
	spawner.pausar(true)
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
	_mostrar_tela_fim("Fase concluída!", false)

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
	_remover_baloes_vivos()
	_mostrar_mensagem("Fim de jogo! Tente novamente.")
	_mostrar_tela_fim("Fim de jogo!", true)

## Remove imediatamente todos os balões que ainda estão caindo, para que
## nenhum deles gere mais eventos (estouro/queda) após o fim de jogo.
func _remover_baloes_vivos() -> void:
	for balao in get_tree().get_nodes_in_group("baloes"):
		if is_instance_valid(balao):
			balao.queue_free()

func _mostrar_tela_fim(titulo: String, derrota: bool) -> void:
	if not painel_fim:
		return
	if label_fim_titulo:
		label_fim_titulo.text = titulo
	if botao_proxima_fase:
		# Só mostra "Próxima fase" se venceu (não derrota) e existe uma próxima.
		botao_proxima_fase.visible = (not derrota) and config.proxima_fase_config_path != ""
	painel_fim.show()

func _on_botao_reiniciar_pressed() -> void:
	# Reinicia a MESMA sub-fase atual (o config já atribuído na cena
	# continua o mesmo; Fase6Estado não é tocado aqui).
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
