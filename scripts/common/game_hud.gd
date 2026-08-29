extends CanvasLayer

signal pause_requested
signal resume_requested
signal intro_confirmed
signal menu_confirmed
signal hint_requested
signal objective_requested
signal retry_requested
signal next_requested
signal replay_requested

const GAME_FONT := preload("res://fonts/Friend Bestie.otf")
const INK := Color("06111d")
const PANEL := Color("081827")
const PANEL_2 := Color("10283b")
const BORDER := Color("5f7890")
const GOLD := Color("ffc43d")
const TEXT := Color("f4f7fb")
const MUTED := Color("a9bac9")
const RED := Color("ff5252")

var _root: Control
var _hearts_label: Label
var _lives_label: Label
var _score_label: Label
var _combo_label: Label
var _title_label: Label
var _subtitle_label: Label
var _lives_panel: PanelContainer
var _points_panel: PanelContainer
var _title_panel: PanelContainer
var _timer_panel: PanelContainer
var _timer_label: Label
var _menu_button: Button
var _scanner_root: Control
var _objective_summary: Label
var _code_label: RichTextLabel
var _slots: HBoxContainer
var _footer_root: Control
var _feedback_label: Label
var _progress_label: Label
var _overlay: ColorRect
var _dialog_title: Label
var _dialog_body: RichTextLabel
var _dialog_buttons: HBoxContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_interface()
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.lives_changed.connect(_on_lives_changed)
	GameManager.combo_changed.connect(_on_combo_changed)
	_on_score_changed(GameManager.score, 0)
	_on_lives_changed(GameManager.lives, GameManager.MAX_LIVES)
	_on_combo_changed(GameManager.combo, 0)


func configure_phase(title: String, subtitle: String, show_timer: bool = false) -> void:
	_title_label.text = title
	_subtitle_label.text = subtitle
	_timer_panel.visible = show_timer


## Layout compacto usado somente pela Fase 6. Distribui o HUD de forma
## simétrica sem reduzir a área jogável. Painéis decorativos deixam o clique
## chegar ao canhão; apenas botões continuam consumindo eventos do mouse.
func configure_phase6_compact_layout() -> void:
	_set_anchors(_title_panel, 0.0, 0.0, 0.0, 0.0, Rect2(370, 10, 540, 64))
	_set_anchors(_lives_panel, 0.0, 0.0, 0.0, 0.0, Rect2(12, 10, 190, 64))
	_set_anchors(_points_panel, 0.0, 0.0, 0.0, 0.0, Rect2(212, 10, 140, 64))
	_set_anchors(_menu_button, 0.0, 0.0, 0.0, 0.0, Rect2(1178, 10, 90, 64))
	_title_label.add_theme_font_size_override("font_size", 25)
	_subtitle_label.add_theme_font_size_override("font_size", 12)
	_menu_button.text = "⚙\nMENU"
	_timer_panel.hide()
	for child in _root.get_children():
		if child != _overlay:
			_habilitar_clique_atraves(child)


func configure_scanner(code_bbcode: String, slot_count: int, progress_text: String) -> void:
	_scanner_root.visible = true
	_footer_root.visible = true
	_code_label.text = code_bbcode
	set_progress(progress_text)
	_objective_summary.text = "O Scanner separou os tokens.\nColete %d na ordem do código." % slot_count
	_clear_slots()
	var slot_width := 60.0 if slot_count <= 5 else 47.0
	_slots.add_theme_constant_override("separation", 8 if slot_count <= 5 else 5)
	for index in slot_count:
		var slot := Label.new()
		slot.custom_minimum_size = Vector2(slot_width, 32)
		slot.text = str(index + 1)
		slot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		slot.add_theme_font_size_override("font_size", 15)
		slot.add_theme_color_override("font_color", MUTED)
		slot.add_theme_stylebox_override("normal", _style(Color("0b1c2b"), BORDER, 2, 5))
		_slots.add_child(slot)


func hide_scanner_interface() -> void:
	_scanner_root.visible = false
	_footer_root.visible = false


func set_slot(index: int, lexeme: String, kind_short: String, color: Color) -> void:
	if index < 0 or index >= _slots.get_child_count():
		return
	var slot := _slots.get_child(index) as Label
	var slot_size := slot.custom_minimum_size
	slot_size.x = maxf(slot_size.x, 44.0 + lexeme.length() * 4.0)
	slot.custom_minimum_size = slot_size
	slot.text = "%s\n%s" % [lexeme, kind_short]
	slot.add_theme_font_size_override("font_size", 12)
	slot.add_theme_color_override("font_color", INK)
	slot.add_theme_stylebox_override("normal", _style(color, color.lightened(0.25), 2, 5))


