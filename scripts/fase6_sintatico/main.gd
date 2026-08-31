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
## Estourar o próximo token correto não tira vida, mas desperdiça a chance
## de coletá-lo e obriga o jogador a aguardar outro balão igual.
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
@export_range(0.0, 600.0, 5.0) var tempo_retorno_inatividade: float = 120.0

const HUD_SCENE := preload("res://scenes/common/game_hud.tscn")
const CAMINHO_TUTORIAL := "res://scenes/fase6_sintatico/Tutorial.tscn"

@onready var gerenciador: GerenciadorExpressao = $GerenciadorExpressao
@onready var spawner: SpawnerBaloes = $SpawnerBaloes
@onready var label_expressao: RichTextLabel = $UI/PainelObjetivo/VBox/LabelExpressao
@onready var label_progresso: Label = $UI/PainelObjetivo/VBox/LabelProgresso
@onready var label_mensagem: Label = $UI/LabelMensagem
@onready var canhao: CanhaoFase6 = $Canhao
@onready var overlay_mecanica: Control = $UI/OverlayMecanica
@onready var overlay_escurecer: ColorRect = $UI/OverlayMecanica/Escurecer
@onready var alerta_exclamacoes: Label = $UI/OverlayMecanica/AlertaExclamacoes
@onready var alerta_fundo: Label = $UI/OverlayMecanica/AlertaFundo
@onready var overlay_painel: ColorRect = $UI/OverlayMecanica/Painel
@onready var overlay_titulo: Label = $UI/OverlayMecanica/Painel/OverlayTitulo
@onready var overlay_texto: Label = $UI/OverlayMecanica/Painel/OverlayTexto
@onready var overlay_botao: Button = $UI/OverlayMecanica/Painel/OverlayBotao

const PHASE_ID := 6
const COR_SUCESSO := Color("72e6a1")
const COR_ALERTA := Color("ffc43d")
const COR_ERRO := Color("ff6b6b")
const COR_NEUTRA := Color("e8f2fa")

var hud

## Trava geral: quando true, nenhum evento de balão (estouro/queda) altera
## mais vidas, progresso ou spawns. Evita processar eventos após o fim de
## jogo/vitória (o GameManager também tem sua própria trava interna, esta
## é a trava local desta cena).
var jogo_acabou := false
var pausado := false
var fase_concluida := false
var tutorial_mecanica_ativo := false
var _alvo_destaque: Balao = null
var _balao_fortificado_pendente: Balao = null
var _spawnar_chefe_ao_fechar := false
var _tween_destaque: Tween = null
var _tempo_sem_entrada := 0.0
var _retorno_inatividade_em_andamento := false

func _ready() -> void:
	var config_pendente := Fase6Estado.consumir_config_pendente()
	if config_pendente != null:
		config = config_pendente

	if config == null:
		push_warning("Main.tscn sem ConfigFase atribuído — usando valores padrão.")
		config = ConfigFase.new()
	if not Fase6Estado.execucao_ativa:
		Fase6Estado.iniciar_execucao()

	jogo_acabou = false
	pausado = false
	fase_concluida = false

	if not GameManager.game_over.is_connected(_on_game_manager_game_over):
		GameManager.game_over.connect(_on_game_manager_game_over)

	GameManager.begin_phase(PHASE_ID)
	_criar_hud()

	gerenciador.definir_expressao(config.expressao_objetivo)
	gerenciador.token_correto_coletado.connect(_on_token_correto_coletado)
	gerenciador.expressao_completa.connect(_on_expressao_completa)

	spawner.aplicar_config(config)
	spawner.balao_criado.connect(_on_balao_criado)
	spawner.chefe_pronto_para_spawn.connect(_on_chefe_pronto_para_spawn)
	spawner.iniciar(gerenciador)
	overlay_botao.pressed.connect(_on_overlay_mecanica_confirmado)
	overlay_mecanica.hide()

	_atualizar_ui()

func _on_balao_criado(balao: Balao) -> void:
	balao.add_to_group("baloes")
	balao.estourado.connect(_on_balao_estourado)
	balao.chegou_ao_chao.connect(_on_balao_chegou_ao_chao.bind(balao))
	if pausado:
		balao.set_process(false)
	if (
		balao.vidas > 1
		and not balao.eh_gigante
		and not Fase6Estado.tutorial_fortificado_visto
		and not is_instance_valid(_balao_fortificado_pendente)
	):
		# O aviso não abre enquanto o balão ainda está parcialmente fora da
		# tela. _process aguarda ele alcançar cerca de 1/4 da altura visível.
		_balao_fortificado_pendente = balao

