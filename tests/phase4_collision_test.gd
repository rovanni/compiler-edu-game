extends Node

const PHASE_SCENE := preload("res://scenes/fase4_ast/Main.tscn")
var failures := 0


func _ready() -> void:
	var phase := PHASE_SCENE.instantiate()
	add_child(phase)
	await get_tree().process_frame
	phase.hud.hide_dialog()
	await phase._begin_playing()
	_expect(phase.entry_portal != null, "a entrada deve usar um portal próprio")
	_expect(phase.entry_portal.enabled, "o portal de entrada deve permanecer ativo")
	_expect(phase.entry_portal.portal_sprite.texture == phase.portal.portal_sprite.texture, "os portais de entrada e saída devem usar a mesma arte")
	_expect(phase.player.controls_enabled, "os controles devem ser liberados após a animação de entrada")
	_expect(phase.player.global_position.distance_to(phase.player.spawn_position) < 1.0, "a animação deve terminar no ponto inicial")

	var landing_surfaces := [
		{"name": "início", "x": 115.0, "top": 570.0},
		{"name": "folha esquerda", "x": 320.0, "top": 528.0},
		{"name": "folha central", "x": 500.0, "top": 528.0},
		{"name": "filho esquerdo", "x": 420.0, "top": 372.0},
		{"name": "filho direito", "x": 840.0, "top": 372.0},
		{"name": "raiz", "x": 640.0, "top": 216.0},
		{"name": "portal", "x": 1170.0, "top": 570.0},
	]

	for surface in landing_surfaces:
		phase.player.global_position = Vector2(surface["x"], surface["top"] - 90.0)
		phase.player.velocity = Vector2.ZERO
		phase.player._fall_reported = false
		for frame in 45:
			await get_tree().physics_frame
		_expect(phase.player.is_on_floor(), "jogador deve pousar na plataforma %s" % surface["name"])
		_expect(absf(phase.player.global_position.y - (surface["top"] - 40.0)) < 2.5, "colisão visual deve coincidir com o topo de %s" % surface["name"])

	for gap_x in [410.0, 870.0]:
		phase.player.global_position = Vector2(gap_x, 450.0)
		phase.player.velocity = Vector2.ZERO
		phase.player._fall_reported = false
		for frame in 35:
			await get_tree().physics_frame
		_expect(not phase.player.is_on_floor(), "o vão em x=%d deve permitir a queda do jogador" % int(gap_x))

	phase.player.global_position = Vector2(320.0, 488.0)
	phase.player.velocity = Vector2.ZERO
	for frame in 10:
		await get_tree().physics_frame
	_expect(phase.player.is_on_floor(), "jogador deve pousar antes do teste de descida")
	Input.action_press(&"drop_down")
	await get_tree().physics_frame
	Input.action_release(&"drop_down")
	for frame in 12:
		await get_tree().physics_frame
	_expect(not phase.player.is_on_floor(), "seta para baixo deve atravessar a plataforma semissólida")
	_expect(phase.player.global_position.y > 500.0, "jogador deve se deslocar para baixo ao atravessar a plataforma")

	if failures == 0:
		print("PASS: colisões e pousos da Fase 4")
		get_tree().quit(0)
	else:
		push_error("FAIL: %d teste(s) de colisão da Fase 4" % failures)
		get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error("TESTE COLISÃO: %s" % message)
