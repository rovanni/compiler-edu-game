extends CanvasLayer

signal pause_requested
signal resume_requested
signal intro_confirmed
signal menu_requested
signal hint_requested
signal retry_requested
signal replay_requested
signal next_phase_requested

const GAME_FONT := preload("res://fonts/Friend Bestie.otf")
const INK := Color("06111d")
const PANEL := Color(0.025, 0.065, 0.09, 0.94)
const PANEL_LIGHT := Color(0.05, 0.12, 0.15, 0.96)
const BORDER := Color("5f7890")
const GOLD := Color("ffc94a")
const TEXT := Color("f6f1dc")
const MUTED := Color("a8bdc6")
const RED := Color("ff5252")

var _root: Control
var _hearts_label: Label
var _score_label: Label
var _time_label: Label
var _expression_label: RichTextLabel
var _token_panel: PanelContainer
var _token_label: Label
var _instruction_label: Label
var _progress_label: Label
var _lesson_label: Label
var _overlay: ColorRect
var _dialog_title: Label
var _dialog_body: RichTextLabel
var _dialog_buttons: HBoxContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_interface()
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.lives_changed.connect(_on_lives_changed)
	_on_score_changed(GameManager.score, 0)
	_on_lives_changed(GameManager.lives, GameManager.MAX_LIVES)


func set_expression(expression: String, lesson: String) -> void:
	_expression_label.text = _expression_bbcode(expression)
	_lesson_label.text = lesson


func set_token(token: String, color: Color) -> void:
	_token_label.text = token if not token.is_empty() else "✓"
	var style := _style(color.darkened(0.28), color.lightened(0.34), 3, 8)
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	_token_panel.add_theme_stylebox_override("panel", style)


func set_time(seconds: float) -> void:
	var total := maxi(int(ceil(seconds)), 0)
	_time_label.text = "%02d:%02d" % [total / 60, total % 60]
	_time_label.add_theme_color_override("font_color", RED if total <= 15 else TEXT)


func set_progress(current: int, total: int) -> void:
	_progress_label.text = "ÁRVORE AST\n%d / %d NÓS\nPREENCHIDOS" % [current, total]


func set_instruction(text: String) -> void:
	_instruction_label.text = text


func show_feedback(text: String, color: Color = TEXT) -> void:
	# O retorno pedagógico reutiliza a área de instrução para manter o cenário
	# limpo, sem um painel adicional atravessando a tela.
	_instruction_label.text = text
	_instruction_label.add_theme_color_override("font_color", color)


func show_intro(expression: String, lesson: String) -> void:
	_show_dialog("CONSTRUA A ÁRVORE SINTÁTICA", "A expressão desta rodada é [b]%s[/b].\n\n%s\n\nVocê receberá um token por vez. Percorra as plataformas, aproxime-se do nó correto e pressione [b]E[/b] para alocá-lo." % [expression, lesson], [
		{"text": "COMEÇAR", "action": "intro"},
		{"text": "VOLTAR AO MENU", "action": "ask_menu"},
	])


func show_pause() -> void:
	_show_dialog("JOGO PAUSADO", "A árvore e o cronômetro estão pausados.", [
		{"text": "CONTINUAR", "action": "resume"},
		{"text": "VOLTAR AO MENU", "action": "ask_menu"},
	])


func show_game_over() -> void:
	_show_dialog("SEM VIDAS", "Revise a precedência dos operadores e tente montar a AST novamente. Os pontos provisórios desta fase serão removidos.", [
		{"text": "TENTAR NOVAMENTE", "action": "retry"},
		{"text": "VOLTAR AO MENU", "action": "menu"},
	])


func show_completion(expression: String, bonus: int) -> void:
	_show_dialog("FLORESTA DA AST CONCLUÍDA!", "Você transformou [b]%s[/b] em uma árvore sintática correta.\n\n[b]+%d pontos de conclusão.[/b]\n\nOperadores de maior precedência aparecem em subárvores mais profundas; a raiz representa a última operação avaliada." % [expression, bonus], [
		{"text": "PRÓXIMA FASE", "action": "next_phase"},
		{"text": "NOVA EXPRESSÃO", "action": "replay"},
		{"text": "VOLTAR AO MENU", "action": "menu"},
	])


func hide_dialog() -> void:
	_overlay.visible = false


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
	_build_side_panels()
	_build_bottom_bar()
	_build_dialog()


