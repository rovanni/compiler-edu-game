extends Node

const PHASE_SCENE := preload("res://scenes/fase4_ast/Main.tscn")
var failures := 0


func _ready() -> void:
	var phase := PHASE_SCENE.instantiate()
	add_child(phase)
	await get_tree().process_frame
	phase.hud.hide_dialog()
	phase._begin_playing()

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
