extends Node

const PHASE_SCENE := preload("res://scenes/fase2_scanner/main.tscn")

var _phase


func _ready() -> void:
	_phase = PHASE_SCENE.instantiate()
	add_child(_phase)
	await get_tree().process_frame
	if "--challenge2" in OS.get_cmdline_user_args():
		_phase._load_challenge(1)
		await get_tree().process_frame

	var capture_dir := _capture_dir()
	if capture_dir.is_empty():
		# Modo original: apenas abre a fase para inspeção visual manual.
		_phase.hud.hide_dialog()
		_phase._start_challenge()
		return

	await _capture_evidence(capture_dir)


func _capture_dir() -> String:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			return argument.trim_prefix("--capture-dir=")
	return ""


# Percorre os estados visuais da fase e salva uma imagem de cada um, para
# compor as evidências AEX (docs/evidencias_fase2.md).
func _capture_evidence(directory: String) -> void:
	var failures := 0
	DirAccess.make_dir_recursive_absolute(directory)

	failures += await _shot(directory, "fase2_intro.png")

	_phase.hud.hide_dialog()
	_phase._start_challenge()
	await get_tree().create_timer(1.0).timeout
	failures += await _shot(directory, "fase2_vale.png")

	var block = _first_free_block()
	if block:
		block.pick_up(_phase.player)
		failures += await _shot(directory, "fase2_carregando.png")
		block.drop(_phase.block_container, block.global_position)

	# A câmera padrão segue o jogador, que fica no portal de entrada; os
	# encaixes ficam no centro do mapa e não apareceriam no quadro.
	var slots := _bridge_slot_count()
	if slots > 0:
		var bridge_camera := Camera2D.new()
		add_child(bridge_camera)
		bridge_camera.global_position = _phase._bridge_target_position() + Vector2(0, 80)
		bridge_camera.make_current()

		# Apenas o primeiro encaixe: deixa o vão bem visível, em contraste
		# claro com a captura da ponte completa.
		_phase.bridge_progress.activate_slot(0)
		failures += await _shot(directory, "fase2_ponte_parcial.png")

		for index in range(1, slots):
			_phase.bridge_progress.activate_slot(index)
		failures += await _shot(directory, "fase2_ponte_completa.png")

		bridge_camera.queue_free()
		_phase.camera.make_current()
		await get_tree().process_frame

	# Usa a conclusão real da fase, para que a evidência mostre os bônus e o
	# texto didático efetivamente exibidos ao jogador.
	_phase._complete_phase()
	failures += await _shot(directory, "fase2_conclusao.png")

	get_tree().quit(0 if failures == 0 else 1)


func _shot(directory: String, file_name: String) -> int:
	# Duas esperas garantem que o quadro já foi desenhado antes da leitura.
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


func _first_free_block():
	for block in _phase.spawned_blocks:
		if is_instance_valid(block) and not block.is_placed:
			return block
	return null


func _bridge_slot_count() -> int:
	if _phase.bridge_progress == null:
		return 0
	return _phase.bridge_progress.get_children().filter(func(node): return node.has_method("set_active")).size()