func _on_balao_estourado(simbolo: String) -> void:
	if jogo_acabou:
		return
	if gerenciador.eh_a_vez_dele(simbolo):
		# Estourou o balão certo -> NÃO perde vida mais.
		# O spawner já entende que o balão foi destruído e enviará outro em breve.
		# Vamos apenas exibir um aviso inofensivo ao jogador.
		_mostrar_mensagem("Proteja o símbolo '%s': espere o próximo balão!" % simbolo, COR_ALERTA)
		_atualizar_ui()
	else:
		# Estourou um símbolo que não é a vez dele (lixo ou fora de ordem) -> correto.
		GameManager.register_correct_action()
		_mostrar_mensagem("Boa defesa! Símbolo '%s' eliminado." % simbolo, COR_SUCESSO)
		_atualizar_ui()

func _on_balao_chegou_ao_chao(simbolo: String, posicao: Vector2, balao: Balao) -> void:
	if jogo_acabou:
		return
	if balao.eh_gigante:
		_mostrar_mensagem("O balão gigante atravessou a defesa!", COR_ERRO)
		GameManager.register_fatal_mistake("O balão gigante chegou ao chão.")
		return
	if gerenciador.eh_a_vez_dele(simbolo):
		# Pontua antes de registrar a coleta porque o último token emite
		# expressao_completa de forma síncrona e torna a fase terminal.
		GameManager.register_correct_action()
		gerenciador.registrar_coleta_correta(simbolo)
		EfeitoEstouro.tocar_em(self, posicao)
		_mostrar_mensagem("Token '%s' preservado na ordem correta!" % simbolo, COR_SUCESSO)
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
		Fase6Estado.encerrar_execucao()
	else:
		# Sub-fases intermediárias (1 e 2): dão o mesmo bônus de pontos que
		# uma fase completa, mas SEM marcar completed_phases (o carimbo
		# "✓ Fase 6 concluída" só deve aparecer ao vencer a fase3).
		GameManager.award_sub_phase_bonus()

	_mostrar_mensagem("Expressão completa! Análise sintática concluída.", COR_SUCESSO)
	var tem_proxima := config.proxima_fase_config_path != ""
	var texto_conclusao := (
		"Você preservou os tokens esperados e eliminou os símbolos incorretos."
		if tem_proxima
		else "Você atuou como um analisador sintático: conferiu a ordem dos símbolos e protegeu a estrutura do código. Essa lógica faz parte do trabalho com compiladores, linguagens e desenvolvimento de jogos."
	)
	hud.show_completion(
		"FASE 6 CONCLUÍDA!" if not tem_proxima else "SUB-FASE CONCLUÍDA!",
		texto_conclusao,
		tem_proxima
	)

func _registrar_erro(motivo: String) -> void:
	if jogo_acabou:
		return
	GameManager.register_mistake(motivo)
	_mostrar_mensagem(motivo, COR_ERRO)
	_atualizar_ui()
	# GameManager.game_over já cobre lives == 0 via sinal (_on_game_manager_game_over).

func _on_game_manager_game_over(phase_id: int) -> void:
	if phase_id != PHASE_ID or jogo_acabou:
		return
	jogo_acabou = true
	spawner.pausar(true)
	canhao.definir_ativo(false)
	_remover_baloes_vivos()
	_mostrar_mensagem("Defesa rompida. Observe o próximo símbolo e tente novamente.", COR_ERRO)
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
	label_expressao.text = "[color=#d8e9f5][b]Expressão:[/b][/color] " + gerenciador.expressao_como_bbcode(
		Color("72e6a1"),
		Color("ffc43d"),
		Color("9aabba"),
		22,
		32
	)
	var proximo := gerenciador.proximo_esperado()
	label_progresso.text = "Próximo símbolo: %s   •   Progresso: %d/%d" % [
		proximo if proximo != "" else "✓",
		gerenciador.indice_atual,
		gerenciador.expressao.size(),
	]

