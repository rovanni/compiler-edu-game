extends Node2D

var tokens_coletados := 0
var total_tokens := 0

var posicao_inicial: Vector2

func _ready() -> void:
	posicao_inicial = $Jogador.global_position

	total_tokens = $Tokens.get_child_count()

	for token in $Tokens.get_children():
		token.coletado.connect(_on_token_coletado)

	$Espinho2.atingido.connect(_on_espinho_atingido)
	$Espinho.atingido.connect(_on_espinho_atingido)

func _on_token_coletado() -> void:
	tokens_coletados += 1

	print("Tokens coletados: ", tokens_coletados, "/", total_tokens)

	if tokens_coletados == total_tokens:
		vencer()

func _on_espinho_atingido() -> void:
	resetar_fase()

func resetar_fase() -> void:
	$Jogador.global_position = posicao_inicial

	$Jogador.velocity = Vector2.ZERO

	tokens_coletados = 0

	for token in $Tokens.get_children():
		token.resetar()

	print("Tokens resetados!")

func vencer() -> void:
	print("FASE CONCLUÍDA!")
