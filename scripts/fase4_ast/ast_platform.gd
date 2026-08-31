extends StaticBody2D

var platform_size := Vector2(180.0, 28.0)
var platform_one_way := true


func configure(new_size: Vector2, one_way: bool = true) -> void:
	platform_size = new_size
	platform_one_way = one_way
	queue_redraw()


func _ready() -> void:
	collision_layer = 1
	collision_mask = 1
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = platform_size
	collision.shape = shape
	collision.one_way_collision = platform_one_way
	collision.one_way_collision_margin = 12.0
	add_child(collision)
	queue_redraw()


func _draw() -> void:
	var half := platform_size * 0.5
	var body_rect := Rect2(-half.x, -half.y, platform_size.x, platform_size.y)
	draw_rect(body_rect, Color("162534"), true)
	draw_rect(body_rect, Color("07111b"), false, 3.0)

	# Grama em camadas, no mesmo verde musgoso da floresta. A base continua
	# alinhada com o topo físico da plataforma para não criar colisão invisível.
	var grass_dark := Color("244d27")
	var grass_mid := Color("3f7732")
	var grass_light := Color("6e9b3f")
	draw_rect(Rect2(-half.x, -half.y - 7.0, platform_size.x, 10.0), grass_dark, true)
	draw_rect(Rect2(-half.x, -half.y - 9.0, platform_size.x, 6.0), grass_mid, true)
	draw_line(Vector2(-half.x, -half.y - 8.0), Vector2(half.x, -half.y - 8.0), grass_light, 2.0)

	var grass_start := int(-half.x) + 3
	var grass_end := int(half.x) - 2
	for blade_x in range(grass_start, grass_end, 7):
		var pattern := posmod(blade_x, 4)
		var blade_height := 6.0 + float(pattern) * 2.0
		var lean := -3.0 if posmod(blade_x, 3) == 0 else (3.0 if posmod(blade_x, 3) == 1 else 0.0)
		draw_line(
			Vector2(blade_x, -half.y - 7.0),
			Vector2(blade_x + lean, -half.y - 7.0 - blade_height),
			grass_light if pattern == 0 else grass_mid,
			2.0,
			true
		)

	# Pequenos tufos pendentes quebram a aparência de uma faixa reta.
	for tuft_x in range(grass_start + 9, grass_end, 29):
		draw_line(Vector2(tuft_x, -half.y + 1.0), Vector2(tuft_x - 2.0, -half.y + 8.0), grass_dark, 2.0)
		draw_line(Vector2(tuft_x + 3.0, -half.y + 1.0), Vector2(tuft_x + 5.0, -half.y + 6.0), grass_mid, 2.0)

	var first_seam := int(-half.x) + 22
	var last_seam := int(half.x) - 8
	for seam_x in range(first_seam, last_seam, 34):
		draw_line(Vector2(seam_x, -half.y + 7.0), Vector2(seam_x - 5.0, half.y - 3.0), Color("30475a"), 2.0)

	# Pequenas raízes/pedras dão volume sem alterar a área física.
	var underside := PackedVector2Array([
		Vector2(-half.x + 14.0, half.y),
		Vector2(-half.x + 30.0, half.y + 10.0),
		Vector2(half.x - 30.0, half.y + 10.0),
		Vector2(half.x - 14.0, half.y),
	])
	draw_colored_polygon(underside, Color("0c1722"))