func _build_top_bar() -> void:
	var status_panel := _panel(_root, "StatusPanel", Rect2(12, 10, 220, 70), PANEL)
	var status_box := VBoxContainer.new()
	status_box.alignment = BoxContainer.ALIGNMENT_CENTER
	status_panel.add_child(status_box)
	_hearts_label = _label("♥  ♥  ♥", 22, RED)
	_hearts_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_score_label = _label("●  PONTOS  0", 15, GOLD)
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_box.add_child(_hearts_label)
	status_box.add_child(_score_label)

	var title_panel := _panel(_root, "TitlePanel", Rect2(390, 10, 500, 58), PANEL)
	var title := _label("FASE 4 - ÁRVORE SINTÁTICA", 23, TEXT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 6)
	title_panel.add_child(title)

	var time_panel := _panel(_root, "TimePanel", Rect2(1015, 10, 140, 64), PANEL)
	var time_box := VBoxContainer.new()
	time_box.alignment = BoxContainer.ALIGNMENT_CENTER
	time_panel.add_child(time_box)
	var time_heading := _label("⌛  TEMPO", 12, GOLD)
	time_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_time_label = _label("03:00", 21, TEXT)
	_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_box.add_child(time_heading)
	time_box.add_child(_time_label)

	var pause_button := _button("Ⅱ", 28)
	pause_button.position = Vector2(1195, 10)
	pause_button.size = Vector2(72, 64)
	pause_button.pressed.connect(func() -> void: pause_requested.emit())
	_root.add_child(pause_button)


func _build_side_panels() -> void:
	var expression_panel := _panel(_root, "ExpressionPanel", Rect2(18, 112, 178, 66), PANEL)
	var expression_box := VBoxContainer.new()
	expression_box.alignment = BoxContainer.ALIGNMENT_CENTER
	expression_panel.add_child(expression_box)
	var expression_heading := _label("EXPRESSÃO", 13, GOLD)
	expression_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	expression_box.add_child(expression_heading)
	_expression_label = RichTextLabel.new()
	_expression_label.custom_minimum_size = Vector2(148, 27)
	_expression_label.bbcode_enabled = true
	_expression_label.fit_content = false
	_expression_label.scroll_active = false
	_expression_label.add_theme_font_size_override("normal_font_size", 19)
	expression_box.add_child(_expression_label)

	var lesson_panel := _panel(_root, "LessonPanel", Rect2(18, 190, 190, 96), PANEL_LIGHT)
	var lesson_box := VBoxContainer.new()
	lesson_box.add_theme_constant_override("separation", 5)
	lesson_panel.add_child(lesson_box)
	var lesson_heading := _label("LÓGICA DA AST", 13, GOLD)
	lesson_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lesson_box.add_child(lesson_heading)
	_lesson_label = _label("Observe a precedência dos operadores.", 10, TEXT)
	_lesson_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lesson_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lesson_box.add_child(_lesson_label)


func _build_bottom_bar() -> void:
	var token_bar := _panel(_root, "TokenBar", Rect2(335, 630, 575, 76), PANEL)
	var token_row := HBoxContainer.new()
	token_row.add_theme_constant_override("separation", 16)
	token_bar.add_child(token_row)
	var token_box := VBoxContainer.new()
	token_box.custom_minimum_size = Vector2(170, 0)
	token_box.alignment = BoxContainer.ALIGNMENT_CENTER
	token_row.add_child(token_box)
	var token_heading := _label("TOKEN NA MÃO", 13, GOLD)
	token_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	token_box.add_child(token_heading)
	_token_panel = PanelContainer.new()
	_token_panel.custom_minimum_size = Vector2(50, 40)
	_token_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_token_label = _label("+", 24, TEXT)
	_token_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_token_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_token_panel.add_child(_token_label)
	token_box.add_child(_token_panel)

	var separator := VSeparator.new()
	separator.custom_minimum_size = Vector2(2, 0)
	token_row.add_child(separator)
	var instruction_box := VBoxContainer.new()
	instruction_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	instruction_box.alignment = BoxContainer.ALIGNMENT_CENTER
	token_row.add_child(instruction_box)
	_instruction_label = _label("APROXIME-SE DE UM NÓ\nE PRESSIONE  E  PARA ALOCAR", 12, TEXT)
	_instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_instruction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instruction_box.add_child(_instruction_label)
	var hint_button := _button("DICA  -5", 12)
	hint_button.custom_minimum_size = Vector2(82, 25)
	hint_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	hint_button.pressed.connect(func() -> void: hint_requested.emit())
	instruction_box.add_child(hint_button)

	var progress_panel := _panel(_root, "ProgressPanel", Rect2(1060, 630, 195, 76), PANEL)
	_progress_label = _label("ÁRVORE AST\n0 / 5 NÓS\nPREENCHIDOS", 11, GOLD)
	_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_progress_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	progress_panel.add_child(_progress_label)


