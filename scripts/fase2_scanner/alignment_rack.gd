extends Node2D

var slots: Array[Dictionary] = []


func configure(destinations: Array[Vector2], tokens: Array) -> void:
	slots.clear()
	for index in destinations.size():
		slots.append({"position": destinations[index], "label": str(index + 1), "color": ScannerData.kind_color(int(tokens[index]["kind"]))})
	queue_redraw()


func _draw() -> void:
	for slot in slots:
		var center: Vector2 = slot["position"]
		var half_width := 31.0 if slots.size() <= 5 else 21.0
		var rect := Rect2(center - Vector2(half_width, 29), Vector2(half_width * 2.0, 58))
		draw_rect(rect, Color(0.02, 0.1, 0.16, 0.56), true)
		draw_rect(rect, slot["color"], false, 3.0)
		draw_string(ThemeDB.fallback_font, center + Vector2(-4, 39), slot["label"], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("f4f7fb"))