func _mostrar_mensagem(texto: String, cor: Color = COR_NEUTRA) -> void:
	if label_mensagem:
		label_mensagem.text = texto
		label_mensagem.add_theme_color_override("font_color", cor)
	if hud:
		hud.set_feedback(texto, cor)

func _criar_hud() -> void:
	hud = HUD_SCENE.instantiate()
	add_child(hud)
	hud.configure_phase("FASE 6 - ANÁLISE SINTÁTICA", config.rotulo_fase, false)
	hud.configure_phase6_compact_layout()
	hud.hide_scanner_interface()
	hud.pause_requested.connect(_pausar)
	hud.resume_requested.connect(_retomar)
	hud.menu_confirmed.connect(_voltar_ao_menu)
	hud.retry_requested.connect(_on_botao_reiniciar_pressed)
	hud.next_requested.connect(_on_botao_proxima_fase_pressed)
	hud.replay_requested.connect(_on_replay_requested)

func _unhandled_input(event: InputEvent) -> void:
	if tutorial_mecanica_ativo:
		return
	if not event.is_action_pressed(&"pause"):
		return
	if pausado:
		_retomar()
	elif not jogo_acabou:
		_pausar()
	get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
	if (
		(event is InputEventKey and event.pressed)
		or (event is InputEventMouseButton and event.pressed)
		or (event is InputEventMouseMotion and event.relative.length_squared() > 4.0)
	):
		_tempo_sem_entrada = 0.0

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
	Fase6Estado.encerrar_execucao()
	if not fase_concluida:
		GameManager.abandon_phase()
	get_tree().change_scene_to_file("res://scenes/menu/menu.tscn")

func _on_replay_requested() -> void:
	if config.proxima_fase_config_path == "":
		GameManager.reset_lives()
		get_tree().change_scene_to_file(CAMINHO_TUTORIAL)
	else:
		_on_botao_reiniciar_pressed()

func _on_chefe_pronto_para_spawn() -> void:
	if Fase6Estado.tutorial_chefe_visto:
		_mostrar_alerta_chefe_breve()
		return
	Fase6Estado.tutorial_chefe_visto = true
	_spawnar_chefe_ao_fechar = true
	_abrir_overlay_mecanica(
		"UM GRANDE BALÃO ESTÁ VINDO!",
		"Ele é muito resistente e precisa de muitos disparos para estourar. Quando estoura, libera vários outros balões. Não deixe que chegue ao chão: você perderá todas as vidas!",
		Color("ffc43d"),
		true,
		true
	)

func _mostrar_tutorial_fortificado(balao: Balao) -> void:
	if not is_instance_valid(balao) or jogo_acabou:
		return
	_alvo_destaque = balao
	_abrir_overlay_mecanica(
		"NOVO: BALÃO REFORÇADO",
		"Este balão é mais resistente. O primeiro impacto apenas o enfraquece, então continue disparando até estourá-lo!",
		Color("ffc43d"),
		true
	)
	_iniciar_pulso_destaque()

func _mostrar_alerta_chefe_breve() -> void:
	_abrir_overlay_mecanica(
		"",
		"",
		Color("ffc43d"),
		false,
		true
	)
	await get_tree().create_timer(1.6, true).timeout
	if tutorial_mecanica_ativo and not jogo_acabou:
		_fechar_overlay_mecanica()
		spawner.spawnar_chefe()

func _abrir_overlay_mecanica(
	titulo: String,
	texto: String,
	cor: Color,
	interativo: bool,
	alerta_chefe: bool = false
) -> void:
	tutorial_mecanica_ativo = true
	_definir_simulacao_ativa(false)
	canhao.definir_ativo(false)
	overlay_painel.visible = interativo or not alerta_chefe
	overlay_titulo.text = titulo
	overlay_titulo.add_theme_color_override("font_color", cor)
	overlay_titulo.add_theme_font_size_override("font_size", 30)
	overlay_escurecer.color = (
		Color(0.01, 0.02, 0.04, 0.22 if interativo else 0.08)
		if alerta_chefe
		else Color(0.01, 0.02, 0.04, 0.38)
	)
	overlay_texto.text = texto
	overlay_botao.visible = interativo
	alerta_exclamacoes.visible = alerta_chefe
	alerta_fundo.visible = alerta_chefe
	overlay_mecanica.show()
	if alerta_chefe:
		_animar_alerta_chefe()
	if interativo:
		call_deferred("_focar_botao_overlay")

