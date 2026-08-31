class_name PressurePlate
extends Area2D

signal plate_pressed(plate_value: String)

@export var active_color: Color = Color(0.2, 0.8, 0.2)
@export var inactive_color: Color = Color(0.5, 0.5, 0.5)

var plate_value: String = ""
var is_pressed: bool = false

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null
@onready var color_rect: ColorRect = $ColorRect if has_node("ColorRect") else null
@onready var label: Label = $Label if has_node("Label") else null

var _default_scale: Vector2 = Vector2(3.5, 3.5)

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if anim_sprite:
		_default_scale = anim_sprite.scale
		anim_sprite.play("unpressed")
	if color_rect:
		color_rect.color = inactive_color
	if label:
		label.text = plate_value

func set_value(new_value: String) -> void:
	plate_value = new_value
	if label:
		label.text = plate_value

func set_highlight(is_highlighted: bool) -> void:
	if is_pressed and is_highlighted:
		return
		
	if label:
		if is_highlighted and not is_pressed:
			label.add_theme_color_override("font_color", Color("#2ecc71"))
			label.add_theme_color_override("font_outline_color", Color("#0e3818"))
			label.add_theme_constant_override("outline_size", 8)
		else:
			label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
			label.add_theme_color_override("font_outline_color", Color(0.04, 0.04, 0.08, 1))
			label.add_theme_constant_override("outline_size", 6)
			
	if anim_sprite:
		if is_highlighted and not is_pressed:
			anim_sprite.modulate = Color(0.65, 1.25, 0.65, 1.0)
		else:
			anim_sprite.modulate = Color(1, 1, 1, 1)

func _on_body_entered(body: Node2D) -> void:
	if not is_pressed and (body.is_in_group("player") or body.name == "Player"):
		press_plate()

func press_plate() -> void:
	if is_pressed:
		return
	is_pressed = true
	
	# Retorna imediatamente à cor original ao ser pressionada
	set_highlight(false)
	
	if anim_sprite:
		anim_sprite.modulate = Color(1, 1, 1, 1)
		anim_sprite.play("pressed")
		# Smooth punchy visual press feedback
		var tween := create_tween()
		tween.tween_property(anim_sprite, "scale", _default_scale * Vector2(1.08, 0.92), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(anim_sprite, "scale", _default_scale, 0.12).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		
	if label:
		label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		label.add_theme_color_override("font_outline_color", Color(0.04, 0.04, 0.08, 1))
		label.add_theme_constant_override("outline_size", 6)
		# Subtle pop animation on label
		var lbl_tween := create_tween()
		lbl_tween.tween_property(label, "scale", Vector2(1.15, 1.15), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		lbl_tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		
	if color_rect:
		color_rect.color = inactive_color
		
	plate_pressed.emit(plate_value)

func reset_plate() -> void:
	is_pressed = false
	set_highlight(false)
	if anim_sprite:
		anim_sprite.play("unpressed")
		anim_sprite.scale = _default_scale
		anim_sprite.modulate = Color(1, 1, 1, 1)
	if label:
		label.scale = Vector2(1.0, 1.0)
		label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		label.add_theme_color_override("font_outline_color", Color(0.04, 0.04, 0.08, 1))
		label.add_theme_constant_override("outline_size", 6)
	if color_rect:
		color_rect.color = inactive_color
