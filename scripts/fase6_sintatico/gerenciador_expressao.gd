extends Node
class_name GerenciadorExpressao
## Controla a expressão-objetivo da fase e qual símbolo é o "próximo esperado".
## A expressão é sempre definida em "tokens de nível alto" (ex: ["x", "=",
## "20", "+", "5"]), mas números com mais de um dígito são AUTOMATICAMENTE
## quebrados em dígitos individuais internamente (ex: "20" -> "2", "0"),
## pois cada balão só carrega um caractere por vez.
## Avanço é sempre POSICIONAL (indice_atual): só o balão que cai no índice
## certo conta como acerto. Vários balões iguais no ar não avançam o
## ponteiro sozinhos — só um deles pode efetivamente ser coletado por vez.

signal token_correto_coletado(simbolo: String, indice: int)
signal expressao_completa

## Expressão já expandida em caracteres individuais (o que o jogo usa).
var expressao: Array[String] = []
var indice_atual: int = 0

func definir_expressao(tokens: Array[String]) -> void:
	expressao = _expandir_em_caracteres(tokens)
	indice_atual = 0

## Quebra qualquer token numérico com 2+ dígitos em dígitos individuais,
## na ordem em que aparecem (ex: "20" -> "2", "0"). Tokens não-numéricos
## (variáveis, operadores, dígitos únicos) passam direto.
func _expandir_em_caracteres(tokens: Array[String]) -> Array[String]:
	var resultado: Array[String] = []
	for token in tokens:
		if token.is_valid_int() and token.length() > 1:
			for c in token:
				resultado.append(c)
		else:
			resultado.append(token)
	return resultado

func proximo_esperado() -> String:
	if indice_atual >= expressao.size():
		return ""
	return expressao[indice_atual]

## true se o próximo caractere esperado é um dígito (0-9).
func proximo_esperado_eh_digito() -> bool:
	return proximo_esperado().is_valid_int()

func pertence_a_expressao(simbolo: String) -> bool:
	# Verifica se o símbolo aparece em algum ponto ainda não coletado da expressão.
	for i in range(indice_atual, expressao.size()):
		if expressao[i] == simbolo:
			return true
	return false

func eh_a_vez_dele(simbolo: String) -> bool:
	return proximo_esperado() == simbolo

## Chamado quando um balão "correto" (é a vez dele) chega ao chão.
## O estado é atualizado antes dos sinais, garantindo que todo observador
## enxergue o novo progresso. Retorna false se o caller violar a ordem.
func registrar_coleta_correta(simbolo: String) -> bool:
	if not eh_a_vez_dele(simbolo):
		return false
	var indice_coletado := indice_atual
	indice_atual += 1
	token_correto_coletado.emit(simbolo, indice_coletado)
	if indice_atual >= expressao.size():
		expressao_completa.emit()
	return true

func reiniciar() -> void:
	indice_atual = 0

func expressao_como_texto() -> String:
	return " ".join(expressao)

## Texto com BBCode para exibir a expressão-objetivo com destaque visual:
## - já coletado: verde
## - caractere atual esperado: preto, negrito, fonte maior ("selecionado")
## - ainda não é a vez: cinza ("em breve")
## tamanho_base deve bater com o normal_font_size configurado na
## RichTextLabel na cena; tamanho_atual é o tamanho absoluto (maior) do
## caractere em destaque. [font_size=+N] não é confiável no BBCode do
## Godot, então usamos sempre valores absolutos.
func expressao_como_bbcode(
	cor_coletado: Color = Color(0.2, 0.7, 0.3),
	cor_atual: Color = Color(0.05, 0.05, 0.05),
	cor_futuro: Color = Color(0.6, 0.6, 0.6),
	tamanho_base: int = 22,
	tamanho_atual: int = 34
) -> String:
	var partes: Array[String] = []
	for i in range(expressao.size()):
		var c := expressao[i]
		var exibido := c.replace("[", "(").replace("]", ")")
		if i < indice_atual:
			partes.append(
				"[color=#%s][font_size=%d]%s[/font_size][/color]"
				% [cor_coletado.to_html(false), tamanho_base, exibido]
			)
		elif i == indice_atual:
			partes.append(
				"[color=#%s][b][font_size=%d]%s[/font_size][/b][/color]"
				% [cor_atual.to_html(false), tamanho_atual, exibido]
			)
		else:
			partes.append(
				"[color=#%s][font_size=%d]%s[/font_size][/color]"
				% [cor_futuro.to_html(false), tamanho_base, exibido]
			)
	return " ".join(partes)
