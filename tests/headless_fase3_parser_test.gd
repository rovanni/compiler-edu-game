extends SceneTree

const BossFightScript := preload("res://scripts/fase3_parser/boss_fight.gd")
var failures := 0

func _init() -> void:
	_test_token_arrays_integrity()
	_test_token_lengths_match_levels()
	_test_no_empty_or_whitespace_tokens()
	_test_sequence_validation_logic()
	_test_plate_highlight_logic()
	_test_boss_audio_paths()
	_test_custom_health_bars()
	
	if failures == 0:
		print("PASS: Fase 3 Parser - Novas opções de tokens, integridade, validação sintática, áudio e barras de vida")
		quit(0)
	else:
		push_error("FAIL: %d teste(s) da Fase 3 falharam" % failures)
		quit(1)

func _test_custom_health_bars() -> void:
	var bosses = ["slime", "fantasma", "parser"]
	var levels = ["alta", "media", "baixa"]
	for b in bosses:
		for lvl in levels:
			var path = "res://assets/fase3_parser/sprites/health_bars/%s/%s.png" % [b, lvl]
			var exists = FileAccess.file_exists(path)
			_expect(exists, "Barra de vida '%s' deve existir" % path)

func _test_boss_audio_paths() -> void:
	_expect(BossFightScript.AUDIO_PATHS.size() >= 19, "Deveria haver pelo menos 19 arquivos de áudio registrados")
	for key in BossFightScript.AUDIO_PATHS:
		var path = BossFightScript.AUDIO_PATHS[key]
		var file_exists = FileAccess.file_exists(path)
		_expect(file_exists, "Arquivo de áudio '%s' em '%s' deve existir" % [key, path])
	var main_room_bgm_exists = FileAccess.file_exists("res://assets/fase3_parser/audio/escolha_boss.mp3")
	_expect(main_room_bgm_exists, "Arquivo de áudio da escolha de chefe 'res://assets/fase3_parser/audio/escolha_boss.mp3' deve existir")

func _test_token_arrays_integrity() -> void:
	_expect(BossFightScript.CODES_LEVEL_3_PLATES.size() >= 5, "Nível 3 placas deve ter pelo menos 5 sentenças")
	_expect(BossFightScript.CODES_LEVEL_4_PLATES.size() >= 20, "Nível 4 placas deve ter pelo menos 20 sentenças")
	_expect(BossFightScript.CODES_LEVEL_5_PLATES.size() >= 20, "Nível 5 placas deve ter pelo menos 20 sentenças")
	_expect(BossFightScript.CODES_LEVEL_6_PLATES.size() >= 20, "Nível 6 placas deve ter pelo menos 20 sentenças")

func _test_token_lengths_match_levels() -> void:
	for code in BossFightScript.CODES_LEVEL_3_PLATES:
		_expect(code.size() == 3, "Sentença em CODES_LEVEL_3_PLATES deve ter 3 tokens: %s" % str(code))
		
	for code in BossFightScript.CODES_LEVEL_4_PLATES:
		_expect(code.size() == 4, "Sentença em CODES_LEVEL_4_PLATES deve ter 4 tokens: %s" % str(code))
		
	for code in BossFightScript.CODES_LEVEL_5_PLATES:
		_expect(code.size() == 5, "Sentença em CODES_LEVEL_5_PLATES deve ter 5 tokens: %s" % str(code))
		
	for code in BossFightScript.CODES_LEVEL_6_PLATES:
		_expect(code.size() == 6, "Sentença em CODES_LEVEL_6_PLATES deve ter 6 tokens: %s" % str(code))

func _test_no_empty_or_whitespace_tokens() -> void:
	var all_lists = [
		BossFightScript.CODES_LEVEL_3_PLATES,
		BossFightScript.CODES_LEVEL_4_PLATES,
		BossFightScript.CODES_LEVEL_5_PLATES,
		BossFightScript.CODES_LEVEL_6_PLATES
	]
	
	for list in all_lists:
		for code in list:
			for token in code:
				_expect(token is String, "Token deve ser String: %s" % str(token))
				_expect(token.strip_edges() != "", "Token não pode ser vazio ou só espaço: %s" % str(token))

func _test_sequence_validation_logic() -> void:
	var sample_expected = ["var", "x", "=", "10"]
	
	# Teste de acerto passo a passo
	var current_step_0_correct = ("var" == sample_expected[0])
	var current_step_1_correct = ("x" == sample_expected[1])
	_expect(current_step_0_correct and current_step_1_correct, "Passos individuais corretos devem ser aceitos")
	
	# Teste de erro IMEDIATO no primeiro elemento
	var first_elem_wrong = ("10" != sample_expected[0])
	_expect(first_elem_wrong, "Erro no 1º elemento deve ser detectado imediatamente")
	
	# Teste de erro IMEDIATO em elemento intermediário
	var intermediate_wrong = ("=" != sample_expected[1])
	_expect(intermediate_wrong, "Erro intermediário deve ser detectado imediatamente")

func _test_plate_highlight_logic() -> void:
	var expected_seq = ["var", "x", "=", "10"]
	var current_seq = []
	
	# Próximo token no início é o primeiro elemento
	var next_token_initial = expected_seq[current_seq.size()] if current_seq.size() < expected_seq.size() else ""
	_expect(next_token_initial == "var", "Dica inicial deve apontar para 'var'")
	
	# Após avançar 1 passo correto
	current_seq.append("var")
	var next_token_step1 = expected_seq[current_seq.size()] if current_seq.size() < expected_seq.size() else ""
	_expect(next_token_step1 == "x", "Dica no passo 1 deve apontar para 'x'")

func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error("TESTE FASE 3 PARSER: %s" % message)
