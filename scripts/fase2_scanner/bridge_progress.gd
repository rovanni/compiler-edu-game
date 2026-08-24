extends Node2D

signal bridge_completed

var activated_slots: Dictionary = {}

func _ready() -> void:
	for child in get_children():
		if child.has_method("set_active"):
			child.set_active(false)

func activate_slot(index: int) -> bool:
	var slots := get_children().filter(func(node): return node.has_method("set_active"))
	if slots.is_empty():
		return false
	var slot_index := posmod(index, slots.size())
	if activated_slots.has(slot_index):
		return false
	activated_slots[slot_index] = true
	slots[slot_index].set_active(true)
	if activated_slots.size() >= slots.size():
		bridge_completed.emit()
	return true

func reset_bridge() -> void:
	activated_slots.clear()
	for child in get_children():
		if child.has_method("set_active"):
			child.set_active(false)
