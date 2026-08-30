extends SceneTree

const GerenciadorExpressaoScript := preload("res://scripts/fase6_sintatico/gerenciador_expressao.gd")
const SpawnerBaloesScript := preload("res://scripts/fase6_sintatico/spawner_baloes.gd")
const ConfigFaseScript := preload("res://scripts/fase6_sintatico/config_fase.gd")
const GameManagerScript := preload("res://scripts/autoload/game_manager.gd")
const BALAO_SCENE := preload("res://scenes/fase6_sintatico/balao.tscn")
const CANHAO_SCENE := preload("res://scenes/fase6_sintatico/canhao.tscn")
const EFEITO_SCENE := preload("res://scenes/fase6_sintatico/efeito_estouro.tscn")

var failures := 0

func _init() -> void:
	call_deferred("_executar")

func _executar() -> void:
	_test_progresso_da_expressao()
	await _test_gatilho_do_chefe()
	_test_penalidade_fatal()
	_test_material_de_destaque()
	_test_integracao_dos_assets()
	await _test_combo_quebrado_ao_estourar_simbolo_certo()
	_test_layout_e_cliques_da_fase6()
	await process_frame

	if failures == 0:
		print("PASS: lógica, chefe, penalidade, destaque e assets finais da Fase 6")
		quit(0)
	else:
		push_error("FAIL: %d teste(s) da Fase 6 falharam" % failures)
		quit(1)

func _test_progresso_da_expressao() -> void:
	var gerenciador = GerenciadorExpressaoScript.new()
	root.add_child(gerenciador)
	gerenciador.definir_expressao(["x", "=", "20"])
	_expect(gerenciador.expressao == ["x", "=", "2", "0"], "números devem ser expandidos em dígitos")

	var indice_observado := [-1]
	var indice_emitido := [-1]
	gerenciador.token_correto_coletado.connect(func(_simbolo: String, indice: int) -> void:
		indice_observado[0] = gerenciador.indice_atual
		indice_emitido[0] = indice
	)

	_expect(gerenciador.registrar_coleta_correta("x"), "o próximo símbolo deve ser aceito")
	_expect(indice_emitido[0] == 0, "o sinal deve informar o índice coletado")
	_expect(indice_observado[0] == 1, "observadores devem enxergar o progresso já atualizado")
	_expect(not gerenciador.registrar_coleta_correta("0"), "símbolo fora de ordem deve ser rejeitado")
	_expect(gerenciador.indice_atual == 1, "entrada inválida não deve alterar o progresso")
	gerenciador.queue_free()

func _test_gatilho_do_chefe() -> void:
	var gerenciador = GerenciadorExpressaoScript.new()
	root.add_child(gerenciador)
	gerenciador.definir_expressao(["x", "=", "1", "2"])

	var spawner = SpawnerBaloesScript.new()
	spawner.cena_balao = BALAO_SCENE
	spawner.intervalo_spawn = 999.0
	root.add_child(spawner)
	var config = ConfigFaseScript.new()
	config.inicia_com_chefe = true
	config.intervalo_spawn = 999.0
	spawner.aplicar_config(config)
	spawner.iniciar(gerenciador)
	spawner.pausar(true)

	var alertas := [0]
	spawner.chefe_pronto_para_spawn.connect(func() -> void: alertas[0] += 1)
	gerenciador.registrar_coleta_correta("x")
	await process_frame
	_expect(alertas[0] == 0, "chefe não deve ser anunciado antes da metade")

	gerenciador.registrar_coleta_correta("=")
	await process_frame
	_expect(alertas[0] == 1, "chefe deve ser anunciado ao completar metade da expressão")

	var chefe_criado := [null]
	var quantidade_chefes := [0]
	spawner.balao_criado.connect(func(balao) -> void:
		if balao.eh_gigante:
			chefe_criado[0] = balao
			quantidade_chefes[0] += 1
	)
	spawner.spawnar_chefe()
	_expect(chefe_criado[0] != null and chefe_criado[0].eh_gigante, "spawn solicitado deve criar o chefe")
	spawner.spawnar_chefe()
	_expect(quantidade_chefes[0] == 1, "chefe não deve ser criado mais de uma vez")

	spawner.queue_free()
	gerenciador.queue_free()

func _test_penalidade_fatal() -> void:
	var manager = GameManagerScript.new()
	root.add_child(manager)
	manager.start_new_session(6)
	var game_overs := [0]
	manager.game_over.connect(func(_phase_id: int) -> void: game_overs[0] += 1)
	manager.register_fatal_mistake("chefe")
	manager.register_fatal_mistake("duplicado")
	_expect(manager.lives == 0, "perigo fatal deve remover todas as vidas")
	_expect(game_overs[0] == 1, "perigo fatal deve emitir game over uma única vez")
	manager.queue_free()

func _test_material_de_destaque() -> void:
	var balao = BALAO_SCENE.instantiate()
	root.add_child(balao)
	var material_original = balao.sprite.material
	balao.definir_destaque_visual(true)
	_expect(balao.sprite.material is ShaderMaterial, "destaque deve aplicar um shader temporário")
	balao.definir_intensidade_destaque(0.3)
	balao.definir_destaque_visual(false)
	_expect(balao.sprite.material == material_original, "destaque deve restaurar o material original")
	balao.free()

