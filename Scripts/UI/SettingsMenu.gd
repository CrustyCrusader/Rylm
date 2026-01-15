# SettingsMenu.gd
extends Control
class_name SettingsMenu

@onready var panel = $Panel
@onready var close_button = $Panel/VBoxContainer/CloseButton
@onready var save_button = $Panel/VBoxContainer/SaveButton
@onready var load_button = $Panel/VBoxContainer/LoadButton
@onready var quit_button = $Panel/VBoxContainer/QuitButton

var save_system = SimpleSaveSystem.new()

func _ready():
	panel.visible = false
	close_button.pressed.connect(close)
	save_button.pressed.connect(_on_save_pressed)
	load_button.pressed.connect(_on_load_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func open():
	panel.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().paused = true

func close():
	panel.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	get_tree().paused = false

func _on_save_pressed():
	if save_system.save_game():
		print("Game saved!")
	else:
		print("Save failed!")

func _on_load_pressed():
	if save_system.load_game():
		print("Game loaded!")
		close()
	else:
		print("Load failed!")

func _on_quit_pressed():
	get_tree().quit()