func _build_dialog() -> void:
	_overlay = ColorRect.new()
	_overlay.color = Color(0.005, 0.018, 0.026, 0.91)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.visible = false
	_root.add_child(_overlay)

	var dialog_panel := _panel(_overlay, "DialogPanel", Rect2(320, 145, 640, 430), PANEL)
	var dialog_box := VBoxContainer.new()
	dialog_box.add_theme_constant_override("separation", 14)
	dialog_panel.add_child(dialog_box)
	_dialog_title = _label("CONSTRUA A ÁRVORE", 27, GOLD)
	_dialog_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialog_box.add_child(_dialog_title)
	_dialog_body = RichTextLabel.new()
	_dialog_body.custom_minimum_size = Vector2(590, 285)
	_dialog_body.bbcode_enabled = true
	_dialog_body.scroll_active = true
	_dialog_body.add_theme_font_size_override("normal_font_size", 17)
	_dialog_body.add_theme_color_override("default_color", TEXT)
	dialog_box.add_child(_dialog_body)
	_dialog_buttons = HBoxContainer.new()
	_dialog_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	_dialog_buttons.add_theme_constant_override("separation", 12)
	dialog_box.add_child(_dialog_buttons)


func _show_dialog(title: String, body: String, buttons: Array) -> void:
	_dialog_title.text = title
	_dialog_body.text = body
	for child in _dialog_buttons.get_children():
		_dialog_buttons.remove_child(child)
		child.queue_free()
	for definition in buttons:
		var button := _button(str(definition.get("text", "OK")), 14)
		button.custom_minimum_size = Vector2(175, 42)
		button.pressed.connect(_on_dialog_action.bind(str(definition.get("action", "resume"))))
		_dialog_buttons.add_child(button)
	_overlay.visible = true


func _on_dialog_action(action: String) -> void:
	match action:
		"intro": hide_dialog(); intro_confirmed.emit()
		"resume": hide_dialog(); resume_requested.emit()
		"ask_menu":
			_show_dialog("ABANDONAR A FASE?", "Os pontos positivos ainda não confirmados serão removidos. As penalidades permanecem.", [
				{"text": "CANCELAR", "action": "resume"},
				{"text": "SIM, VOLTAR", "action": "menu"},
			])
		"menu": hide_dialog(); menu_requested.emit()
		"retry": hide_dialog(); retry_requested.emit()
		"replay": hide_dialog(); replay_requested.emit()
		"next_phase": hide_dialog(); next_phase_requested.emit()


func _expression_bbcode(expression: String) -> String:
	var parts := PackedStringArray()
	for part in expression.split(" "):
		var color := "#d076ff" if part in ["+", "-", "*", "/", "="] else "#60c9ff"
		parts.append("[color=%s]%s[/color]" % [color, part])
	return "[center][font_size=20]%s[/font_size][/center]" % " ".join(parts)


func _on_score_changed(total: int, _delta: int) -> void:
	_score_label.text = "●  PONTOS  %d" % total


func _on_lives_changed(current: int, maximum: int) -> void:
	var hearts := ""
	for index in maximum:
		hearts += "♥  " if index < current else "♡  "
	_hearts_label.text = hearts.strip_edges()


func _panel(parent: Control, node_name: String, rect: Rect2, background: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = node_name
	panel.position = rect.position
	panel.size = rect.size
	var style := _style(background, BORDER, 3, 8)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	return panel


func _button(text: String, font_size: int) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _style(Color("162737"), Color("7890a4"), 3, 7))
	button.add_theme_stylebox_override("hover", _style(Color("24445a"), GOLD, 3, 7))
	button.add_theme_stylebox_override("pressed", _style(Color("0d1c29"), GOLD, 3, 7))
	return button


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _style(background: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.5)
	style.shadow_size = 5
	return style
