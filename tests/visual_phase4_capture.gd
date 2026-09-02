extends Node

const PHASE_SCENE := preload("res://scenes/fase4_ast/Main.tscn")

var _phase


func _ready() -> void:
	_phase = PHASE_SCENE.instantiate()
	add_child(_phase)
	await get_tree().process_frame
	_phase._start_challenge(0)
	await get_tree().process_frame

	var capture_dir := _capture_dir()
	if capture_dir.is_empty():
		_phase.hud.hide_dialog()
		_phase._begin_playing()
		return

	await _capture_evidence(capture_dir)


func _capture_dir() -> String:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			return argument.trim_prefix("--capture-dir=")
	return ""


func _capture_evidence(directory: String) -> void:
	var failures := 0
	DirAccess.make_dir_recursive_absolute(directory)

	failures += await _shot(directory, "intro_arvore.png")

	_phase.hud.hide_dialog()
	await _phase._begin_playing()
	await _place_current_token()
	await _place_current_token()
	failures += await _shot(directory, "gameplay.png")

	while not _phase.session.is_complete():
		await _place_current_token()
	_phase._on_portal_entered()
	failures += await _shot(directory, "conclusao.png")

	_phase.ambience_player.stop()
	get_tree().quit(0 if failures == 0 else 1)


func _place_current_token() -> void:
	var token: String = _phase.session.current_token
	for slot_id in _phase.active_nodes:
		if _phase.session.placed_by_slot.has(slot_id):
			continue
		if _phase.session.expected_for(slot_id) != token:
			continue
		var target = _phase.active_nodes[slot_id]
		_phase.player.global_position = target.global_position
		target.jogador_proximo = true
		_phase._try_place_current_token()
		await get_tree().process_frame
		return
	push_error("Não foi encontrado nó para o token '%s' durante a captura." % token)


func _shot(directory: String, file_name: String) -> int:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := directory.path_join(file_name)
	var error := image.save_png(path)
	if error != OK:
		push_error("Não foi possível salvar %s: erro %d" % [path, error])
		return 1
	print("Captura salva: %s" % path)
	return 0
