extends MovementController
class_name PlayerMovementController

func get_movement_direction() -> Vector3:
	var input_dir = Vector2.ZERO
	
	# Get 2D input direction
	if Input.is_action_pressed("forward"):
		input_dir.y -= 1
	if Input.is_action_pressed("backward"):
		input_dir.y += 1
	if Input.is_action_pressed("left"):
		input_dir.x -= 1
	if Input.is_action_pressed("right"):
		input_dir.x += 1
	
	# Normalize if moving diagonally
	input_dir = input_dir.normalized()
	
	# Convert to 3D direction relative to character's orientation
	var direction = Vector3.ZERO
	if character:
		direction = character.transform.basis * Vector3(input_dir.x, 0, input_dir.y)
	
	return direction

func jump():
	if character and character.is_on_floor():
		# Check stamina if needed
		if character.stats and not character.stats.use_stamina(jump_stamina_cost):
			return false
		
		character.velocity.y = jump_velocity
		set_move_state(MoveState.JUMPING)
		return true
	return false
