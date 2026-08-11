extends CanvasLayer

@onready var label_token: Label = $PainelHUD/HBoxHUD/TokenInfo/LabelTokenValor
@onready var label_instrucao: Label = $PainelHUD/HBoxHUD/Instrucao/LabelInstrucao

func atualizar_token(token: String) -> void:
	label_token.text = token

func mostrar_instrucao(texto: String) -> void:
	label_instrucao.text = texto
