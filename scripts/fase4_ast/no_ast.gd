extends Area2D

var slot_id := "root"
var rotulo := "RAIZ"
var token_esperado := "+"
var preenchido := false
var jogador_proximo := false
var _temporary_color := false

@onready var slot_panel: Panel = $SlotPanel
@onready var header_panel: PanelContainer = $HeaderPanel
@onready var label_tipo: Label = $HeaderPanel/LabelTipo
@onready var label_token: Label = $LabelToken
@onready var label_interagir: Label = $LabelInteragir
@onready var feedback_timer: Timer = $FeedbackTimer

const EMPTY := Color(0.035, 0.09, 0.075, 0.94)
const HOVER := Color(0.10, 0.22, 0.16, 0.98)
const CORRECT := Color("2f9e63")
const ERROR := Color("a52a3a")
const HINT := Color("d5a72e")
const BORDER := Color("f7efc1")


func _ready() -> void:
	monitoring = true
	collision_layer = 0
	collision_mask = 1
	label_interagir.visible = false
	_update_labels()
	_apply_slot_style(EMPTY, BORDER)
	_apply_header_style()


func configure(new_slot_id: String, new_label: String, expected_token: String) -> void:
	slot_id = new_slot_id
	rotulo = new_label
	token_esperado = expected_token
	preenchido = false
	jogador_proximo = false
	if is_node_ready():
		_update_labels()
		_apply_slot_style(EMPTY, BORDER)


func is_player_nearby() -> bool:
	return jogador_proximo and not preenchido


func mark_filled(token: String, color: Color) -> void:
	preenchido = true
	_temporary_color = false
	label_token.text = token
	label_token.add_theme_color_override("font_color", Color("07111b"))
	label_interagir.visible = false
	_apply_slot_style(color, color.lightened(0.35))


func flash_error() -> void:
	if preenchido:
		return
	_temporary_color = true
	_apply_slot_style(ERROR, Color("ff9ca6"))
	feedback_timer.start(0.55)


func highlight_hint() -> void:
	if preenchido:
		return
	_temporary_color = true
	_apply_slot_style(HINT, Color("fff0a0"))
	feedback_timer.start(1.35)


func _on_body_entered(body: Node2D) -> void:
	if body.name != "Jogador" or preenchido:
		return
	jogador_proximo = true
	label_interagir.visible = true
	if not _temporary_color:
		_apply_slot_style(HOVER, Color("b9f6ca"))


func _on_body_exited(body: Node2D) -> void:
	if body.name != "Jogador":
		return
	jogador_proximo = false
	label_interagir.visible = false
	if not preenchido and not _temporary_color:
		_apply_slot_style(EMPTY, BORDER)


func _on_feedback_timer_timeout() -> void:
	_temporary_color = false
	if preenchido:
		return
	_apply_slot_style(HOVER if jogador_proximo else EMPTY, Color("b9f6ca") if jogador_proximo else BORDER)


func _update_labels() -> void:
	label_tipo.text = rotulo
	label_token.text = "?"
	label_token.add_theme_color_override("font_color", Color("f7efc1"))


func _apply_slot_style(background: Color, border: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.6)
	style.shadow_size = 6
	slot_panel.add_theme_stylebox_override("panel", style)


func _apply_header_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("4d341d")
	style.border_color = Color("17100a")
	style.set_border_width_all(3)
	style.set_corner_radius_all(5)
	header_panel.add_theme_stylebox_override("panel", style)
