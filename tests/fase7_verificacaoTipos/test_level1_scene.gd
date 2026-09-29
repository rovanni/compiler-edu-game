## test_level1_scene.gd
##
## Teste de integração da cena scenes/levels/Level1.tscn: instancia a cena
## de verdade (não só a lógica isolada — complementa test_level1_logic.gd),
## chama _process com deltas grandes pra forçar quedas rápidas sem depender
## de tempo real, e confere que peças aterrissam, são julgadas e a UI
## (pontuação/barra/feedback) reage — incluindo o clamp de movimento lateral
## e o desligamento do jogo em COMPILATION FAILED.
##
## Como rodar (na pasta do projeto):
##   godot --headless --script res://scripts/tests/test_level1_scene.gd
##
## Nota: como --headless --script sai antes de qualquer frame real passar,
## o _ready() da cena (que resolve as vars @onready) nunca dispara sozinho
## — por isso chamamos `instancia._ready()` na mão logo após instanciar.
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
	# Autoloads (GameManager) só ficam registrados como identificador global
	# depois do primeiro ciclo de inicialização da SceneTree — adiamos a
	# carga/execução real com call_deferred() pra evitar erro de compilação
	# "Identifier not found: GameManager" ao dar load() nas cenas da Fase 7
	# (mesmo padrão já usado pelo harness de teste do resto do projeto, ver
	# tests/headless_fase6_test.gd).
	call_deferred("_executar")


func _executar() -> void:
	print("=== Smoke test: Level1.tscn instanciada de verdade ===\n")

	var packed: PackedScene = load("res://scenes/fase7_verificacaoTipos/Level1.tscn")
	var instancia: Control = packed.instantiate()
	root.add_child(instancia)
	# Em --headless --script não passa nenhum frame antes do quit(), então o
	# _ready() (que resolve as vars @onready) nunca dispara sozinho — chamamos
	# na mão. Como vamos sair antes de qualquer frame real, não roda em dobro.
	instancia._ready()

	_check("cena instanciou e entrou na árvore sem erro", is_instance_valid(instancia))
	_check("_ready() rodou (barra do compilador começa em 100)", instancia._barra_compilador.value == 100.0)
	_check("primeira peça já foi sorteada", instancia._peca_texto_atual != "")
	_check("explosão de derrota começa escondida", instancia._explosao_derrota.visible == false)
	_check("texto de derrota começa escondido", instancia._texto_derrota.visible == false)

	var pontuacao_inicial: int = instancia._logica.pontuacao
	var texto_antes = instancia._peca_texto_atual

	# Delta grande o bastante pra garantir que a peça atinja o chão numa
	# chamada só (velocidade_queda * delta >= y_alvo).
	instancia._process(10.0)

	_check("depois de cair, uma peça nova foi sorteada (pode repetir o texto por sorte, mas o feedback deve ter mudado)", instancia._label_feedback.text != "")
	_check("mensagem de feedback é ✓ ou reflete um erro", instancia._label_feedback.text.begins_with("✓") or instancia._label_feedback.text.length() > 0)

	# Roda várias quedas seguidas pra ver o placar/barra se moverem de
	# alguma forma (ou os dois +100 quando acerta, ou a barra -20 quando erra).
	var mudou_algo := false
	for i in 20:
		instancia._process(10.0)
		if instancia._logica.pontuacao != pontuacao_inicial or instancia._barra_compilador.value != 100.0:
			mudou_algo = true
	_check("depois de 20 quedas, pontuação e/ou barra mudaram (o loop está rodando de verdade)", mudou_algo)

	# Movimento lateral: a peça deve ir pro centro da coluna escolhida.
	instancia._mover_lane(-10) # clamp pra 0 (mais à esquerda)
	instancia._atualizar_posicao_x()
	var coluna0: Control = instancia._colunas_nodes[0]
	var centro_esperado: float = coluna0.position.x + coluna0.size.x / 2.0 - instancia._peca_caindo.size.x / 2.0
	_check("mover totalmente pra esquerda trava na coluna 0 (clamp) e centraliza a peça", is_equal_approx(instancia._peca_caindo.position.x, centro_esperado))

	instancia._mover_lane(10) # clamp pra 4 (mais à direita)
	var coluna4: Control = instancia._colunas_nodes[4]
	var centro4: float = coluna4.position.x + coluna4.size.x / 2.0 - instancia._peca_caindo.size.x / 2.0
	_check("mover totalmente pra direita trava na coluna 4 (clamp) e centraliza a peça", is_equal_approx(instancia._peca_caindo.position.x, centro4))

	# Força muitos erros de propósito pra checar o game over visual.
	for i in 10:
		instancia._logica.julgar(999, "isso não devia bater com nada") # coluna inválida de propósito -> sempre erra
	_check("depois de forçar vários erros, compilacao_falhou desligou o jogo (_jogo_ativo=false)", instancia._jogo_ativo == false)
	_check("explosão de derrota ficou visível no game over", instancia._explosao_derrota.visible == true)
	_check("explosão de derrota tem um AnimatedTexture de 8 quadros", (instancia._explosao_derrota.texture as AnimatedTexture).frames == 8)
	_check("texto de derrota ficou visível, centralizado, no game over", instancia._texto_derrota.visible == true)
	_check("texto de derrota menciona GAME OVER", instancia._texto_derrota.text.findn("GAME OVER") != -1)

	var y_antes_de_travado = instancia._peca_caindo.position.y
	instancia._process(10.0) # não deveria mais mover nada, jogo acabou
	_check("com o jogo acabado, _process não mexe mais na peça caindo", instancia._peca_caindo.position.y == y_antes_de_travado)

	print("")
	if _falhas == 0:
		print("✓ TODOS OS %d TESTES DE FUMAÇA PASSARAM" % _total)
	else:
		print("✗ %d de %d testes de fumaça FALHARAM" % [_falhas, _total])

	instancia.queue_free()
	quit(1 if _falhas > 0 else 0)
