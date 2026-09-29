## test_caminho_visual.gd
##
## Teste da textura do caminho recebida do Anibal (GDD seção 5-B.5) — só
## confere que carrega, as dimensões batem com o que foi enviado, e que dá
## pra escalar pra cobrir a largura do canvas (1280) sem esticar feio.
##
## Como rodar (na pasta do projeto):
##   godot --headless --script res://scripts/tests/test_caminho_visual.gd
extends SceneTree

const CANVAS_LARGURA := 1280.0

var _total := 0
var _falhas := 0


func _check(descricao: String, condicao: bool) -> void:
	_total += 1
	if condicao:
		print("  ✓ %s" % descricao)
	else:
		_falhas += 1
		print("  ✗ FALHOU: %s" % descricao)


func _init() -> void:
	print("=== Teste: textura do caminho (Torre de Defesa, GDD 5-B.5) ===\n")

	var textura: Texture2D = load("res://assets/fase7_verificacaoTipos/sprites/paths/caminho_trilha.png")
	_check("textura do caminho carrega", textura != null)
	_check("dimensões batem com o arquivo enviado (1672x941)", textura.get_size() == Vector2(1672, 941))

	var escala := CANVAS_LARGURA / textura.get_width()
	var altura_resultante := textura.get_height() * escala
	_check("escalando pra largura do canvas (1280) dá uma altura razoável (>200px)", altura_resultante > 200.0)

	var caminho := TextureRect.new()
	caminho.texture = textura
	root.add_child(caminho)
	_check("TextureRect aceita a textura sem erro", caminho.texture != null)
	caminho.queue_free()

	print("")
	if _falhas == 0:
		print("✓ TODOS OS %d TESTES PASSARAM" % _total)
	else:
		print("✗ %d de %d TESTES FALHARAM" % [_falhas, _total])

	quit(1 if _falhas > 0 else 0)
