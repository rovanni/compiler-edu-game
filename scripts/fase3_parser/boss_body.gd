extends StaticBody2D

func _ready():
	var anim_sprite = get_node_or_null("AnimatedSprite2D")
	if anim_sprite:
		var boss_id = ""
		if owner and "arena_boss_id" in owner:
			boss_id = owner.arena_boss_id
			
		# Aplica o shader de remover fundo APENAS no boss final
		if boss_id == "boss_final_parser" or boss_id == "boss_final":
			var shader = load("res://scripts/fase3_parser/remove_bg.gdshader")
			var mat = ShaderMaterial.new()
			mat.shader = shader
			mat.set_shader_parameter("remove_color1", Color.BLACK)
			mat.set_shader_parameter("remove_color2", Color.BLACK)
			anim_sprite.material = mat

func take_damage() -> void:
	if owner and owner.has_method("boss_take_damage"):
		owner.boss_take_damage()
	else:
		var root = get_tree().current_scene
		if root and root.has_method("boss_take_damage"):
			root.boss_take_damage()