func set_progress(text: String) -> void:
	_progress_label.text = text.replace("  •  ", "\n")


func set_timer(seconds: float) -> void:
	var total := maxi(int(ceil(seconds)), 0)
	_timer_label.text = "%02d:%02d" % [total / 60, total % 60]
	_timer_label.add_theme_color_override("font_color", RED if total <= 10 else TEXT)


func set_feedback(text: String, color: Color = TEXT) -> void:
	_feedback_label.text = text
	_feedback_label.add_theme_color_override("font_color", color)


func show_intro(title: String, body_bbcode: String) -> void:
	_show_dialog(title, body_bbcode, [{"text": "COMEÇAR", "action": "intro"}])


func show_objective(title: String, body_bbcode: String) -> void:
	_show_dialog(title, body_bbcode, [{"text": "VOLTAR AO JOGO", "action": "resume"}])


func show_pause() -> void:
	_show_dialog("JOGO PAUSADO", "O mundo do jogo está pausado.", [
		{"text": "CONTINUAR", "action": "resume"},
		{"text": "VOLTAR AO MENU", "action": "ask_menu"},
	])


func show_game_over(body_bbcode: String = "Revise a estratégia e tente novamente. Os pontos provisórios desta fase serão removidos.") -> void:
	_show_dialog("SEM VIDAS", body_bbcode, [
		{"text": "TENTAR NOVAMENTE", "action": "retry"},
		{"text": "VOLTAR AO MENU", "action": "ask_menu"},
	])


func show_completion(title: String, body_bbcode: String, has_next: bool) -> void:
	var buttons: Array[Dictionary] = []
	buttons.append({"text": "PRÓXIMA FASE" if has_next else "JOGAR NOVAMENTE", "action": "next" if has_next else "replay"})
	buttons.append({"text": "VOLTAR AO MENU", "action": "menu"})
	_show_dialog(title, body_bbcode, buttons)


func hide_dialog() -> void:
	_overlay.visible = false


func is_dialog_visible() -> bool:
	return _overlay.visible


func _build_interface() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var theme := Theme.new()
	theme.default_font = GAME_FONT
	theme.default_font_size = 16
	_root.theme = theme
	add_child(_root)
	_build_top_bar()
	_build_scanner_row()
	_build_footer()
	_build_dialog()


func _build_top_bar() -> void:
	_lives_panel = _panel(_root, "LivesPanel", 0.0, 0.0, 0.0, 0.0, Rect2(12, 10, 208, 72))
	var lives_box := VBoxContainer.new()
	lives_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_lives_panel.add_child(lives_box)
	_hearts_label = _label("♥  ♥  ♥", 24, RED)
	_hearts_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lives_label = _label("VIDAS × 3", 15, TEXT)
	_lives_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lives_box.add_child(_hearts_label)
	lives_box.add_child(_lives_label)

	_points_panel = _panel(_root, "PointsPanel", 0.0, 0.0, 0.0, 0.0, Rect2(230, 10, 132, 72))
	var points_box := VBoxContainer.new()
	points_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_points_panel.add_child(points_box)
	_score_label = _label("★  0", 20, GOLD)
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_combo_label = _label("", 12, Color("7dd3fc"))
	_combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	points_box.add_child(_score_label)
	points_box.add_child(_combo_label)

	_title_panel = _panel(_root, "TitlePanel", 0.0, 0.0, 0.0, 0.0, Rect2(372, 10, 530, 72))
	var title_box := VBoxContainer.new()
	title_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_title_panel.add_child(title_box)
	_title_label = _label("FASE 2 - SCANNER", 28, GOLD)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle_label = _label("ORGANIZE OS TOKENS NA ORDEM CORRETA", 14, TEXT)
	_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_box.add_child(_title_label)
	title_box.add_child(_subtitle_label)

	_timer_panel = _panel(_root, "TimerPanel", 0.0, 0.0, 0.0, 0.0, Rect2(912, 10, 154, 72))
	var timer_box := VBoxContainer.new()
	timer_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_timer_panel.add_child(timer_box)
	var timer_heading := _label("TEMPO", 13, GOLD)
	timer_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer_label = _label("02:00", 26, TEXT)
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_box.add_child(timer_heading)
	timer_box.add_child(_timer_label)

	_menu_button = _button("⚙\nMENU", 16)
	_set_anchors(_menu_button, 1.0, 0.0, 1.0, 0.0, Rect2(-102, 10, 90, 72))
	_menu_button.pressed.connect(func() -> void: pause_requested.emit())
	_root.add_child(_menu_button)


