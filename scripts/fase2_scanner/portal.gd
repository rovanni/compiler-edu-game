extends Area2D

signal entered

const STONE_DARK := Color("14283a")
const STONE := Color("405d75")
const STONE_LIGHT := Color("7894a9")
const CYAN := Color("31d7ff")
const BLUE := Color("2857e8")
const GOLD := Color("ffc43d")

var enabled := false
var _pulse := 0.0

func _ready() -> void:
	queue_redraw()

func _process(delta: float) -> void:
	if enabled:
		_pulse += delta * 3.0
		queue_redraw()

func set_enabled(value: bool) -> void:
	enabled = value
	queue_redraw()

func _draw() -> void:
	# Placa e pedestal mantêm a silhueta legível sem formar um retângulo maciço.
	draw_rect(Rect2(-43, -112, 86, 25), STONE_DARK, true)
	draw_rect(Rect2(-43, -112, 86, 25), STONE_LIGHT, false, 3.0)
	draw_string(ThemeDB.fallback_font, Vector2(-25, -94), "SAÍDA", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, GOLD)
	draw_rect(Rect2(-56, 11, 112, 15), STONE_DARK, true)
	draw_rect(Rect2(-56, 11, 112, 15), STONE_LIGHT, false, 3.0)
	draw_rect(Rect2(-52, -61, 18, 74), STONE, true)
	draw_rect(Rect2(34, -61, 18, 74), STONE, true)
	draw_line(Vector2(-43, -61), Vector2(-43, 12), STONE_LIGHT, 3.0)
	draw_line(Vector2(43, -61), Vector2(43, 12), STONE_LIGHT, 3.0)
	draw_arc(Vector2(0, -59), 43, PI, TAU, 32, STONE, 18.0)
	draw_arc(Vector2(0, -59), 52, PI, TAU, 32, STONE_LIGHT, 3.0)
	draw_set_transform(Vector2(0, -28), 0.0, Vector2(1.0, 1.28))
	if enabled:
		var radius := 29.0 + sin(_pulse) * 2.0
		draw_circle(Vector2.ZERO, radius + 5.0, Color(0.02, 0.08, 0.16, 0.92))
		draw_circle(Vector2.ZERO, radius, Color(0.05, 0.58, 0.95, 0.72))
		draw_arc(Vector2.ZERO, radius - 7.0, 0.0, TAU, 36, CYAN, 3.5)
		draw_arc(Vector2.ZERO, radius - 15.0, _pulse, _pulse + PI * 1.65, 28, BLUE, 4.5)
		draw_circle(Vector2(cos(_pulse) * 8.0, sin(_pulse) * 8.0), 4.0, Color.WHITE)
	else:
		draw_circle(Vector2.ZERO, 34.0, Color("071523"))
		draw_arc(Vector2.ZERO, 27.0, PI * 0.15, PI * 0.85, 20, Color("64788a"), 5.0)
		draw_rect(Rect2(-18, -3, 36, 26), Color("182b3d"), true)
		draw_rect(Rect2(-18, -3, 36, 26), STONE_LIGHT, false, 2.0)
		draw_circle(Vector2(0, 8), 4.0, GOLD)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _on_body_entered(body: Node2D) -> void:
	if enabled and body.is_in_group(&"player"):
		entered.emit()
