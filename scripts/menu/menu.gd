extends Control

# Modais
@onready var container_modais: Control = $Modais
@onready var modal_config: Control = $Modais/ModalConfig
@onready var modal_ranking: Control = $Modais/ModalRanking
@onready var modal_tutorial: Control = $Modais/ModalTutorial
@onready var modal_aprender: Control = $Modais/ModalAprender
@onready var modal_creditos: Control = $Modais/ModalCreditos

# Configurações de Áudio / Som
var som_ativo: bool = true
var musica_ativa: bool = true

func _ready() -> void:
	esconder_todos_modais()
	aplicar_estilos_prototipo()
	atualizar_estado_da_sessao()

func esconder_todos_modais() -> void:
	if container_modais: container_modais.hide()
	if modal_config: modal_config.hide()
	if modal_ranking: modal_ranking.hide()
	if modal_tutorial: modal_tutorial.hide()
	if modal_aprender: modal_aprender.hide()
	if modal_creditos: modal_creditos.hide()

func abrir_modal(modal: Control) -> void:
	esconder_todos_modais()
	if container_modais: container_modais.show()
	if modal: modal.show()

# --- Estilização Dinâmica com a Paleta do Protótipo (Bordas Pretas & Contorno nos Títulos) ---
func aplicar_estilos_prototipo() -> void:
	var cor_borda_preta = Color("#000000")

	# 1. Botões Principais de Ação (Verde, Roxo, Laranja) com borda PRETA
	var btn_jogar = get_node_or_null("MarginContainer/VBoxRoot/HBoxMain/LeftPanel/ContentSplit/ActionButtons/BtnJogar")
	if btn_jogar:
		estilar_botao(btn_jogar, Color("#34A853"), Color("#42B863"), cor_borda_preta, 10, 3)

	var btn_aprender = get_node_or_null("MarginContainer/VBoxRoot/HBoxMain/LeftPanel/ContentSplit/ActionButtons/BtnAprender")
	if btn_aprender:
		estilar_botao(btn_aprender, Color("#8A2BE2"), Color("#9D44E8"), cor_borda_preta, 10, 3)

	var btn_creditos = get_node_or_null("MarginContainer/VBoxRoot/HBoxMain/LeftPanel/ContentSplit/ActionButtons/BtnCreditos")
	if btn_creditos:
		estilar_botao(btn_creditos, Color("#E67E22"), Color("#F39C12"), cor_borda_preta, 10, 3)

	# 2. Botões da Barra Superior (TopBar) com borda PRETA
	var topbar_btns = [
		get_node_or_null("MarginContainer/VBoxRoot/TopBar/BtnConfiguracoes"),
		get_node_or_null("MarginContainer/VBoxRoot/TopBar/BtnRanking"),
		get_node_or_null("MarginContainer/VBoxRoot/TopBar/BtnTutorial")
	]
	for b in topbar_btns:
		if b:
			estilar_botao(b, Color("#1C2638"), Color("#2C3B54"), cor_borda_preta, 8, 2)

	# 3. Cards dos Mundos (Grid) com borda PRETA
	var card1 = get_node_or_null("MarginContainer/VBoxRoot/HBoxMain/RightPanel/VBoxMundos/GridCards/CardFase1")
	if card1: estilar_card(card1, Color("#1E4627"), cor_borda_preta)
	
	var card2 = get_node_or_null("MarginContainer/VBoxRoot/HBoxMain/RightPanel/VBoxMundos/GridCards/CardFase2")
	if card2: estilar_card(card2, Color("#19376D"), cor_borda_preta)
	
	var card3 = get_node_or_null("MarginContainer/VBoxRoot/HBoxMain/RightPanel/VBoxMundos/GridCards/CardFase3")
	if card3: estilar_card(card3, Color("#5C4A1E"), cor_borda_preta)
	
	var card4 = get_node_or_null("MarginContainer/VBoxRoot/HBoxMain/RightPanel/VBoxMundos/GridCards/CardFase4")
	if card4: estilar_card(card4, Color("#442A5C"), cor_borda_preta)
	
	var card5 = get_node_or_null("MarginContainer/VBoxRoot/HBoxMain/RightPanel/VBoxMundos/GridCards/CardFase5")
	if card5: estilar_card(card5, Color("#5C2A2A"), cor_borda_preta)
	
	var card6 = get_node_or_null("MarginContainer/VBoxRoot/HBoxMain/RightPanel/VBoxMundos/GridCards/CardFase6")
	if card6: estilar_card(card6, Color("#3A1A2A"), cor_borda_preta)

	# 4. Ribbon e Painéis de Fundo com borda PRETA
	var ribbon = get_node_or_null("MarginContainer/VBoxRoot/HBoxMain/LeftPanel/HeaderContainer/RibbonBanner")
	if ribbon:
		estilar_painel(ribbon, Color("#3F2B68"), cor_borda_preta, 8, 2)

	var mission = get_node_or_null("MarginContainer/VBoxRoot/HBoxMain/LeftPanel/ContentSplit/MissionBoard")
	if mission:
		estilar_painel(mission, Color("#4A2E16"), cor_borda_preta, 10, 2, 10)

	var right_panel = get_node_or_null("MarginContainer/VBoxRoot/HBoxMain/RightPanel")
	if right_panel:
		estilar_painel(right_panel, Color("#131927"), cor_borda_preta, 12, 3)

	# 5. Modais (Fundo Azul Opaco estilo Vale do Scanner #19376D com Borda PRETA)
	var modais = [modal_config, modal_ranking, modal_tutorial, modal_aprender, modal_creditos]
	for m in modais:
		if m:
			estilar_painel(m, Color("#19376D"), cor_borda_preta, 12, 3)

	# Botões de Fechar nos Modais (Borda Preta)
	var fechar_btns = [
		get_node_or_null("Modais/ModalConfig/VBoxConfig/BtnVoltarConfig"),
		get_node_or_null("Modais/ModalRanking/VBoxRanking/BtnVoltarRanking"),
		get_node_or_null("Modais/ModalTutorial/VBoxTutorial/BtnVoltarTutorial"),
		get_node_or_null("Modais/ModalAprender/VBoxAprender/BtnVoltarAprender"),
		get_node_or_null("Modais/ModalCreditos/VBoxCreditos/BtnVoltarCreditos")
	]
	for fb in fechar_btns:
		if fb:
			estilar_botao(fb, Color("#34A853"), Color("#42B863"), cor_borda_preta, 8, 2)

	# 6. Contornos pretos nos títulos para destaque perfeito
	adicionar_contorno_titulos()

