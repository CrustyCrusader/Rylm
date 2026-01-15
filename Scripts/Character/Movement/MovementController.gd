extends Node
class_name MovementController

var character: BaseCharacter3D = null


#region Movement States
enum MoveState { STANDING, WALKING, RUNNING, CROUCHING, JUMPING }
var current_move_state: MoveState = MoveState.STANDING
#endregion

#region Movement Parameters
@export var walk_speed: float = 5.0
@export var run_speed: float = 10.0
@export var crouch_speed: float = 2.5
@export var jump_velocity: float = 6.0
@export var acceleration: float = 15.0
@export var deceleration: float = 20.0

@export var run_stamina_cost: float = 15.0  # per second
@export var jump_stamina_cost: float = 20.0
#endregion

var speed_multiplier: float = 1.0
var is_stunned: bool = false
var stun_timer: float = 0.0

func process_movement(delta: float):
	if not character:
		print("MovementController: No character reference!")
		return
	
	if is_stunned:
		stun_timer -= delta
		if stun_timer <= 0:
			is_stunned = false
		return
	
	# Get input from player or AI
	var move_direction = get_movement_direction()
	
	
	# Apply movement based on state
	match current_move_state:
		MoveState.STANDING:
			handle_standing(delta, move_direction)
		MoveState.WALKING:
			handle_walking(delta, move_direction)
		MoveState.RUNNING:
			handle_running(delta, move_direction)
		MoveState.CROUCHING:
			handle_crouching(delta, move_direction)
		MoveState.JUMPING:
			handle_jumping(delta, move_direction)
	
	# Apply gravity
	if not character.is_on_floor():
		character.velocity.y -= 9.8 * delta
		print("Applying gravity, velocity.y: ", character.velocity.y)  # DEBUG

func get_movement_direction() -> Vector3:
	# This should be overridden by PlayerMovementController or AI
	return Vector3.ZERO

func handle_standing(delta: float, _direction: Vector3):
	# When standing, slow down to a stop
	character.velocity.x = move_toward(character.velocity.x, 0, deceleration * delta)
	character.velocity.z = move_toward(character.velocity.z, 0, deceleration * delta)
	print("Standing - Velocity: ", character.velocity)  # DEBUG

func handle_walking(delta: float, direction: Vector3):
	var target_speed = walk_speed * speed_multiplier
	
	if direction.length() > 0:
		var target_velocity = direction * target_speed
		character.velocity.x = move_toward(character.velocity.x, target_velocity.x, acceleration * delta)
		character.velocity.z = move_toward(character.velocity.z, target_velocity.z, acceleration * delta)
		
		print("Walking - Direction: ", direction, " Target Velocity: ", target_velocity, " Actual Velocity: ", character.velocity)  # DEBUG
	else:
		character.velocity.x = move_toward(character.velocity.x, 0, deceleration * delta)
		character.velocity.z = move_toward(character.velocity.z, 0, deceleration * delta)

func handle_running(delta: float, direction: Vector3):
	if not character.stats:
		handle_walking(delta, direction)
		return
	
	# Check if we have stamina to run
	var stamina_cost = run_stamina_cost * delta
	
	if character.stats.use_stamina(stamina_cost):
		var target_speed = run_speed * speed_multiplier
		
		if direction.length() > 0:
			var target_velocity = direction * target_speed
			character.velocity.x = move_toward(character.velocity.x, target_velocity.x, acceleration * delta)
			character.velocity.z = move_toward(character.velocity.z, target_velocity.z, acceleration * delta)
			
			print("Running - Velocity: ", character.velocity)  # DEBUG
		else:
			character.velocity.x = move_toward(character.velocity.x, 0, deceleration * delta)
			character.velocity.z = move_toward(character.velocity.z, 0, deceleration * delta)
	else:
		# Not enough stamina, switch to walking
		set_move_state(MoveState.WALKING)
		handle_walking(delta, direction)

func handle_crouching(delta: float, direction: Vector3):
	var target_speed = crouch_speed * speed_multiplier
	
	if direction.length() > 0:
		var target_velocity = direction * target_speed
		character.velocity.x = move_toward(character.velocity.x, target_velocity.x, acceleration * 0.5 * delta)
		character.velocity.z = move_toward(character.velocity.z, target_velocity.z, acceleration * 0.5 * delta)
	else:
		character.velocity.x = move_toward(character.velocity.x, 0, deceleration * 0.5 * delta)
		character.velocity.z = move_toward(character.velocity.z, 0, deceleration * 0.5 * delta)

func handle_jumping(delta: float, direction: Vector3):
	# Air control - reduced control while jumping
	var air_control_factor = 0.3
	var target_speed = walk_speed * speed_multiplier * air_control_factor
	
	if direction.length() > 0:
		var target_velocity = direction * target_speed
		character.velocity.x = move_toward(character.velocity.x, target_velocity.x, acceleration * air_control_factor * delta)
		character.velocity.z = move_toward(character.velocity.z, target_velocity.z, acceleration * air_control_factor * delta)
	
	# Check if we've landed
	if character.is_on_floor():
		if direction.length() > 0:
			set_move_state(MoveState.WALKING)
		else:
			set_move_state(MoveState.STANDING)

func set_speed_multiplier(multiplier: float):
	speed_multiplier = multiplier
	print("Speed multiplier set to: ", speed_multiplier)  # DEBUG

func set_move_state(new_state: MoveState):
	if current_move_state == new_state:
		return
	
	current_move_state = new_state
	print("Movement state changed to: ", MoveState.keys()[new_state])  # DEBUG
	
	# Play appropriate animation
	if character and character.has_node("AnimationPlayer"):
		var anim_player = character.get_node("AnimationPlayer")
		match new_state:
			MoveState.STANDING:
				anim_player.play("AnimationLibrary_Godot_Standard/Idle")
			MoveState.WALKING:
				anim_player.play("AnimationLibrary_Godot_Standard/Walk")
			MoveState.RUNNING:
				anim_player.play("AnimationLibrary_Godot_Standard/Sprint")
			MoveState.CROUCHING:
				anim_player.play("AnimationLibrary_Godot_Standard/Crouch")
			MoveState.JUMPING:
				anim_player.play("AnimationLibrary_Godot_Standard/Jump")
