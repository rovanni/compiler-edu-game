extends StaticBody2D

func take_damage() -> void:
	if owner and owner.has_method("boss_take_damage"):
		owner.boss_take_damage()
	else:
		var root = get_tree().current_scene
		if root and root.has_method("boss_take_damage"):
			root.boss_take_damage()
