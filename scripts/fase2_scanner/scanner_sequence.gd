extends RefCounted
class_name ScannerSequence

enum Result { WRONG, ACCEPTED, COMPLETE }
var expected_tokens: Array = []
var accepted_tokens: Array = []
var expected_index := 0

func configure(tokens: Array) -> void:
	expected_tokens = tokens.duplicate(true)
	reset()

func reset() -> void:
	accepted_tokens.clear()
	expected_index = 0

func try_accept(candidate: Dictionary) -> Result:
	if is_complete() or not matches_next(candidate):
		return Result.WRONG
	accepted_tokens.append(candidate)
	expected_index += 1
	return Result.COMPLETE if is_complete() else Result.ACCEPTED

func matches_next(candidate: Dictionary) -> bool:
	if is_complete():
		return false
	var expected: Dictionary = expected_tokens[expected_index]
	return str(candidate.get("lexeme", "")) == str(expected.get("lexeme", "")) and int(candidate.get("kind", -1)) == int(expected.get("kind", -2))

func next_token() -> Dictionary:
	return {} if is_complete() else expected_tokens[expected_index]

func is_complete() -> bool:
	return expected_index >= expected_tokens.size()
