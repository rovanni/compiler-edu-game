extends Area2D

signal entered

const ARCANE_PORTAL_TEXTURE := preload("res://assets/fase2_scanner/portal_fase2_fundo_suave.png")

var enabled := false
var portal_sprite: Sprite2D
var portal_particles: CPUParticles2D

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
	portal_particles = CPUParticles2D.new()
	portal_particles.name = "PortalParticles"
	portal_particles.position = Vector2(0, -78)
	portal_particles.z_index = 1
	portal_particles.amount = 42
	portal_particles.lifetime = 1.6
	portal_particles.preprocess = 1.0
	portal_particles.randomness = 0.35
	portal_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	portal_particles.emission_rect_extents = Vector2(58, 68)
	portal_particles.direction = Vector2(0, -1)
	portal_particles.spread = 55.0
	portal_particles.gravity = Vector2(0, -12)
	portal_particles.initial_velocity_min = 8.0
	portal_particles.initial_velocity_max = 28.0
	portal_particles.scale_amount_min = 0.8
	portal_particles.scale_amount_max = 1.8
	portal_particles.color = Color(0.78, 0.22, 1.0, 0.82)
	portal_particles.emitting = true
	add_child(portal_particles)
	queue_redraw()

func set_enabled(value: bool) -> void:
	enabled = value

func _draw() -> void:
	# The visual portal is supplied by ARCANE_PORTAL_TEXTURE; collision remains this Area2D.
	pass

func _on_body_entered(body: Node2D) -> void:
	if enabled and body.is_in_group(&"player"):
		entered.emit()
