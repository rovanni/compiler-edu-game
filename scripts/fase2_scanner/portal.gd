extends Area2D

signal entered

const ARCANE_PORTAL_TEXTURE := preload("res://assets/fase2_scanner/portal_fase2_fundo_suave.png")

var enabled := false
var portal_sprite: Sprite2D

func set_label(value: String) -> void:
	# Mantido para compatibilidade com o controlador da fase; a arte já contém
	# toda a arte do portal e não recebe placas ou desenhos adicionais.
	pass

func _ready() -> void:
	portal_sprite = Sprite2D.new()
	portal_sprite.texture = ARCANE_PORTAL_TEXTURE
	# A base da arte fica nivelada com o chão do portal.
	portal_sprite.position = Vector2(0, -57)
	portal_sprite.scale = Vector2(0.2, 0.2)
	portal_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portal_sprite.z_index = 0
	add_child(portal_sprite)
	queue_redraw()

func set_enabled(value: bool) -> void:
	enabled = value

func _draw() -> void:
	# The visual portal is supplied by ARCANE_PORTAL_TEXTURE; collision remains this Area2D.
	pass

func _on_body_entered(body: Node2D) -> void:
	if enabled and body.is_in_group(&"player"):
		entered.emit()
