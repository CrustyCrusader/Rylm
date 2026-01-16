extends Node
class_name InputManager

# Input Action Signals
# signal input_action_triggered(action: String, strength: float)  # Commented out for now
signal input_mode_changed(mode: String)  # "gameplay", "ui", "dialog"
signal controller_connected(device_id: int)
signal controller_disconnected(device_id: int)

# Input Modes
enum InputMode {
	GAMEPLAY,
	UI,
	DIALOG,
	CUTSCENE
}

var current_input_mode: InputMode = InputMode.GAMEPLAY
var mouse_sensitivity: float = 0.002
var controller_sensitivity: float = 2.0
var invert_y_axis: bool = false
var input_buffer: Array = []  # For input buffering/queuing

# Controller support
var controller_connected_bool: bool = false
var current_controller_id: int = -1
var deadzone: float = 0.15

func _ready():
	print("InputManager loaded")
	setup_input_actions()
	
	# Detect controller connection
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	check_controllers()

func _process(_delta):
	process_input_buffer()
	detect_input_mode_changes()

func setup_input_actions():
	# Define input actions if they don't exist
	var actions = [
		"move_forward", "move_backward", "move_left", "move_right",
		"jump", "run", "crouch", "inventory", "attack", "interact",
		"pause", "quick_save", "quick_load"
	]
	
	for action in actions:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			print("Added input action: ", action)

func set_input_mode(mode: InputMode):
	if current_input_mode != mode:
		current_input_mode = mode
		var mode_names = ["GAMEPLAY", "UI", "DIALOG", "CUTSCENE"]
		print("Input mode changed to: ", mode_names[mode])
		input_mode_changed.emit(mode_names[mode])

func get_mouse_look() -> Vector2:
	if current_input_mode != InputMode.GAMEPLAY:
		return Vector2.ZERO
	
	var mouse_input = Input.get_last_mouse_velocity()
	var sensitivity = mouse_sensitivity
	
	if invert_y_axis:
		mouse_input.y = -mouse_input.y
	
	return mouse_input * sensitivity

func get_movement_vector() -> Vector3:
	if current_input_mode != InputMode.GAMEPLAY:
		return Vector3.ZERO
	
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	return Vector3(input_dir.x, 0, input_dir.y)

func is_action_just_pressed(action: String) -> bool:
	if is_input_blocked_for_action(action):
		return false
	return Input.is_action_just_pressed(action)

func is_action_pressed(action: String) -> bool:
	if is_input_blocked_for_action(action):
		return false
	return Input.is_action_pressed(action)

func is_input_blocked_for_action(action: String) -> bool:
	match current_input_mode:
		InputMode.UI:
			# In UI mode, only allow UI navigation and escape
			return not action in ["ui_cancel", "ui_accept", "ui_up", "ui_down", "ui_left", "ui_right"]
		InputMode.DIALOG:
			# In dialog mode, only allow dialog controls
			return not action in ["ui_accept", "ui_cancel", "skip_dialog"]
		InputMode.CUTSCENE:
			# In cutscene, only allow skipping
			return not action in ["skip_cutscene", "ui_cancel"]
	return false

func buffer_input(action: String, strength: float = 1.0):
	# Buffer input for later processing (for combo systems, etc.)
	input_buffer.append({
		"action": action,
		"strength": strength,
		"timestamp": Time.get_ticks_msec()
	})
	
	# Keep buffer size reasonable
	if input_buffer.size() > 10:
		input_buffer.pop_front()

func process_input_buffer():
	var current_time = Time.get_ticks_msec()
	
	# Remove old inputs (older than 500ms)
	input_buffer = input_buffer.filter(func(input): 
		return current_time - input.timestamp < 500
	)

func detect_input_mode_changes():
	# Auto-switch to UI mode when inventory is open
	var ui_elements = get_tree().get_nodes_in_group("ui_active")
	if ui_elements.size() > 0 and current_input_mode == InputMode.GAMEPLAY:
		set_input_mode(InputMode.UI)
	elif ui_elements.size() == 0 and current_input_mode == InputMode.UI:
		set_input_mode(InputMode.GAMEPLAY)

func check_controllers():
	var devices = Input.get_connected_joypads()
	if devices.size() > 0:
		controller_connected_bool = true
		current_controller_id = devices[0]
		controller_connected.emit(current_controller_id)
		print("Controller connected: ", Input.get_joy_name(current_controller_id))

func _on_joy_connection_changed(device_id: int, connected: bool):
	if connected:
		controller_connected_bool = true
		current_controller_id = device_id
		controller_connected.emit(device_id)
		print("Controller connected: ", Input.get_joy_name(device_id))
	else:
		controller_connected_bool = false
		current_controller_id = -1
		controller_disconnected.emit(device_id)
		print("Controller disconnected")

# Get controller stick input with deadzone
func get_controller_stick(stick: String) -> Vector2:
	if not controller_connected_bool:
		return Vector2.ZERO
	
	var input = Vector2.ZERO
	
	match stick:
		"left":
			input.x = Input.get_joy_axis(current_controller_id, JOY_AXIS_LEFT_X)
			input.y = Input.get_joy_axis(current_controller_id, JOY_AXIS_LEFT_Y)
		"right":
			input.x = Input.get_joy_axis(current_controller_id, JOY_AXIS_RIGHT_X)
			input.y = Input.get_joy_axis(current_controller_id, JOY_AXIS_RIGHT_Y)
	
	# Apply deadzone
	if input.length() < deadzone:
		return Vector2.ZERO
	
	return input.normalized() * ((input.length() - deadzone) / (1.0 - deadzone))

# For debug/console commands
func print_input_state():
	print("=== Input Manager State ===")
	print("Mode: ", ["GAMEPLAY", "UI", "DIALOG", "CUTSCENE"][current_input_mode])
	print("Controller Connected: ", controller_connected_bool)
	print("Mouse Sensitivity: ", mouse_sensitivity)
	print("Input Buffer Size: ", input_buffer.size())
