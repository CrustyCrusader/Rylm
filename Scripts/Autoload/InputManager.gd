class_name InputManager
extends Node

signal input_mode_changed(new_mode: int)

enum InputMode { GAMEPLAY, UI, DIALOG, CUTSCENE }

var current_input_mode: InputMode = InputMode.GAMEPLAY:
	set(value):
		if current_input_mode != value:
			current_input_mode = value
			input_mode_changed.emit(current_input_mode)

var controller_deadzone: float = 0.2
var input_buffer: Array[Dictionary] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	_update_ui_mode_state()
	_process_buffer(delta)

func _update_ui_mode_state() -> void:
	var ui_nodes := get_tree().get_nodes_in_group("ui_active")
	if ui_nodes.size() > 0 and current_input_mode == InputMode.GAMEPLAY:
		current_input_mode = InputMode.UI
	elif ui_nodes.size() == 0 and current_input_mode == InputMode.UI:
		current_input_mode = InputMode.GAMEPLAY

func buffer_action(action_name: String, duration: float = 0.2) -> void:
	input_buffer.append({"action": action_name, "time_left": duration})

func is_action_buffered(action_name: String) -> bool:
	for item in input_buffer:
		if item.get("action", "") == action_name:
			return true
	return false

func consume_buffered_action(action_name: String) -> bool:
	for i in range(input_buffer.size() - 1, -1, -1):
		var item: Dictionary = input_buffer[i]
		if String(item.get("action", "")) == action_name:
			input_buffer.remove_at(i)
			return true
	return false

func _process_buffer(delta: float) -> void:
	for i in range(input_buffer.size() - 1, -1, -1):
		var entry: Dictionary = input_buffer[i]
		var remaining_time: float = float(entry.get("time_left", 0.0)) - delta
		entry["time_left"] = remaining_time
		if remaining_time <= 0.0:
			input_buffer.remove_at(i)
