extends Node

const PHASE_SCENE := preload("res://scenes/fase2_scanner/main.tscn")


func _ready() -> void:
	var phase := PHASE_SCENE.instantiate()
	add_child(phase)
	await get_tree().process_frame
	if "--challenge2" in OS.get_cmdline_user_args():
		phase._load_challenge(1)
		await get_tree().process_frame
	phase.hud.hide_dialog()
	phase._start_challenge()