func _build_scanner_row() -> void:
	_scanner_root = Control.new()
	_scanner_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_scanner_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_scanner_root)

	var objective_panel := _panel(_scanner_root, "ObjectivePanel", 0.0, 0.0, 0.0, 0.0, Rect2(12, 92, 250, 92))
	var objective_box := VBoxContainer.new()
	objective_panel.add_child(objective_box)
	var objective_heading := _label("OBJETIVO", 16, GOLD)
	_objective_summary = _label("Colete os tokens na ordem do código.", 13, TEXT)
	_objective_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_box.add_child(objective_heading)
	objective_box.add_child(_objective_summary)

	var order_panel := _panel(_scanner_root, "OrderPanel", 0.0, 0.0, 0.0, 0.0, Rect2(272, 92, 596, 92))
	var order_box := VBoxContainer.new()
	order_box.add_theme_constant_override("separation", 4)
	order_panel.add_child(order_box)
	var order_heading := _label("ORDEM CORRETA", 16, GOLD)
	order_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	order_box.add_child(order_heading)
	_slots = HBoxContainer.new()
	_slots.alignment = BoxContainer.ALIGNMENT_CENTER
	order_box.add_child(_slots)

	var code_panel := _panel(_scanner_root, "CodePanel", 1.0, 0.0, 1.0, 0.0, Rect2(-400, 92, 388, 92))
	_code_label = RichTextLabel.new()
	_code_label.bbcode_enabled = true
	_code_label.fit_content = false
	_code_label.scroll_active = false
	_code_label.add_theme_font_size_override("normal_font_size", 19)
	_code_label.add_theme_color_override("default_color", TEXT)
	code_panel.add_child(_code_label)
	_scanner_root.visible = false


func _build_footer() -> void:
	_footer_root = Control.new()
	_set_anchors(_footer_root, 0.0, 1.0, 1.0, 1.0, Rect2(12, -66, -24, 56))
	_root.add_child(_footer_root)
	var controls_panel := _panel(_footer_root, "Controls", 0.0, 0.0, 0.0, 1.0, Rect2(0, 0, 225, 0))
	var controls := _label("A / D ou SETAS  -  MOVER\nW / ESPAÇO  -  PULAR", 13, TEXT)
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	controls_panel.add_child(controls)

	var feedback_panel := _panel(_footer_root, "Feedback", 0.0, 0.0, 1.0, 1.0, Rect2(237, 0, -534, 0))
	var feedback_box := HBoxContainer.new()
	feedback_box.add_theme_constant_override("separation", 7)
	feedback_panel.add_child(feedback_box)
	var scanner_face := _label("[•‿•]", 18, Color("60a5fa"))
	scanner_face.custom_minimum_size = Vector2(58, 0)
	scanner_face.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	feedback_box.add_child(scanner_face)
	_feedback_label = _label("O Scanner lê o código da esquerda para a direita.", 13, TEXT)
	_feedback_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_feedback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	feedback_box.add_child(_feedback_label)
	var objective_button := _button("OBJETIVO", 11)
	objective_button.custom_minimum_size = Vector2(78, 0)
	objective_button.pressed.connect(func() -> void: objective_requested.emit())
	feedback_box.add_child(objective_button)
	var hint_button := _button("DICA -5", 11)
	hint_button.custom_minimum_size = Vector2(68, 0)
	hint_button.pressed.connect(func() -> void: hint_requested.emit())
	feedback_box.add_child(hint_button)

	var progress_panel := _panel(_footer_root, "Progress", 1.0, 0.0, 1.0, 1.0, Rect2(-285, 0, 285, 0))
	_progress_label = _label("FASE 2/6\nDESAFIO 1/2\nTOKENS 0/5", 13, GOLD)
	_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_progress_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	progress_panel.add_child(_progress_label)
	_footer_root.visible = false