func estilar_botao(btn: Button, bg: Color, hover_bg: Color, border: Color, corner_radius: int = 10, border_width: int = 2) -> void:
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = bg
	style_normal.border_color = border
	style_normal.set_border_width_all(border_width)
	style_normal.set_corner_radius_all(corner_radius)
	style_normal.content_margin_left = 10
	style_normal.content_margin_top = 6
	style_normal.content_margin_right = 10
	style_normal.content_margin_bottom = 6

	var style_hover = style_normal.duplicate()
	style_hover.bg_color = hover_bg

	var style_pressed = style_normal.duplicate()
	style_pressed.bg_color = bg.darkened(0.2)

	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("pressed", style_pressed)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color(0.9, 0.9, 0.9, 1))
	btn.add_theme_color_override("font_outline_color", Color.BLACK)
	btn.add_theme_constant_override("outline_size", 5)

func estilar_card(btn: Button, bg: Color, border: Color) -> void:
	estilar_botao(btn, bg, bg.lightened(0.15), border, 10, 3)

func estilar_painel(panel: PanelContainer, bg: Color, border: Color, corner_radius: int = 10, border_width: int = 2, margin: int = 14) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(corner_radius)
	style.content_margin_left = margin
	style.content_margin_top = margin
	style.content_margin_right = margin
	style.content_margin_bottom = margin
	panel.add_theme_stylebox_override("panel", style)

