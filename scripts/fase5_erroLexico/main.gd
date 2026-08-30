extends Node2D


var nivel_atual := 1


var niveis := [
	"res://scenes/fase5_erroLexico/niveis/nivel1.tscn",
	"res://scenes/fase5_erroLexico/niveis/nivel2.tscn",
	"res://scenes/fase5_erroLexico/niveis/nivel3.tscn",
	"res://scenes/fase5_erroLexico/niveis/nivel4.tscn",
	"res://scenes/fase5_erroLexico/niveis/nivel5.tscn"
]


@onready var nivel_container = $NivelAtual


func _ready():

	carregar_nivel(nivel_atual)


func carregar_nivel(numero_nivel: int):


	for filho in nivel_container.get_children():

		filho.queue_free()


	var cena_nivel = load(
		niveis[numero_nivel - 1]
	)


	var novo_nivel = cena_nivel.instantiate()


	nivel_container.add_child(novo_nivel)


	novo_nivel.nivel_concluido.connect(
		proximo_nivel
	)


func proximo_nivel():

	if nivel_atual < 5:

		nivel_atual += 1

		carregar_nivel(nivel_atual)

	else:

		abrir_conclusao()


func abrir_conclusao():

	get_tree().change_scene_to_file(
		"res://scenes/fase5_erroLexico/conclusao.tscn"
	)
