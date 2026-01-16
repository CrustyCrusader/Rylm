extends MovementController
class_name PlayerMovementController

# Camera reference
var camera: Camera3D = null

# Input action names
@export var forward_action: String = "forward"
@export var backward_action: String = "backward"
@export var left_action: String = "left"
@export var right_action: String = "right"
@export var jump_action: String = "jump"
@export var sprint_action: String = "sprint"
@export var crouch_action: String = "crouch"

# Crouching state
var is_crouching: bool = false

func _ready() -> void:
	print("PlayerMovementController: Ready")
	camera = get_viewport().get_camera_3d()
	if camera:
		print("Found camera: ", camera.name)
	else:
		print("WARNING: No camera found!")

func _physics_process(delta: float) -> void:
	if not character:
		print("No character reference!")
		return
	
	var move_direction = get_movement_direction()
	_handle_input()
	_update_state(move_direction)
	process_movement(delta, move_direction)

func _handle_input() -> void:
	# Crouch toggle
	if Input.is_action_just_pressed(crouch_action):
		is_crouching = !is_crouching
		if is_crouching:
			set_move_state(MoveState.CROUCHING)
	
	# Jump
	if Input.is_action_just_pressed(jump_action):
		print("Jump button pressed")
		jump()

func _update_state(move_direction: Vector3) -> void:
	# Skip state updates if crouching or jumping
	if character.is_on_floor() and not is_crouching and current_move_state != MoveState.JUMPING:
		if move_direction.length() > 0.1:
			if Input.is_action_pressed(sprint_action):
				set_move_state(MoveState.RUNNING)
			else:
				set_move_state(MoveState.WALKING)
		else:
			if current_move_state in [MoveState.WALKING, MoveState.RUNNING]:
				set_move_state(MoveState.STANDING)

func get_movement_direction() -> Vector3:
	# Get 2D input
	var input_dir = Input.get_vector(left_action, right_action, forward_action, backward_action)
	
	# Return zero if no input
	if input_dir.length() < 0.1:
		return Vector3.ZERO
	
	# Camera-relative movement
	if camera:
		var camera_basis = camera.global_transform.basis
		var forward = camera_basis.z  # Camera looks down -Z, so Z is forward
		var right = camera_basis.x
		
		# Flatten to horizontal plane
		forward.y = 0
		right.y = 0
		
		# Normalize
		forward = forward.normalized()
		right = right.normalized()
		
		# Calculate direction
		var direction = (forward * input_dir.y) + (right * input_dir.x)
		
		if direction.length() > 0.1:
			print("Input: ", input_dir, " Direction: ", direction)
		
		return direction.normalized()
	
	# Fallback to global axes
	return Vector3(-input_dir.x, 0, -input_dir.y).normalized()
