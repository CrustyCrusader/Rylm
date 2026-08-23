extends Node

@export var body_meshes: Array[MeshInstance3D] = []

var current_body: int = 0


func _ready() -> void:
	_select_body(current_body)


func set_body(index: int) -> void:
	if body_meshes.is_empty():
		return

	current_body = clampi(index, 0, body_meshes.size() - 1)
	_select_body(current_body)


func next_body() -> void:
	if body_meshes.is_empty():
		return

	current_body = (current_body + 1) % body_meshes.size()
	_select_body(current_body)


func previous_body() -> void:
	if body_meshes.is_empty():
		return

	current_body -= 1

	if current_body < 0:
		current_body = body_meshes.size() - 1

	_select_body(current_body)


func _select_body(index: int) -> void:
	for i in range(body_meshes.size()):
		if is_instance_valid(body_meshes[i]):
			body_meshes[i].visible = (i == index)



func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_right"):
		next_body()
	if event.is_action_pressed("ui_left"):
		previous_body()
