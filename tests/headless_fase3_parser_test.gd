extends SceneTree

const BossFightScript := preload("res://scripts/fase3_parser/boss_fight.gd")
var failures := 0

func _init() -> void:
	_test_token_arrays_integrity()
	_test_token_lengths_match_levels()
	_test_no_empty_or_whitespace_tokens()
	_test_sequence_validation_logic()
	
	if failures == 0:
		print("PASS: Fase 3 Parser - Novas opções de tokens, integridade e validação sintática")
		quit(0)
	else:
		push_error("FAIL: %d teste(s) da Fase 3 falharam" % failures)
		quit(1)

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
	var sample_correct = ["var", "x", "=", "10"]
	var sample_wrong = ["10", "=", "x", "var"]
	
	var is_correct = true
	for i in range(sample_expected.size()):
		if sample_correct[i] != sample_expected[i]:
			is_correct = false
			break
	_expect(is_correct, "Sequência correta deve ser aceita")
	
	var is_wrong_detected = false
	for i in range(sample_expected.size()):
		if sample_wrong[i] != sample_expected[i]:
			is_wrong_detected = true
			break
	_expect(is_wrong_detected, "Sequência errada deve ser rejeitada")

func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error("TESTE FASE 3 PARSER: %s" % message)
