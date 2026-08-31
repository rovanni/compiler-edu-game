extends Area2D

signal touched(token: Area2D)
var token_data: Dictionary = {}
var collected := false
var _base_scale := Vector2.ONE
var _highlight_tween: Tween
@onready var sprite: Sprite2D = $Sprite2D
@onready var lexeme_label: Label = $Lexeme
@onready var kind_label: Label = $Kind

func _ready() -> void:
	_base_scale = scale

func configure(data: Dictionary) -> void:
	token_data = data.duplicate(true)
	var lexeme := str(token_data.get("lexeme", "?"))
	lexeme_label.text = lexeme
	lexeme_label.add_theme_font_size_override("font_size", 16 if lexeme.length() >= 5 else (19 if lexeme.length() >= 3 else 22))
	kind_label.text = ScannerData.kind_short(int(token_data.get("kind", -1)))
	var color := ScannerData.kind_color(int(token_data.get("kind", -1)))
	sprite.self_modulate = color
	kind_label.add_theme_color_override("font_color", Color("071523"))
	var badge := StyleBoxFlat.new()
	badge.bg_color = color.lightened(0.16)
	badge.border_color = Color("071523")
	badge.set_border_width_all(2)
	badge.set_corner_radius_all(3)
	badge.content_margin_left = 4
	badge.content_margin_right = 4
	kind_label.add_theme_stylebox_override("normal", badge)
	lexeme_label.add_theme_color_override("font_outline_color", Color("071523"))
	lexeme_label.add_theme_constant_override("outline_size", 4)

func collect() -> void:
	if collected: return
	collected = true
	hide()
	set_deferred("monitoring", false)

func restore() -> void:
	collected = false
	show()
	set_deferred("monitoring", true)
	scale = _base_scale

func highlight(duration: float = 3.0) -> void:
	if collected: return
	if _highlight_tween and _highlight_tween.is_valid(): _highlight_tween.kill()
	_highlight_tween = create_tween()
	_highlight_tween.set_loops(maxi(int(duration / 0.4), 1))
	_highlight_tween.tween_property(self, "scale", _base_scale * 1.18, 0.2)
	_highlight_tween.tween_property(self, "scale", _base_scale, 0.2)

func _on_body_entered(body: Node2D) -> void:
	if not collected and body.is_in_group(&"player"):
		touched.emit(self)