func _build_dialog() -> void:
	_overlay = ColorRect.new()
	_overlay.color = Color(0.01, 0.03, 0.06, 0.9)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.visible = false
	_root.add_child(_overlay)
	var dialog_panel := _panel(_overlay, "DialogPanel", 0.5, 0.5, 0.5, 0.5, Rect2(-330, -215, 660, 430))
	var dialog_box := VBoxContainer.new()
	dialog_box.add_theme_constant_override("separation", 14)
	dialog_panel.add_child(dialog_box)
	_dialog_title = _label("TÍTULO", 28, GOLD)
	_dialog_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialog_box.add_child(_dialog_title)
	_dialog_body = RichTextLabel.new()
	_dialog_body.custom_minimum_size = Vector2(610, 285)
	_dialog_body.bbcode_enabled = true
	_dialog_body.scroll_active = true
	_dialog_body.add_theme_font_size_override("normal_font_size", 17)
	_dialog_body.add_theme_color_override("default_color", TEXT)
	dialog_box.add_child(_dialog_body)
	_dialog_buttons = HBoxContainer.new()
	_dialog_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	_dialog_buttons.add_theme_constant_override("separation", 12)
	dialog_box.add_child(_dialog_buttons)


func _show_dialog(title: String, body_bbcode: String, buttons: Array[Dictionary]) -> void:
	_dialog_title.text = title
	_dialog_body.text = body_bbcode
	for child in _dialog_buttons.get_children():
		_dialog_buttons.remove_child(child)
		child.queue_free()
	var primeiro_botao: Button = null
	for definition in buttons:
		var button := _button(str(definition.get("text", "OK")), 15)
		button.custom_minimum_size = Vector2(160, 42)
		button.pressed.connect(_on_dialog_action.bind(str(definition.get("action", "resume"))))
		_dialog_buttons.add_child(button)
		if primeiro_botao == null:
			primeiro_botao = button
	_overlay.visible = true
	# Todos os diálogos compartilhados podem ser operados só com teclado:
	# Enter ativa a primeira opção e Tab/setas percorrem as demais.
	if primeiro_botao:
		primeiro_botao.call_deferred("grab_focus")


func _on_dialog_action(action: String) -> void:
	match action:
		"intro": hide_dialog(); intro_confirmed.emit()
		"resume": hide_dialog(); resume_requested.emit()
		"ask_menu":
			_show_dialog("ABANDONAR A FASE?", "Os pontos positivos ainda não confirmados serão removidos. As penalidades permanecem.", [
				{"text": "CANCELAR", "action": "resume"},
				{"text": "SIM, VOLTAR", "action": "menu"},
			])
		"menu": hide_dialog(); menu_confirmed.emit()
		"retry": hide_dialog(); retry_requested.emit()
		"next": hide_dialog(); next_requested.emit()
		"replay": hide_dialog(); replay_requested.emit()


func _on_score_changed(total: int, _delta: int) -> void:
	_score_label.text = "★  %d" % total


func _on_lives_changed(current: int, maximum: int) -> void:
	_lives_label.text = "VIDAS × %d" % current
	var hearts := ""
	for index in maximum:
		hearts += "♥  " if index < current else "♡  "
	_hearts_label.text = hearts.strip_edges()


func _on_combo_changed(streak: int, bonus: int) -> void:
	_combo_label.text = "COMBO %d  +%d" % [streak, bonus] if streak >= 2 else "PONTOS"


func _clear_slots() -> void:
	for child in _slots.get_children():
		_slots.remove_child(child)
		child.queue_free()


func _panel(parent: Control, node_name: String, left: float, top: float, right: float, bottom: float, rect: Rect2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = node_name
	panel.add_theme_stylebox_override("panel", _style(PANEL, BORDER, 3, 7))
	_set_anchors(panel, left, top, right, bottom, rect)
	parent.add_child(panel)
	return panel


func _button(text: String, font_size: int) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_stylebox_override("normal", _style(PANEL, BORDER, 3, 6))
	button.add_theme_stylebox_override("hover", _style(PANEL_2, GOLD, 3, 6))
	button.add_theme_stylebox_override("pressed", _style(Color("17334a"), GOLD, 3, 6))
	return button


func _set_anchors(control: Control, left: float, top: float, right: float, bottom: float, rect: Rect2) -> void:
	control.anchor_left = left
	control.anchor_top = top
	control.anchor_right = right
	control.anchor_bottom = bottom
	control.offset_left = rect.position.x
	control.offset_top = rect.position.y
	control.offset_right = rect.position.x + rect.size.x
	control.offset_bottom = rect.position.y + rect.size.y


func _habilitar_clique_atraves(node: Node) -> void:
	if node is Control:
		node.mouse_filter = (
			Control.MOUSE_FILTER_STOP
			if node is BaseButton
			else Control.MOUSE_FILTER_IGNORE
		)
	for child in node.get_children():
		_habilitar_clique_atraves(child)


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", GAME_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 2)
	return label


func _style(background: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0, 0, 0, 0.55)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 3)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style
