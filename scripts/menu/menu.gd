extends Control

# Modais
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

func esconder_todos_modais() -> void:
	if modal_config: modal_config.hide()
	if modal_ranking: modal_ranking.hide()
	if modal_tutorial: modal_tutorial.hide()
	if modal_aprender: modal_aprender.hide()
	if modal_creditos: modal_creditos.hide()

# --- Ações Principais ---

func _on_btn_jogar_pressed() -> void:
	iniciar_fase("res://scenes/fase1_tokens/Main.tscn")

func _on_btn_fases_pressed() -> void:
	# Rola a visão ou destaca a grade de mundos
	var grid = $MarginContainer/HBoxMain/RightPanel
	if grid:
		grid.grab_focus()

func _on_btn_aprender_pressed() -> void:
	esconder_todos_modais()
	if modal_aprender: modal_aprender.show()

func _on_btn_creditos_pressed() -> void:
	esconder_todos_modais()
	if modal_creditos: modal_creditos.show()

# --- Ações TopBar ---

func _on_btn_configuracoes_pressed() -> void:
	esconder_todos_modais()
	if modal_config: modal_config.show()

func _on_btn_ranking_pressed() -> void:
	esconder_todos_modais()
	if modal_ranking: modal_ranking.show()

func _on_btn_tutorial_pressed() -> void:
	esconder_todos_modais()
	if modal_tutorial: modal_tutorial.show()

# --- Ações dos Cards de Mundos ---

func _on_card_fase_1_pressed() -> void:
	iniciar_fase("res://scenes/fase1_tokens/Main.tscn")

func _on_card_fase_2_pressed() -> void:
	exibir_mensagem_em_breve("Vale do Scanner")

func _on_card_fase_3_pressed() -> void:
	exibir_mensagem_em_breve("Caverna do Parser")

func _on_card_fase_4_pressed() -> void:
	exibir_mensagem_em_breve("Floresta da AST")

func _on_card_fase_5_pressed() -> void:
	exibir_mensagem_em_breve("Castelo dos Erros Léxicos")

func _on_card_fase_6_pressed() -> void:
	exibir_mensagem_em_breve("Fortaleza dos Erros Sintáticos")

# --- Helpers ---

func iniciar_fase(caminho_cena: String) -> void:
	get_tree().change_scene_to_file(caminho_cena)

func exibir_mensagem_em_breve(nome_fase: String) -> void:
	print("A fase '", nome_fase, "' está em desenvolvimento!")

func _on_btn_fechar_modal_pressed() -> void:
	esconder_todos_modais()
