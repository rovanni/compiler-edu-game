extends Node2D

@onready var prompt_panel: PanelContainer = $CanvasLayer/UI/PromptPanel
@onready var prompt_label: Label = $CanvasLayer/UI/PromptPanel/MarginContainer/PromptLabel
@onready var entrances_node: Node2D = $BossEntrances
@onready var hint_button: Button = $CanvasLayer/UI/HeaderPanel/HintButton

var active_entrance: BossEntrance = null
var bgm_player: AudioStreamPlayer = null

const BGM_PATH: String = "res://assets/fase3_parser/audio/escolha_boss.mp3"

static var gosma_defeated: bool = false
static var fantasma_defeated: bool = false
static var final_defeated: bool = false

func _ready() -> void:
	_setup_bgm()
	if prompt_panel:
		prompt_panel.visible = false
		
	if hint_button:
		_update_hint_button_ui()
		hint_button.pressed.connect(_on_hint_button_pressed)
		
	# Conecta todos os gatilhos de entrada dos chefões
	if entrances_node:
		for child in entrances_node.get_children():
			if child is BossEntrance:
				child.player_entered.connect(_on_boss_entrance_player_entered)
				child.player_exited.connect(_on_boss_entrance_player_exited)

	_start_ambient_animations(self)

	var player = get_node_or_null("Player")
	if player:
		EffectHelper.play_one_shot_effect(self, "res://assets/fase3_parser/sprites/smoke_burst.png", player.global_position, 128.0, 15.0)

	var btn_voltar = get_node_or_null("CanvasLayer/UI/HeaderPanel/BtnVoltarMenu")
	if btn_voltar:
		btn_voltar.pressed.connect(_on_btn_voltar_menu_pressed)

func _setup_bgm() -> void:
	bgm_player = AudioStreamPlayer.new()
	bgm_player.name = "MainRoomBGMPlayer"
	bgm_player.volume_db = -6.0
	add_child(bgm_player)
	
	var stream: AudioStream = null
	if ResourceLoader.exists(BGM_PATH):
		var res = load(BGM_PATH)
		if res is AudioStream:
			stream = res
			
	if stream == null:
		var global_p = ProjectSettings.globalize_path(BGM_PATH)
		stream = AudioStreamMP3.load_from_file(global_p)
		
	if stream:
		if stream is AudioStreamMP3:
			(stream as AudioStreamMP3).loop = true
		bgm_player.stream = stream
		bgm_player.play()
		bgm_player.finished.connect(func():
			if bgm_player and bgm_player.stream:
				bgm_player.play()
		)

func _stop_bgm() -> void:
	if bgm_player and bgm_player.playing:
		bgm_player.stop()

func _start_ambient_animations(node: Node) -> void:
	for child in node.get_children():
		if child is AnimatedSprite2D:
			var player_node = get_node_or_null("Player")
			if player_node and (child == player_node.get_node_or_null("AnimatedSprite2D") or player_node.is_ancestor_of(child)):
				continue
			if child.sprite_frames:
				var anim_name = child.animation if (child.animation != "" and child.sprite_frames.has_animation(child.animation)) else child.sprite_frames.get_animation_names()[0]
				child.sprite_frames.set_animation_loop(anim_name, true)
				if not child.is_playing():
					child.play(anim_name)
		_start_ambient_animations(child)

func _on_btn_voltar_menu_pressed() -> void:
	_stop_bgm()
	get_tree().change_scene_to_file("res://scenes/menu/menu.tscn")

func _on_hint_button_pressed() -> void:
	var BossFightScript = load("res://scripts/fase3_parser/boss_fight.gd")
	if BossFightScript:
		BossFightScript.show_hints = not BossFightScript.show_hints
		_update_hint_button_ui()

func _update_hint_button_ui() -> void:
	var BossFightScript = load("res://scripts/fase3_parser/boss_fight.gd")
	if hint_button and BossFightScript:
		if BossFightScript.show_hints:
			hint_button.text = "Ativar Dica: LIGADO"
		else:
			hint_button.text = "Ativar Dica: DESLIGADO"

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_stop_bgm()
		get_tree().change_scene_to_file("res://scenes/menu/menu.tscn")
		return

	if active_entrance != null:
		var pressed_interact = InputMap.has_action("interact") and event.is_action_pressed("interact")
		var pressed_accept = event.is_action_pressed("ui_accept")
		var pressed_e = event is InputEventKey and event.pressed and event.keycode == KEY_E
		
		if pressed_interact or pressed_accept or pressed_e:
			_enter_boss_phase(active_entrance)

func _on_boss_entrance_player_entered(entrance: BossEntrance) -> void:
	if prompt_label and prompt_panel:
		var boss_name_text = entrance.boss_name
		var can_enter = true
		
		if entrance.boss_name.to_lower() == "fantasma" and not gosma_defeated:
			can_enter = false
			prompt_label.text = "Derrote o Boss Gosma primeiro para liberar esta arena!"
		elif entrance.is_final_boss and not fantasma_defeated:
			can_enter = false
			prompt_label.text = "Derrote o Boss Fantasma primeiro para liberar esta arena!"
		else:
			if entrance.is_final_boss:
				prompt_label.text = "[★ BOSS FINAL ★] Pressione 'E' ou 'ENTER' para desafiar %s!" % boss_name_text
			else:
				prompt_label.text = "Pressione 'E' ou 'ENTER' para entrar na fase de %s!" % boss_name_text
		
		if can_enter:
			active_entrance = entrance
		else:
			active_entrance = null
		
		prompt_panel.visible = true

func _on_boss_entrance_player_exited(entrance: BossEntrance) -> void:
	if active_entrance == entrance or active_entrance == null:
		active_entrance = null
		if prompt_panel:
			prompt_panel.visible = false

func _enter_boss_phase(entrance: BossEntrance) -> void:
	_stop_bgm()
	var BossFightScript = load("res://scripts/fase3_parser/boss_fight.gd")
	if BossFightScript:
		BossFightScript.current_boss_id = entrance.boss_id
		BossFightScript.current_boss_name = entrance.boss_name
		BossFightScript.current_boss_color = entrance.accent_color
		BossFightScript.current_boss_bg_path = entrance.bg_path
	
	print("Entrando na fase do chefão: ", entrance.boss_name)
	var target_scene = entrance.arena_scene_path if entrance.arena_scene_path != "" else "res://scenes/fase3_parser/boss_fight.tscn"
	get_tree().change_scene_to_file(target_scene)
