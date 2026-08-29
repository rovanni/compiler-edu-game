extends SceneTree

const AstSessionScript := preload("res://scripts/fase4_ast/ast_session.gd")
var failures := 0


func _init() -> void:
	_test_operator_precedence_tree()
	_test_wrong_node_does_not_consume_token()
	if failures == 0:
		print("PASS: lógica da AST, precedência e alocação de tokens")
		quit(0)
	else:
		push_error("FAIL: %d teste(s) da AST falharam" % failures)
		quit(1)


func _test_operator_precedence_tree() -> void:
	var nodes := {
		"root": {"token": "+"},
		"left": {"token": "a"},
		"right": {"token": "*"},
		"right_left": {"token": "b"},
		"right_right": {"token": "c"},
	}
	var session = AstSessionScript.new()
	session.configure(nodes, ["+", "a", "*", "b", "c"])
	_expect(session.try_place("root") == AstSessionScript.Result.ACCEPTED, "+ deve ocupar a raiz")
	_expect(session.try_place("left") == AstSessionScript.Result.ACCEPTED, "a deve ocupar o filho esquerdo")
	_expect(session.try_place("right") == AstSessionScript.Result.ACCEPTED, "* deve iniciar a subárvore direita")
	_expect(session.try_place("right_left") == AstSessionScript.Result.ACCEPTED, "b deve ser folha esquerda de *")
	_expect(session.try_place("right_right") == AstSessionScript.Result.COMPLETE, "c conclui a AST")
	_expect(session.is_complete(), "todos os cinco nós devem estar preenchidos")


func _test_wrong_node_does_not_consume_token() -> void:
	var session = AstSessionScript.new()
	session.configure({"root": {"token": "="}, "left": {"token": "x"}}, ["=", "x"])
	_expect(session.try_place("left") == AstSessionScript.Result.WRONG, "= não pode ser colocado como filho esquerdo")
	_expect(session.current_token == "=", "um erro não pode consumir o token da mão")
	_expect(session.progress() == 0, "um erro não pode preencher um nó")


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error("TESTE AST: %s" % message)