func _test_integracao_dos_assets() -> void:
	var balao = BALAO_SCENE.instantiate()
	var sprite_balao: Sprite2D = balao.get_node("Sprite2D")
	var label_balao: Label = balao.get_node("Label")
	_expect(sprite_balao.texture != null, "o balão final deve possuir textura")
	_expect(label_balao.get_theme_font("font") != null, "o símbolo deve possuir fonte legível")
	balao.free()

	var canhao = CANHAO_SCENE.instantiate()
	_expect(canhao.get_node("Sprite2D").texture != null, "o canhão final deve possuir textura")
	_expect(canhao.get_node("Tiro").stream != null, "o disparo deve possuir efeito sonoro")
	canhao.free()

	var efeito = EFEITO_SCENE.instantiate()
	var som_estouro: AudioStreamPlayer = efeito.get_node("Som")
	_expect(som_estouro.stream != null, "o estouro deve possuir efeito sonoro")
	_expect(AudioServer.get_bus_index(&"SFX") >= 0, "o bus SFX deve existir")
	efeito.free()

func _test_combo_quebrado_ao_estourar_simbolo_certo() -> void:
	var manager = root.get_node("GameManager")
	manager.start_new_session(6)
	var main_scene: PackedScene = load("res://scenes/fase6_sintatico/Main.tscn")
	var main = main_scene.instantiate()
	root.add_child(main)
	await process_frame
	main.spawner.pausar(true)

	manager.register_correct_action()
	manager.register_correct_action()
	manager.register_correct_action()
	var pontos_antes: int = manager.score
	var vidas_antes: int = manager.lives
	main._on_balao_estourado(main.gerenciador.proximo_esperado())

	_expect(manager.combo == 0, "estourar o símbolo que deveria cair deve quebrar o combo")
	_expect(manager.score == pontos_antes, "quebrar o combo ao estourar o símbolo certo não deve retirar pontos")
	_expect(manager.lives == vidas_antes, "estourar o símbolo certo não deve retirar vida")
	_expect(main.hud._combo_label.text == "PONTOS", "o HUD deve ocultar o combo interrompido")

	manager.register_correct_action()
	manager.register_correct_action()
	manager.register_correct_action()
	var balao_errado = BALAO_SCENE.instantiate()
	balao_errado.simbolo = "@"
	root.add_child(balao_errado)
	main._on_balao_chegou_ao_chao(balao_errado.simbolo, Vector2.ZERO, balao_errado)
	_expect(manager.combo == 0, "deixar um balão errado cair deve zerar o combo")
	_expect(main.hud._combo_label.text == "PONTOS", "o HUD deve ocultar o combo após a queda errada")
	manager.register_correct_action()
	_expect(main.hud._combo_label.text == "PONTOS", "um kill ainda não deve exibir combo")
	manager.register_correct_action()
	_expect(main.hud._combo_label.text.begins_with("COMBO 2"), "o combo deve reaparecer no segundo kill, não após quatro")
	balao_errado.queue_free()
	main.queue_free()
	await process_frame

func _test_layout_e_cliques_da_fase6() -> void:
	var hud_scene: PackedScene = load("res://scenes/common/game_hud.tscn")
	var main_scene: PackedScene = load("res://scenes/fase6_sintatico/Main.tscn")
	var tutorial_scene: PackedScene = load("res://scenes/fase6_sintatico/Tutorial.tscn")
	var hud = hud_scene.instantiate()
	root.add_child(hud)
	_expect(hud._lives_panel.position.x == 12.0, "o HUD padrão das outras fases não deve mudar")
	_expect(hud._lives_panel.size.x == 208.0, "o HUD padrão deve preservar seu tamanho original")
	hud.configure_phase6_compact_layout()
	_expect(hud._lives_panel.size.x == 190.0, "a Fase 6 deve usar um HUD compacto")
	_expect(hud._lives_panel.mouse_filter == Control.MOUSE_FILTER_IGNORE, "painéis laterais devem deixar o clique atravessar")
	_expect(hud._menu_button.mouse_filter == Control.MOUSE_FILTER_STOP, "o botão Menu deve consumir o clique")
	hud.free()

	var main = main_scene.instantiate()
	_expect(main.get_node("Canhao").position.x == 640.0, "a gameplay deve permanecer centralizada na tela")
	_expect(main.get_node("UI/PainelObjetivo").mouse_filter == Control.MOUSE_FILTER_IGNORE, "o painel de objetivo deve permitir disparos")
	_expect(main.get_node("UI/PainelControles").mouse_filter == Control.MOUSE_FILTER_IGNORE, "o painel de controles deve permitir disparos")
	main.free()

	var tutorial = tutorial_scene.instantiate()
	_expect(tutorial.get_node("Canhao").position.x == 640.0, "o tutorial deve permanecer centralizado na tela")
	_expect(tutorial.get_node("UI/Caixa").mouse_filter == Control.MOUSE_FILTER_IGNORE, "a fala do tutorial deve permitir disparos")
	_expect(tutorial.get_node("UI/Caixa/VBoxCaixa/HBoxBotoes/BotaoProximo").mouse_filter == Control.MOUSE_FILTER_STOP, "o botão Próximo deve consumir o clique")
	tutorial._gerenciador_exemplo.free()
	tutorial.free()

func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error("TESTE FASE 6: %s" % message)
