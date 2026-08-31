class_name EffectHelper
extends Node

## Cria um SpriteFrames a partir de uma imagem de tirinha horizontal (frames quadrados)
static func create_sprite_frames(texture_path: String, anim_name: String = "default", loop: bool = false, fps: float = 12.0) -> SpriteFrames:
	var tex = load(texture_path) as Texture2D
	if not tex:
		return null
		
	var sf = SpriteFrames.new()
	if not sf.has_animation(anim_name):
		sf.add_animation(anim_name)
	sf.set_animation_loop(anim_name, loop)
	sf.set_animation_speed(anim_name, fps)
	
	var frame_h = tex.get_height()
	var frame_w = frame_h
	if frame_w <= 0:
		return null
		
	var count = int(round(float(tex.get_width()) / float(frame_w)))
	
	for i in range(count):
		var atlas = AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(i * frame_w, 0, frame_w, frame_h)
		sf.add_frame(anim_name, atlas)
		
	return sf

## Cria um SpriteFrames a partir de uma grade/spritesheet
static func create_grid_sprite_frames(texture_path: String, cols: int, rows: int, row_index: int, start_col: int, end_col: int, anim_name: String = "default", loop: bool = true, fps: float = 10.0) -> SpriteFrames:
	var tex = load(texture_path) as Texture2D
	if not tex:
		return null
		
	var sf = SpriteFrames.new()
	if not sf.has_animation(anim_name):
		sf.add_animation(anim_name)
	sf.set_animation_loop(anim_name, loop)
	sf.set_animation_speed(anim_name, fps)
	
	var frame_w = float(tex.get_width()) / float(cols)
	var frame_h = float(tex.get_height()) / float(rows)
	
	if frame_w <= 0 or frame_h <= 0:
		return null
		
	for c in range(start_col, end_col + 1):
		var atlas = AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(c * frame_w, row_index * frame_h, frame_w, frame_h)
		sf.add_frame(anim_name, atlas)
		
	return sf

## Executa um efeito de animação de tiro único (one-shot) e se deleta ao terminar
static func play_one_shot_effect(parent: Node, texture_path: String, pos: Vector2, target_size: float = 128.0, fps: float = 12.0) -> AnimatedSprite2D:
	if not parent:
		return null
		
	var sf = create_sprite_frames(texture_path, "default", false, fps)
	if not sf:
		return null
		
	var anim_sprite = AnimatedSprite2D.new()
	anim_sprite.sprite_frames = sf
	anim_sprite.global_position = pos
	
	var tex = load(texture_path) as Texture2D
	if tex:
		var frame_h = tex.get_height()
		if frame_h > 0:
			var s = target_size / float(frame_h)
			anim_sprite.scale = Vector2(s, s)
			
	parent.add_child(anim_sprite)
	anim_sprite.animation_finished.connect(func(): anim_sprite.queue_free())
	anim_sprite.play("default")
	return anim_sprite
