extends SceneTree

const ScannerDataScript := preload("res://scripts/fase2_scanner/scanner_data.gd")
const ScannerSequenceScript := preload("res://scripts/fase2_scanner/scanner_sequence.gd")
const GameManagerScript := preload("res://scripts/autoload/game_manager.gd")
var failures := 0

func _init() -> void:
	_test_challenge_one_sequence()
	_test_duplicate_identifiers_are_equivalent()
	_test_score_combo_and_rollback()
	_test_lives_and_terminal_guard()
	if failures == 0:
		print("PASS: scanner, pontuação, rollback e vidas")
		quit(0)
	else:
		push_error("FAIL: %d teste(s) falharam" % failures)
		quit(1)

func _test_challenge_one_sequence() -> void:
	var challenge: Dictionary = ScannerDataScript.challenges()[0]
	var sequence = ScannerSequenceScript.new()
	sequence.configure(challenge["tokens"])
	_expect(sequence.try_accept(challenge["tokens"][1]) == ScannerSequenceScript.Result.WRONG, "token antecipado deve falhar")
	_expect(sequence.expected_index == 0, "erro não altera o prefixo aceito")
	for index in challenge["tokens"].size():
		var result = sequence.try_accept(challenge["tokens"][index])
		_expect(result == (ScannerSequenceScript.Result.COMPLETE if index + 1 == challenge["tokens"].size() else ScannerSequenceScript.Result.ACCEPTED), "resultado correto por posição")

func _test_duplicate_identifiers_are_equivalent() -> void:
	var tokens: Array = ScannerDataScript.challenges()[1]["tokens"]
	var sequence = ScannerSequenceScript.new()
	sequence.configure(tokens)
	sequence.try_accept(tokens[0]); sequence.try_accept(tokens[1])
	_expect(sequence.try_accept(tokens[7]) == ScannerSequenceScript.Result.ACCEPTED, "qualquer x físico atende à primeira ocorrência")
	sequence.try_accept(tokens[3]); sequence.try_accept(tokens[4]); sequence.try_accept(tokens[5]); sequence.try_accept(tokens[6])
	_expect(sequence.try_accept(tokens[2]) == ScannerSequenceScript.Result.ACCEPTED, "o x restante atende à segunda ocorrência")
	_expect(sequence.try_accept(tokens[8]) == ScannerSequenceScript.Result.COMPLETE, "sequência com x trocados deve concluir")

func _test_score_combo_and_rollback() -> void:
	var manager = GameManagerScript.new()
	root.add_child(manager)
	manager.start_new_session(2)
	_expect(manager.register_correct_action() == 10, "primeiro acerto vale 10")
	_expect(manager.register_correct_action() == 12, "segundo acerto vale 12")
	_expect(manager.register_correct_action() == 14, "terceiro acerto vale 14")
	_expect(manager.register_correct_action() == 18, "quarto acerto vale 18")
	var checkpoint: int = manager.create_checkpoint()
	_expect(manager.score == 54, "combo soma 54 pontos")
	manager.register_correct_action(); manager.rollback_to(checkpoint)
	_expect(manager.score == 54, "rollback remove apenas pontos posteriores")
	manager.register_mistake("teste", false)
	_expect(manager.score == 49, "penalidade vale 5")
	manager.rollback_to(0)
	_expect(manager.score == 0, "rollback não deixa score negativo")
	manager.queue_free()

func _test_lives_and_terminal_guard() -> void:
	var manager = GameManagerScript.new()
	root.add_child(manager)
	manager.start_new_session(2)
	var game_over_count := [0]
	manager.game_over.connect(func(_phase_id: int) -> void: game_over_count[0] += 1)
	manager.register_mistake("erro_1", true); manager.register_mistake("erro_2", true); manager.register_mistake("erro_3", true); manager.register_mistake("erro_duplicado", true)
	_expect(manager.lives == 0, "três erros removem as três vidas")
	_expect(game_over_count[0] == 1, "Game Over é emitido uma única vez")
	_expect(manager.score == 0, "pontuação nunca fica negativa")
	manager.queue_free()

func _expect(condition: bool, message: String) -> void:
	if condition: return
	failures += 1
	push_error("TESTE: %s" % message)
