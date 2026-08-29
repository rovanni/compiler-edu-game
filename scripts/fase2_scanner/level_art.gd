extends Node2D

const BRIDGE := Color("9b5a2f")
const BRIDGE_DARK := Color("4c2c21")
const TERRAIN_TEXTURE := preload("res://assets/fase1_tokens/Background2.png")

## The red-marked rectangles are the source of truth for both the drawing and
## the StaticBody2D shapes created by main.gd.
var platforms := [
	Rect2(0, 430, 210, 24), Rect2(270, 305, 205, 24),
	Rect2(580, 215, 190, 24), Rect2(834, 360, 160, 24),
	Rect2(1125, 337, 175, 24), Rect2(455, 540, 345, 80),
	# Second section: a low approach, the delivery bridge and the station.
	Rect2(1280, 540, 420, 80), Rect2(1700, 500, 190, 24),
	Rect2(2200, 500, 100, 24),
	Rect2(2200, 458, 220, 24), Rect2(2300, 535, 300, 185)
]

var visual_platforms := [
	Rect2(0, 430, 210, 55), Rect2(270, 305, 205, 70),
	Rect2(580, 215, 190, 70), Rect2(834, 360, 160, 65),
	Rect2(1125, 337, 175, 70), Rect2(455, 540, 345, 80),
	Rect2(1280, 540, 420, 80),
	Rect2(1700, 500, 190, 45), Rect2(2200, 500, 100, 45),
	Rect2(2200, 458, 220, 70), Rect2(2300, 535, 300, 185)
]

func _ready() -> void:
	z_index = -5
	queue_redraw()

func _draw() -> void:
	# Reuse the old platform artwork without bringing back its sign or flag.
	var sources := [
		Rect2(295, 420, 250, 85), Rect2(655, 285, 250, 95), Rect2(655, 285, 250, 95),
		Rect2(950, 510, 210, 65), Rect2(1305, 465, 225, 110), Rect2(540, 760, 390, 95),
		Rect2(540, 760, 390, 95), Rect2(540, 760, 390, 95), Rect2(950, 510, 210, 65),
		Rect2(1305, 465, 225, 110), Rect2(0, 760, 375, 95)
	]
	for index in visual_platforms.size():
		var platform: Rect2 = visual_platforms[index]
		var source: Rect2 = sources[min(index, sources.size() - 1)]
		_draw_platform_texture(platform, source)
	# Side rails and empty bays make it clear that the five blocks are the bridge.
	draw_line(Vector2(1888, 480), Vector2(2202, 480), BRIDGE_DARK, 7.0)
	draw_line(Vector2(1888, 480), Vector2(1888, 500), BRIDGE_DARK, 6.0)
	draw_line(Vector2(2202, 480), Vector2(2202, 500), BRIDGE_DARK, 6.0)
	for index in 5:
		var x := 1918.0 + index * 66.0
		draw_line(Vector2(x - 29, 500), Vector2(x + 29, 500), BRIDGE_DARK, 5.0)
		draw_line(Vector2(x - 29, 505), Vector2(x + 29, 521), BRIDGE, 8.0)


func _draw_platform_texture(target: Rect2, source: Rect2) -> void:
	var target_cap := minf(34.0, target.size.x / 3.0)
	var source_cap := minf(42.0, source.size.x / 3.0)
	var center_target := Rect2(target.position + Vector2(target_cap, 0), Vector2(target.size.x - target_cap * 2.0, target.size.y))
	var center_source := Rect2(source.position + Vector2(source_cap, 0), Vector2(source.size.x - source_cap * 2.0, source.size.y))
	draw_texture_rect_region(TERRAIN_TEXTURE, Rect2(target.position, Vector2(target_cap, target.size.y)), Rect2(source.position, Vector2(source_cap, source.size.y)))
	draw_texture_rect_region(TERRAIN_TEXTURE, center_target, center_source)
	draw_texture_rect_region(TERRAIN_TEXTURE, Rect2(Vector2(target.end.x - target_cap, target.position.y), Vector2(target_cap, target.size.y)), Rect2(Vector2(source.end.x - source_cap, source.position.y), Vector2(source_cap, source.size.y)))
