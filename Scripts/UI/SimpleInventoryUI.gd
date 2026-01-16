# SimpleInventoryUI.gd - UPDATED VERSION
extends CanvasLayer
class_name SimpleInventoryUI

signal inventory_closed

@export var close_button: Button
var player: BaseCharacter3D = null
var button_connected: bool = false  # Track if button is connected

func _ready():
	print("=== SimpleInventoryUI _ready() called ===")
	
	# Try multiple ways to find the close button
	if not close_button:
		# Method 1: Try to find by name
		close_button = find_child("CloseButton") as Button
		if not close_button:
			# Method 2: Try common button names
			close_button = find_child("XButton") as Button
		if not close_button:
			# Method 3: Try to get first button in the scene
			close_button = get_first_button(self)
	
	if close_button:
		print("Found CloseButton: ", close_button.name)
		# Disconnect first to avoid duplicate connections
		if close_button.pressed.is_connected(_on_close_pressed):
			close_button.pressed.disconnect(_on_close_pressed)
		close_button.pressed.connect(_on_close_pressed)
		button_connected = true
		print("CloseButton connected successfully!")
	else:
		print("ERROR: Could not find CloseButton!")
		# Debug: Print all children to help find the button
		print_all_children(self)
	
	visible = false

func get_first_button(node: Node) -> Button:
	for child in node.get_children():
		if child is Button:
			return child as Button
		var found = get_first_button(child)
		if found:
			return found
	return null

func print_all_children(node: Node, indent: int = 0):
	var prefix = "  ".repeat(indent)
	print(prefix + node.name + " (" + node.get_class() + ")")
	for child in node.get_children():
		print_all_children(child, indent + 1)

func _on_close_pressed():
	print("=== UI: CLOSE BUTTON CLICKED ===")
	print("Button connected status: ", button_connected)
	close()

func open(target_player: BaseCharacter3D):
	print("=== UI: OPENING for player ===")
	player = target_player
	visible = true
	# Debug: Print current mouse mode
	print("Mouse mode on open: ", Input.mouse_mode)

func close():
	print("=== UI: CLOSING and emitting signal ===")
	visible = false
	inventory_closed.emit()
	player = null
	print("=== UI: CLOSE COMPLETE ===")

# Add this to debug ESC key
func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if visible:
			print("=== UI: ESC pressed, closing from UI ===")
			close()
