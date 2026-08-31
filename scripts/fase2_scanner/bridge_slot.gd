@tool
extends Node2D

@export var slot_index := 0
@export var slot_size := Vector2(140, 28)
@export var art_scale := Vector2(0.15, 0.075):
	set(value):
		art_scale = value
		var bridge_visual := get_node_or_null("Visual") as Sprite2D
		if bridge_visual:
			bridge_visual.scale = art_scale
@export var active := false:
	set(value):
		active = value
		_refresh()

@onready var visual: Sprite2D = $Visual
@onready var collision: CollisionPolygon2D = $StaticBody2D/CollisionPolygon2D
@onready var collision_shape: CollisionShape2D = $StaticBody2D/CollisionShape2D

func _ready() -> void:
	_configure_region()
	visual.scale = art_scale
	_refresh()

func set_active(value: bool) -> void:
	active = value

func _refresh() -> void:
	if not is_inside_tree():
		return
	if Engine.is_editor_hint():
		# A ponte permanece visível e selecionável no editor para posicionar a
		# arte e editar/adicionar CollisionPolygon2D. No jogo ela começa oculta.
		if visual:
			visual.visible = true
		if collision:
			collision.disabled = true
		if collision_shape:
			collision_shape.disabled = true
		return
	if visual:
		_configure_region()
		visual.visible = active
	if collision:
		# Esta é a colisão editável da própria ponte; fica ativa apenas após
		# a entrega completa da sequência de blocos.
		collision.disabled = not active
	if collision_shape:
		# Forma sólida de segurança: garante uma faixa caminhável contínua.
		collision_shape.disabled = not active

func _configure_region() -> void:
	if visual == null or visual.texture == null:
		return
	var texture_size := visual.texture.get_size()
	visual.region_enabled = true
	visual.region_rect = Rect2(texture_size.x * slot_index / 5.0, 0.0, texture_size.x / 5.0, texture_size.y)
