extends Area2D
class_name ProjetilFase6

@export var velocidade: float = 720.0

var _consumido := false

func _ready() -> void:
	add_to_group(&"projeteis_fase6")
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	position.y -= velocidade * delta
	if global_position.y < -30.0:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if _consumido or not area is Balao:
		return
	_consumido = true
	area.estourar()
	queue_free()
