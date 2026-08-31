class_name PressurePlate
extends Area2D

signal plate_pressed(plate_value: String)

@export var active_color: Color = Color(0.2, 0.8, 0.2)
@export var inactive_color: Color = Color(0.5, 0.5, 0.5)

var plate_value: String = ""
var is_pressed: bool = false

@onready var color_rect: ColorRect = $ColorRect
@onready var label: Label = $Label

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if color_rect:
		color_rect.color = inactive_color
	if label:
		label.text = plate_value

func set_value(new_value: String) -> void:
	plate_value = new_value
	if label:
		label.text = plate_value

func _on_body_entered(body: Node2D) -> void:
	if not is_pressed and (body.is_in_group("player") or body.name == "Player"):
		press_plate()

func press_plate() -> void:
	is_pressed = true
	if color_rect:
		color_rect.color = active_color
	plate_pressed.emit(plate_value)

func reset_plate() -> void:
	is_pressed = false
	if color_rect:
		color_rect.color = inactive_color
