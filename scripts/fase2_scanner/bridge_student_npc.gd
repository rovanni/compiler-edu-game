extends Area2D

@onready var speech_bubble: PanelContainer = $SpeechBubble


func _ready() -> void:
	speech_bubble.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		speech_bubble.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		speech_bubble.visible = false
