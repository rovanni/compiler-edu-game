## test_inimigo_visual.gd
##
## Teste do primeiro asset visual da Torre de Defesa (GDD seção 5-B.5) — o
## SpriteFrames "flutuar" do inimigo base (recebido do Anibal, 7 quadros).
## Confere que o recurso carrega certinho, tem os 7 quadros, está em loop, e
## que dá pra recolorir por tipo de dado via `modulate` (decisão tomada:
## a criatura azul é a base genérica, recolorida em runtime — GDD 5-B.4).
##
## Como rodar (na pasta do projeto):
##   godot --headless --script res://scripts/tests/test_inimigo_visual.gd
extends SceneTree

const DataTypes = preload("res://scripts/fase7_verificacaoTipos/data_types.gd")

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
	print("=== Teste: asset visual do inimigo base (Torre de Defesa, GDD 5-B.5) ===\n")

	var frames: SpriteFrames = load("res://assets/fase7_verificacaoTipos/sprites/enemies/inimigo_base_flutuar.tres")
	_check("SpriteFrames carrega sem erro", frames != null)
	_check("tem a animação 'flutuar'", frames.has_animation("flutuar"))
	_check("animação 'flutuar' tem 7 quadros", frames.get_frame_count("flutuar") == 7)
	_check("animação está em loop (tremulação contínua enquanto flutua)", frames.get_animation_loop("flutuar") == true)

	for i in 7:
		var textura := frames.get_frame_texture("flutuar", i)
		_check("quadro %d tem textura carregada" % (i + 1), textura != null)

	# Simula o uso real: um AnimatedSprite2D com esse SpriteFrames, tocando
	# a animação e recolorido por tipo (a decisão de "base genérica +
	# modulate por tipo", em vez de uma arte por tipo).
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	root.add_child(sprite)
	sprite.play("flutuar")
	_check("AnimatedSprite2D aceita o recurso e toca a animação", sprite.is_playing() and sprite.animation == "flutuar")

	var cores_por_tipo := {
		DataTypes.Tipo.INT: Color(0.3, 0.55, 1.0),
		DataTypes.Tipo.FLOAT: Color(0.3, 0.9, 0.8),
		DataTypes.Tipo.STRING: Color(1.0, 0.85, 0.3),
		DataTypes.Tipo.BOOLEAN: Color(1.0, 0.55, 0.2),
		DataTypes.Tipo.CHAR: Color(0.75, 0.4, 1.0),
	}
	for tipo in cores_por_tipo:
		sprite.modulate = cores_por_tipo[tipo]
		_check("recolore pro tipo %s sem erro (modulate aplicado)" % DataTypes.nome_tipo(tipo), sprite.modulate == cores_por_tipo[tipo])

	sprite.queue_free()

	print("")
	if _falhas == 0:
		print("✓ TODOS OS %d TESTES PASSARAM" % _total)
	else:
		print("✗ %d de %d TESTES FALHARAM" % [_falhas, _total])

	quit(1 if _falhas > 0 else 0)
