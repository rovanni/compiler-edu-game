extends Area2D

signal entered

var enabled := false
var pulse := 0.0
var collision: CollisionShape2D
var title_label: Label


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	collision = CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(76.0, 112.0)
	collision.position = Vector2(0.0, -7.0)
	collision.shape = shape
	add_child(collision)
	body_entered.connect(_on_body_entered)

	title_label = Label.new()
	title_label.position = Vector2(-52.0, -92.0)
	title_label.size = Vector2(104.0, 28.0)
	title_label.text = "PORTAL"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 17)
	title_label.add_theme_color_override("font_color", Color("ffe29a"))
	title_label.add_theme_color_override("font_outline_color", Color("07111b"))
	title_label.add_theme_constant_override("outline_size", 5)
	add_child(title_label)
	set_enabled(false)


func _process(delta: float) -> void:
	pulse += delta
	queue_redraw()


func set_enabled(value: bool) -> void:
	enabled = value
	if collision:
		collision.set_deferred("disabled", not enabled)
	queue_redraw()


func _draw() -> void:
	var glow_strength := 0.38 + sin(pulse * 3.0) * 0.12 if enabled else 0.08
	var portal_color := Color(0.12, 0.58, 1.0, glow_strength)

	for radius in [48.0, 42.0, 35.0]:
		var points := PackedVector2Array()
		for index in 32:
			var angle := TAU * float(index) / 32.0
			points.append(Vector2(cos(angle) * radius * 0.72, sin(angle) * radius) + Vector2(0.0, -8.0))
		draw_polyline(points, portal_color, 4.0, true)

	var stone := Color("283747")
	var stone_edge := Color("07111b")
	for side in [-1.0, 1.0]:
		for index in 5:
			var rect := Rect2(side * 44.0 - (18.0 if side < 0 else 0.0), -66.0 + index * 27.0, 18.0, 24.0)
			draw_rect(rect, stone, true)
			draw_rect(rect, stone_edge, false, 2.0)
	draw_rect(Rect2(-54.0, 57.0, 108.0, 18.0), stone, true)
	draw_rect(Rect2(-54.0, 57.0, 108.0, 18.0), stone_edge, false, 2.0)

	if not enabled:
		draw_string(ThemeDB.fallback_font, Vector2(-27.0, -3.0), "BLOQ.", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color("7890a4"))


func _on_body_entered(body: Node2D) -> void:
	if enabled and body.name == "Jogador":
		entered.emit()
