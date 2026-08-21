extends SceneTree

const GerenciadorExpressaoScript := preload("res://scripts/fase6_sintatico/gerenciador_expressao.gd")
const SpawnerBaloesScript := preload("res://scripts/fase6_sintatico/spawner_baloes.gd")
const ConfigFaseScript := preload("res://scripts/fase6_sintatico/config_fase.gd")
const GameManagerScript := preload("res://scripts/autoload/game_manager.gd")
const BALAO_SCENE := preload("res://scenes/fase6_sintatico/balao.tscn")

var failures := 0

func _init() -> void:
	call_deferred("_executar")

func _executar() -> void:
	_test_progresso_da_expressao()
	await _test_gatilho_do_chefe()
	_test_penalidade_fatal()
	_test_material_de_destaque()
	await process_frame

	if failures == 0:
		print("PASS: expressão, gatilho do chefe, penalidade fatal e destaque da Fase 6")
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
	balao.queue_free()

func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error("TESTE FASE 6: %s" % message)
