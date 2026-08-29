extends RefCounted
class_name AstSession

enum Result { WRONG, ACCEPTED, COMPLETE }

var expected_by_slot: Dictionary = {}
var placed_by_slot: Dictionary = {}
var remaining_tokens: Array = []
var current_token := ""


func configure(nodes: Dictionary, forced_order: Array = []) -> void:
	expected_by_slot.clear()
	placed_by_slot.clear()
	remaining_tokens.clear()

	for slot_id in nodes:
		var definition: Dictionary = nodes[slot_id]
		expected_by_slot[str(slot_id)] = str(definition.get("token", ""))

	if forced_order.is_empty():
		for token in expected_by_slot.values():
			remaining_tokens.append(str(token))
		remaining_tokens.shuffle()
	else:
		for token in forced_order:
			remaining_tokens.append(str(token))

	_advance_token()


func try_place(slot_id: String) -> Result:
	if current_token.is_empty() or placed_by_slot.has(slot_id):
		return Result.WRONG
	if str(expected_by_slot.get(slot_id, "")) != current_token:
		return Result.WRONG

	placed_by_slot[slot_id] = current_token
	_advance_token()
	return Result.COMPLETE if is_complete() else Result.ACCEPTED


func expected_for(slot_id: String) -> String:
	return str(expected_by_slot.get(slot_id, ""))


func is_complete() -> bool:
	return not expected_by_slot.is_empty() and placed_by_slot.size() == expected_by_slot.size()


func progress() -> int:
	return placed_by_slot.size()


func total() -> int:
	return expected_by_slot.size()


func _advance_token() -> void:
	current_token = "" if remaining_tokens.is_empty() else str(remaining_tokens.pop_front())
