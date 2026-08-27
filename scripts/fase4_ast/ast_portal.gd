extends Area2D

signal entered

const PORTAL_TEXTURE := preload("res://assets/fase4_ast/ast_portal.png")
const PORTAL_SCALE := Vector2(0.145, 0.145)
const BACKGROUND_KEY_SHADER := """
shader_type canvas_item;
render_mode unshaded;

void fragment() {
	vec4 pixel = texture(TEXTURE, UV);
	float brightest = max(pixel.r, max(pixel.g, pixel.b));
	float darkest = min(pixel.r, min(pixel.g, pixel.b));
	if (darkest > 0.90 && brightest - darkest < 0.06) {
		discard;
	}
	COLOR = pixel;
}
"""

var enabled := false
var pulse := 0.0
var collision: CollisionShape2D
var portal_sprite: Sprite2D
var portal_particles: CPUParticles2D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	_build_portal_sprite()
	_build_particles()

	collision = CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(76.0, 112.0)
	collision.position = Vector2(0.0, -7.0)
	collision.shape = shape
	add_child(collision)
	body_entered.connect(_on_body_entered)
	set_enabled(false)


func _process(delta: float) -> void:
	pulse += delta
	if portal_sprite:
		var brightness := 0.47
		if enabled:
			brightness = 0.94 + sin(pulse * 3.2) * 0.06
		portal_sprite.modulate = Color(brightness, brightness, brightness, 1.0)


func set_enabled(value: bool) -> void:
	enabled = value
	if collision:
		collision.set_deferred("disabled", not enabled)
	if portal_particles:
		portal_particles.emitting = enabled
		if enabled:
			portal_particles.restart()


func _build_portal_sprite() -> void:
	portal_sprite = Sprite2D.new()
	portal_sprite.name = "PortalSprite"
	portal_sprite.texture = PORTAL_TEXTURE
	portal_sprite.position = Vector2(0.0, -13.0)
	portal_sprite.scale = PORTAL_SCALE
	portal_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portal_sprite.z_index = 0
	var shader := Shader.new()
	shader.code = BACKGROUND_KEY_SHADER
	var material := ShaderMaterial.new()
	material.shader = shader
	portal_sprite.material = material
	add_child(portal_sprite)


func _build_particles() -> void:
	portal_particles = CPUParticles2D.new()
	portal_particles.name = "PortalParticles"
	portal_particles.position = Vector2(0.0, -34.0)
	portal_particles.z_index = 1
	portal_particles.amount = 34
	portal_particles.lifetime = 1.5
	portal_particles.randomness = 0.4
	portal_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	portal_particles.emission_rect_extents = Vector2(45.0, 55.0)
	portal_particles.direction = Vector2(0.0, -1.0)
	portal_particles.spread = 58.0
	portal_particles.gravity = Vector2(0.0, -10.0)
	portal_particles.initial_velocity_min = 8.0
	portal_particles.initial_velocity_max = 24.0
	portal_particles.scale_amount_min = 0.7
	portal_particles.scale_amount_max = 1.5
	portal_particles.color = Color(0.82, 0.28, 1.0, 0.88)
	portal_particles.emitting = false
	add_child(portal_particles)


func _on_body_entered(body: Node2D) -> void:
	if enabled and body.name == "Jogador":
		entered.emit()
