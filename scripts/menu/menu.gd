extends Control

@onready var panel_fases: PanelContainer = $PanelFases

func _ready() -> void:
	if panel_fases:
		panel_fases.hide()

func _on_btn_jogar_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/fase1_tokens/Main.tscn")

func _on_btn_fases_pressed() -> void:
	if panel_fases:
		panel_fases.show()

func _on_btn_sair_pressed() -> void:
	get_tree().quit()

func _on_btn_fase_1_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/fase1_tokens/Main.tscn")

func _on_btn_fechar_fases_pressed() -> void:
	if panel_fases:
		panel_fases.hide()
