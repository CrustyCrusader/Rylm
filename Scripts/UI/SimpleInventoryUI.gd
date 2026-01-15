extends CanvasLayer
class_name SimpleInventoryUI

signal inventory_closed

@export var close_button: Button
var player: BaseCharacter3D = null

func _ready():
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	visible = false

func _on_close_pressed():
	print("=== UI: CLOSE BUTTON CLICKED ===")
	close()

func open(target_player: BaseCharacter3D):
	print("=== UI: OPENING for player ===")
	player = target_player
	visible = true

func close():
	print("=== UI: CLOSING and emitting signal ===")
	visible = false
	inventory_closed.emit()  # ✅ Emit the signal
	player = null
	# DON'T set mouse mode here - let Player handle it
	print("=== UI: CLOSE COMPLETE ===")
