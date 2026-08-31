extends Node

const PHASE_SCENE := preload("res://scenes/fase4_ast/Main.tscn")


func _ready() -> void:
	var phase := PHASE_SCENE.instantiate()
	add_child(phase)
	await get_tree().process_frame
	phase._start_challenge(0)
	await get_tree().process_frame
	phase.hud.hide_dialog()
	phase._begin_playing()
	await get_tree().process_frame
	await get_tree().process_frame

	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture="):
			var capture_path := argument.trim_prefix("--capture=")
			var image := get_viewport().get_texture().get_image()
			var error := image.save_png(capture_path)
			if error != OK:
				push_error("Não foi possível salvar a captura da Fase 4: %s" % error)
			get_tree().quit(0 if error == OK else 1)
			return
