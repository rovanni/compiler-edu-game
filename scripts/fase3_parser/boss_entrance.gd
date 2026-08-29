class_name BossEntrance
extends Area2D

signal player_entered(entrance: BossEntrance)
signal player_exited(entrance: BossEntrance)

@export var boss_name: String = "Boss 1"
@export var boss_id: String = "boss_1"
@export var is_final_boss: bool = false
@export var accent_color: Color = Color(0.9, 0.3, 0.2, 0.8)
@export var bg_path: String = ""
@export_file("*.tscn") var arena_scene_path: String = ""

@onready var label: Label = $Label
@onready var pad_rect: ColorRect = $PadRect

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	if label:
		label.text = boss_name.to_upper()
	if pad_rect:
		pad_rect.color = accent_color
		
	_setup_portal_animation()

func _setup_portal_animation() -> void:
	var anim_sprite = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if not anim_sprite:
		anim_sprite = get_node_or_null("PortalAnim") as AnimatedSprite2D
		
	if anim_sprite and anim_sprite.sprite_frames:
		if pad_rect:
			pad_rect.visible = false
		if not anim_sprite.is_playing():
			anim_sprite.play()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		player_entered.emit(self)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		player_exited.emit(self)