func _animar_alerta_chefe() -> void:
	alerta_exclamacoes.scale = Vector2(0.88, 0.88)
	alerta_exclamacoes.modulate.a = 0.7
	alerta_exclamacoes.pivot_offset = alerta_exclamacoes.size * 0.5
	var tween_exclamacoes := create_tween().set_loops(3)
	tween_exclamacoes.tween_property(alerta_exclamacoes, "scale", Vector2(1.08, 1.08), 0.22)
	tween_exclamacoes.parallel().tween_property(alerta_exclamacoes, "modulate:a", 1.0, 0.22)
	tween_exclamacoes.tween_property(alerta_exclamacoes, "scale", Vector2.ONE, 0.22)
	tween_exclamacoes.parallel().tween_property(alerta_exclamacoes, "modulate:a", 0.72, 0.22)

	# "CUIDADO!" funciona como marca-d'água e pulsa devagar. Não há
	# flashes rápidos nem mudança brusca da tela inteira.
	alerta_fundo.modulate.a = 0.12
	var tween_fundo := create_tween().set_loops(2)
	tween_fundo.tween_property(alerta_fundo, "modulate:a", 0.3, 0.42)
	tween_fundo.tween_property(alerta_fundo, "modulate:a", 0.12, 0.42)

func _focar_botao_overlay() -> void:
	if tutorial_mecanica_ativo and overlay_botao.visible and overlay_botao.is_inside_tree():
		overlay_botao.grab_focus()

func _on_overlay_mecanica_confirmado() -> void:
	if not tutorial_mecanica_ativo:
		return
	var deve_spawnar_chefe := _spawnar_chefe_ao_fechar
	_spawnar_chefe_ao_fechar = false
	_fechar_overlay_mecanica()
	if deve_spawnar_chefe:
		spawner.spawnar_chefe()

func _fechar_overlay_mecanica() -> void:
	overlay_mecanica.hide()
	alerta_exclamacoes.hide()
	alerta_fundo.hide()
	tutorial_mecanica_ativo = false
	_parar_pulso_destaque()
	_alvo_destaque = null
	if not jogo_acabou:
		_definir_simulacao_ativa(true)
		canhao.definir_ativo(true)

func _process(delta: float) -> void:
	if tempo_retorno_inatividade > 0.0 and not _retorno_inatividade_em_andamento:
		_tempo_sem_entrada += delta
		if _tempo_sem_entrada >= tempo_retorno_inatividade:
			_retorno_inatividade_em_andamento = true
			_voltar_ao_menu()
			return
	if not tutorial_mecanica_ativo:
		_verificar_tutorial_fortificado_pendente()

func _iniciar_pulso_destaque() -> void:
	if not is_instance_valid(_alvo_destaque):
		return
	_parar_pulso_destaque()
	_alvo_destaque.definir_destaque_visual(true)
	_tween_destaque = create_tween().set_loops()
	_tween_destaque.tween_method(
		_alvo_destaque.definir_intensidade_destaque,
		-0.18,
		0.34,
		0.42
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween_destaque.tween_method(
		_alvo_destaque.definir_intensidade_destaque,
		0.34,
		-0.18,
		0.42
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _parar_pulso_destaque() -> void:
	if _tween_destaque:
		_tween_destaque.kill()
		_tween_destaque = null
	if is_instance_valid(_alvo_destaque):
		_alvo_destaque.definir_destaque_visual(false)

func _verificar_tutorial_fortificado_pendente() -> void:
	if not is_instance_valid(_balao_fortificado_pendente):
		_balao_fortificado_pendente = null
		return
	if _balao_fortificado_pendente.is_queued_for_deletion():
		_balao_fortificado_pendente = null
		return
	# Se ele já foi atingido antes de ficar inteiramente visível, esperamos
	# o próximo reforçado para apresentar a propriedade ainda intacta.
	if _balao_fortificado_pendente.vidas < 2:
		_balao_fortificado_pendente = null
		return
	var altura_tela := get_viewport_rect().size.y
	if _balao_fortificado_pendente.global_position.y < altura_tela * 0.20:
		return
	var balao := _balao_fortificado_pendente
	_balao_fortificado_pendente = null
	Fase6Estado.tutorial_fortificado_visto = true
	_mostrar_tutorial_fortificado(balao)