func adicionar_contorno_titulos() -> void:
	var labels = [
		get_node_or_null("MarginContainer/VBoxRoot/HBoxMain/LeftPanel/HeaderContainer/HBoxTitleLine1/LblCompiler"),
		get_node_or_null("MarginContainer/VBoxRoot/HBoxMain/LeftPanel/HeaderContainer/HBoxTitleLine1/LblGear"),
		get_node_or_null("MarginContainer/VBoxRoot/HBoxMain/LeftPanel/HeaderContainer/HBoxTitleLine2/LblCode"),
		get_node_or_null("MarginContainer/VBoxRoot/HBoxMain/LeftPanel/HeaderContainer/HBoxTitleLine2/LblEdu"),
		get_node_or_null("MarginContainer/VBoxRoot/HBoxMain/LeftPanel/HeaderContainer/HBoxTitleLine2/LblGame"),
		get_node_or_null("MarginContainer/VBoxRoot/HBoxMain/LeftPanel/HeaderContainer/RibbonBanner/LblRibbon"),
		get_node_or_null("MarginContainer/VBoxRoot/HBoxMain/LeftPanel/ContentSplit/MissionBoard/VBoxMission/LblMissionTitle"),
		get_node_or_null("MarginContainer/VBoxRoot/HBoxMain/RightPanel/VBoxMundos/LblMundosTitle"),
		get_node_or_null("Modais/ModalConfig/VBoxConfig/LblConfigTitle"),
		get_node_or_null("Modais/ModalRanking/VBoxRanking/LblRankingTitle"),
		get_node_or_null("Modais/ModalTutorial/VBoxTutorial/LblTutorialTitle"),
		get_node_or_null("Modais/ModalAprender/VBoxAprender/LblAprenderTitle"),
		get_node_or_null("Modais/ModalCreditos/VBoxCreditos/LblCreditosTitle")
	]
	for l in labels:
		if l:
			l.add_theme_color_override("font_outline_color", Color.BLACK)
			l.add_theme_constant_override("outline_size", 8)

# --- Ações Principais ---
func _on_btn_jogar_pressed() -> void:
	GameManager.start_new_session(1)
	iniciar_fase("res://scenes/fase1_tokens/Main.tscn")

func _on_btn_fases_pressed() -> void:
	var grid = $MarginContainer/VBoxRoot/HBoxMain/RightPanel
	if grid:
		grid.grab_focus()

func _on_btn_aprender_pressed() -> void:
	abrir_modal(modal_aprender)

func _on_btn_creditos_pressed() -> void:
	abrir_modal(modal_creditos)

# --- Ações TopBar ---
func _on_btn_configuracoes_pressed() -> void:
	abrir_modal(modal_config)

func _on_btn_ranking_pressed() -> void:
	abrir_modal(modal_ranking)

func _on_btn_tutorial_pressed() -> void:
	abrir_modal(modal_tutorial)

# --- Ações dos Cards de Mundos ---
func _on_card_fase_1_pressed() -> void:
	preparar_fase(1)
	iniciar_fase("res://scenes/fase1_tokens/Main.tscn")

func _on_card_fase_2_pressed() -> void:
	preparar_fase(2)
	iniciar_fase("res://scenes/fase2_scanner/main.tscn")

func _on_card_fase_3_pressed() -> void:
	exibir_mensagem_em_breve("Caverna do Parser")

func _on_card_fase_4_pressed() -> void:
	iniciar_fase("res://scenes/fase4_ast/Main.tscn")

func _on_card_fase_5_pressed() -> void:
	exibir_mensagem_em_breve("Castelo dos Erros Léxicos")

func _on_card_fase_6_pressed() -> void:
	preparar_fase(6)
	iniciar_fase("res://scenes/fase6_sintatico/Main.tscn")

# --- Helpers ---
func iniciar_fase(caminho_cena: String) -> void:
	get_tree().change_scene_to_file(caminho_cena)

func preparar_fase(fase_id: int) -> void:
	if GameManager.session_active:
		GameManager.begin_phase(fase_id)
	else:
		GameManager.start_new_session(fase_id)

func atualizar_estado_da_sessao() -> void:
	var status: Label = $MarginContainer/VBoxRoot/FooterBar/LblVersion
	if not GameManager.session_active:
		status.text = "v1.0.0"
		return

	status.text = "PONTOS %d • VIDAS %d" % [GameManager.score, GameManager.lives]

	var card_fase_2: Button = $MarginContainer/VBoxRoot/HBoxMain/RightPanel/VBoxMundos/GridCards/CardFase2
	if GameManager.is_phase_completed(2):
		card_fase_2.text = "✓ 2\nVALE DO SCANNER\n(CONCLUÍDA)"

	var card_fase_6: Button = get_node_or_null("MarginContainer/VBoxRoot/HBoxMain/RightPanel/VBoxMundos/GridCards/CardFase6")
	if card_fase_6 and GameManager.is_phase_completed(6):
		card_fase_6.text = "✓ 6\nFORTALEZA DOS ERROS SINTÁTICOS\n(CONCLUÍDA)"

func exibir_mensagem_em_breve(nome_fase: String) -> void:
	print("A fase '", nome_fase, "' está em desenvolvimento!")

func _on_btn_fechar_modal_pressed() -> void:
	esconder_todos_modais()
