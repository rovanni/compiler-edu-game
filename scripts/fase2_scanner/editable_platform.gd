@tool
extends StaticBody2D

## Plataforma editável no editor 2D. O nó é posicionado pelo centro do retângulo;
## altere platform_size/visual_size no Inspector para remodelar o trecho.
@export var platform_size: Vector2 = Vector2(200, 24):
	set(value):
		platform_size = value
		_refresh()
@export var visual_size: Vector2 = Vector2(200, 70):
	set(value):
		visual_size = value
		_refresh()
@export var texture_region := Rect2(295, 420, 250, 85):
	set(value):
		texture_region = value
		queue_redraw()
@export var draw_texture := true

const TERRAIN_TEXTURE := preload("res://assets/fase1_tokens/Background2.png")
const SOIL := Color("704022")
const GRASS := Color("65c53a")

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	_refresh()

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		_refresh()

func _refresh() -> void:
	if not is_inside_tree():
		return
	if collision_shape == null:
		collision_shape = get_node_or_null("CollisionShape2D")
	if collision_shape:
		var shape := collision_shape.shape as RectangleShape2D
		if shape == null:
			shape = RectangleShape2D.new()
			collision_shape.shape = shape
		shape.size = platform_size
		collision_shape.position = Vector2.ZERO
	queue_redraw()

func _draw() -> void:
	var visual_rect := Rect2(-visual_size * 0.5, visual_size)
	draw_rect(visual_rect, SOIL, true)
	draw_rect(Rect2(visual_rect.position, Vector2(visual_rect.size.x, 10.0)), GRASS, true)
	if not draw_texture or TERRAIN_TEXTURE == null or texture_region.size.x <= 0.0:
		return
	var top_h := minf(visual_size.y, texture_region.size.y)
	var left_w := minf(visual_size.x * 0.18, texture_region.size.x * 0.22)
	var right_w := left_w
	var center_w := maxf(0.0, visual_size.x - left_w - right_w)
	var dest_y := visual_rect.position.y
	var dest_h := visual_size.y
	draw_texture_rect_region(TERRAIN_TEXTURE, Rect2(visual_rect.position.x, dest_y, left_w, dest_h), Rect2(texture_region.position, Vector2(texture_region.size.x * 0.22, texture_region.size.y)))
	draw_texture_rect_region(TERRAIN_TEXTURE, Rect2(visual_rect.position.x + left_w, dest_y, center_w, dest_h), Rect2(texture_region.position + Vector2(texture_region.size.x * 0.22, 0), Vector2(maxf(1.0, texture_region.size.x * 0.56), texture_region.size.y)))
	draw_texture_rect_region(TERRAIN_TEXTURE, Rect2(visual_rect.end.x - right_w, dest_y, right_w, dest_h), Rect2(texture_region.end - Vector2(texture_region.size.x * 0.22, texture_region.size.y), Vector2(texture_region.size.x * 0.22, texture_region.size.y)))
