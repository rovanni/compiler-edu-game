## test_inimigo_corrompido_visual.gd
##
## Teste da variante "corrompida" do inimigo (GDD seção 5-B.5, recebida na
## v2.4 — só usada de verdade a partir da v2.8) — o SpriteFrames "flutuar"
## com 8 quadros (núcleo vermelho/rachado, garras, `!` e `{ }` soltos),
## usada pros inimigos cuja `defesa_correta` é `TowerDefenseSystem.DEFESA_ERRO`
## (expressão/atribuição inválida — Níveis 3 e 4), em vez do inimigo base
## recolorido de vermelho. Diferente do inimigo base, este NÃO é recolorido
## via `modulate` — a arte já vem com a cor de erro própria.
##
## Como rodar (na pasta do projeto):
##   godot --headless --script res://scripts/tests/test_inimigo_corrompido_visual.gd
extends SceneTree

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
	print("=== Teste: variante corrompida do inimigo (Torre de Defesa, GDD 5-B.5) ===\n")

	var frames: SpriteFrames = load("res://assets/fase7_verificacaoTipos/sprites/enemies/inimigo_corrompido_flutuar.tres")
	_check("SpriteFrames carrega sem erro", frames != null)
	_check("tem a animação 'flutuar'", frames.has_animation("flutuar"))
	_check("animação 'flutuar' tem 8 quadros", frames.get_frame_count("flutuar") == 8)
	_check("animação está em loop", frames.get_animation_loop("flutuar") == true)

	for i in 8:
		var textura := frames.get_frame_texture("flutuar", i)
		_check("quadro %d tem textura carregada" % (i + 1), textura != null)

	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	root.add_child(sprite)
	sprite.play("flutuar")
	_check("AnimatedSprite2D aceita o recurso e toca a animação", sprite.is_playing() and sprite.animation == "flutuar")

	sprite.queue_free()

	print("")
	if _falhas == 0:
		print("✓ TODOS OS %d TESTES PASSARAM" % _total)
	else:
		print("✗ %d de %d TESTES FALHARAM" % [_falhas, _total])

	quit(1 if _falhas > 0 else 0)
