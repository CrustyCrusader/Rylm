extends Node
class_name MovementController

# Signals for state and animation
signal movement_state_changed(new_state)
signal animation_requested(animation_name)

# Character reference
var character: CharacterBody3D = null

# Movement states
enum MoveState { STANDING, WALKING, RUNNING, CROUCHING, JUMPING }
var current_move_state: MoveState = MoveState.STANDING
var previous_state: MoveState = MoveState.STANDING

# Movement parameters
@export var walk_speed: float = 5.0
@export var run_speed: float = 10.0
@export var crouch_speed: float = 2.5
@export var jump_velocity: float = 6.0
@export var acceleration: float = 15.0
@export var deceleration: float = 20.0

# Animation names with library prefix
@export var idle_animation: String = "AnimationLibrary_Godot_Standard/Idle"
@export var walk_animation: String = "AnimationLibrary_Godot_Standard/Walk"
@export var run_animation: String = "AnimationLibrary_Godot_Standard/Sprint"
@export var crouch_animation: String = "AnimationLibrary_Godot_Standard/Crouch_Idle"
@export var jump_animation: String = "AnimationLibrary_Godot_Standard/Jump"

# State management
var speed_multiplier: float = 1.0
var is_stunned: bool = false

func initialize(character_node: CharacterBody3D) -> void:
	character = character_node
	print("MovementController: Initialized for ", character.name)
	_update_animations()

func process_movement(delta: float, direction: Vector3) -> void:
	if not character or is_stunned:
		return
	
	# Handle movement based on current state
	match current_move_state:
		MoveState.STANDING:
			_handle_standing(delta, direction)
		MoveState.WALKING:
			_handle_walking(delta, direction)
		MoveState.RUNNING:
			_handle_running(delta, direction)
		MoveState.CROUCHING:
			_handle_crouching(delta, direction)
		MoveState.JUMPING:
			_handle_jumping(delta, direction)
	
	# Apply gravity
	if not character.is_on_floor():
		character.velocity.y -= 9.8 * delta
		# Switch to jump state if falling
		if current_move_state != MoveState.JUMPING and character.velocity.y < 0:
			set_move_state(MoveState.JUMPING)
	else:
		# Reset vertical velocity on floor
		if character.velocity.y < 0:
			character.velocity.y = 0
		# Land from jump state
		if current_move_state == MoveState.JUMPING and character.is_on_floor():
			if direction.length() > 0.1:
				if Input.is_action_pressed("sprint"):
					set_move_state(MoveState.RUNNING)
				else:
					set_move_state(MoveState.WALKING)
			else:
				set_move_state(MoveState.STANDING)
	
	# Move the character
	character.move_and_slide()

func _handle_standing(delta: float, _direction: Vector3) -> void:
	character.velocity.x = move_toward(character.velocity.x, 0, deceleration * delta)
	character.velocity.z = move_toward(character.velocity.z, 0, deceleration * delta)

func _handle_walking(delta: float, direction: Vector3) -> void:
	if direction.length() > 0.1:
		var target_velocity = direction * walk_speed * speed_multiplier
		character.velocity.x = move_toward(character.velocity.x, target_velocity.x, acceleration * delta)
		character.velocity.z = move_toward(character.velocity.z, target_velocity.z, acceleration * delta)
	else:
		_handle_standing(delta, direction)

func _handle_running(delta: float, direction: Vector3) -> void:
	if direction.length() > 0.1:
		var target_velocity = direction * run_speed * speed_multiplier
		character.velocity.x = move_toward(character.velocity.x, target_velocity.x, acceleration * delta)
		character.velocity.z = move_toward(character.velocity.z, target_velocity.z, acceleration * delta)
	else:
		_handle_standing(delta, direction)

func _handle_crouching(delta: float, direction: Vector3) -> void:
	if direction.length() > 0.1:
		var target_velocity = direction * crouch_speed * speed_multiplier
		character.velocity.x = move_toward(character.velocity.x, target_velocity.x, acceleration * 0.5 * delta)
		character.velocity.z = move_toward(character.velocity.z, target_velocity.z, acceleration * 0.5 * delta)
	else:
		character.velocity.x = move_toward(character.velocity.x, 0, deceleration * 0.5 * delta)
		character.velocity.z = move_toward(character.velocity.z, 0, deceleration * 0.5 * delta)

func _handle_jumping(delta: float, direction: Vector3) -> void:
	# Air control
	if direction.length() > 0.1:
		var target_velocity = direction * walk_speed * speed_multiplier * 0.3
		character.velocity.x = move_toward(character.velocity.x, target_velocity.x, acceleration * 0.3 * delta)
		character.velocity.z = move_toward(character.velocity.z, target_velocity.z, acceleration * 0.3 * delta)

func set_move_state(new_state: MoveState) -> void:
	if current_move_state == new_state:
		return
	
	previous_state = current_move_state
	current_move_state = new_state
	
	print("Movement state: ", MoveState.keys()[previous_state], " -> ", MoveState.keys()[new_state])
	emit_signal("movement_state_changed", new_state)
	_update_animations()

func _update_animations() -> void:
	if not character:
		return
	
	match current_move_state:
		MoveState.STANDING:
			emit_signal("animation_requested", idle_animation)
		MoveState.WALKING:
			emit_signal("animation_requested", walk_animation)
		MoveState.RUNNING:
			emit_signal("animation_requested", run_animation)
		MoveState.CROUCHING:
			emit_signal("animation_requested", crouch_animation)
		MoveState.JUMPING:
			emit_signal("animation_requested", jump_animation)

func jump() -> bool:
	if character and character.is_on_floor():
		character.velocity.y = jump_velocity
		set_move_state(MoveState.JUMPING)
		print("Jump! Velocity: ", character.velocity)
		return true
	return false

func get_velocity() -> Vector3:
	return character.velocity if character else Vector3.ZERO

func is_moving() -> bool:
	return character and character.velocity.length() > 0.1
