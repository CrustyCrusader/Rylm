extends Node
class_name AIController

# AI States
enum AIState { IDLE, PATROL, CHASE, ATTACK, INVESTIGATE }
var current_state: AIState = AIState.PATROL

# AI Properties
@export var patrol_points: Array[Vector3] = []
@export var move_speed: float = 4.0
@export var run_speed: float = 6.0
@export var detection_range: float = 10.0
@export var attack_range: float = 2.0
@export var fov_angle: float = 45.0
@export var fov_distance: float = 15.0

# Runtime Variables
var character: BaseCharacter3D = null
var target = null
var patrol_index: int = 0
var investigate_position: Vector3 = Vector3.ZERO

func _ready() -> void:
	character = get_parent()
	if not character:
		push_error("AIController must be a child of a character!")
	
	# Initialize patrol points if empty
	if patrol_points.is_empty():
		initialize_default_patrol_points()
	
	print("AIController ready for ", character.character_name)

func initialize_default_patrol_points() -> void:
	# Create default patrol points around current position
	if character:
		var base_pos = character.global_position
		patrol_points = [
			base_pos + Vector3(5, 0, 0),
			base_pos + Vector3(0, 0, 5),
			base_pos + Vector3(-5, 0, 0),
			base_pos + Vector3(0, 0, -5)
		]
		print("Generated default patrol points")

func process_ai(delta: float) -> void:
	if not character or not character.is_alive:
		return
	
	# Process current state
	match current_state:
		AIState.IDLE:
			process_idle(delta)
		AIState.PATROL:
			process_patrol(delta)
		AIState.CHASE:
			process_chase(delta)
		AIState.ATTACK:
			process_attack(delta)
		AIState.INVESTIGATE:
			process_investigate(delta)

# State Processing
func process_idle(_delta: float) -> void:
	if character and character.movement:
		character.movement.set_move_state(character.movement.MoveState.STANDING)
		character.velocity = Vector3.ZERO

func process_patrol(delta: float) -> void:
	if patrol_points.is_empty():
		set_state(AIState.IDLE)
		return
	
	var target_pos = patrol_points[patrol_index]
	var direction = (target_pos - character.global_position).normalized()
	direction.y = 0
	
	# Use MovementController for movement
	if character and character.movement:
		character.movement.set_move_state(character.movement.MoveState.WALKING)
		character.movement.process_movement(delta, direction)
	
	# Rotate toward movement direction
	if direction.length() > 0.1:
		character.look_at(character.global_position + direction, Vector3.UP)
	
	# Check if reached point
	if character.global_position.distance_to(target_pos) < 1.5:
		# Go to next point
		patrol_index = (patrol_index + 1) % patrol_points.size()
		set_state(AIState.IDLE)
		# Return to patrol after idle
		await get_tree().create_timer(randf_range(1.0, 3.0)).timeout
		set_state(AIState.PATROL)

func process_chase(delta: float) -> void:
	if not target or not is_instance_valid(target):
		set_state(AIState.PATROL)
		return
	
	var direction = (target.global_position - character.global_position).normalized()
	direction.y = 0
	
	# Use MovementController for movement
	if character and character.movement:
		character.movement.set_move_state(character.movement.MoveState.RUNNING)
		character.movement.process_movement(delta, direction)
	
	# Face target
	if direction.length() > 0.1:
		character.look_at(target.global_position, Vector3.UP)
	
	# Check attack range
	var distance = character.global_position.distance_to(target.global_position)
	if distance <= attack_range:
		set_state(AIState.ATTACK)
	elif distance > detection_range * 1.5:
		target_lost()

func process_attack(_delta: float) -> void:
	if not target or not is_instance_valid(target):
		set_state(AIState.PATROL)
		return
	
	# Face target
	var direction = (target.global_position - character.global_position).normalized()
	direction.y = 0
	if direction.length() > 0:
		character.look_at(target.global_position, Vector3.UP)
	
	# Let EnemyCharacter handle actual attack timing
	var distance = character.global_position.distance_to(target.global_position)
	if distance > attack_range * 1.5:
		set_state(AIState.CHASE)

func process_investigate(delta: float) -> void:
	if investigate_position == Vector3.ZERO:
		set_state(AIState.PATROL)
		return
	
	var direction = (investigate_position - character.global_position).normalized()
	direction.y = 0
	
	if character and character.movement:
		character.movement.set_move_state(character.movement.MoveState.WALKING)
		character.movement.process_movement(delta, direction)
	
	# Face investigation direction
	if direction.length() > 0.1:
		character.look_at(character.global_position + direction, Vector3.UP)
	
	# Reached investigation point
	if character.global_position.distance_to(investigate_position) < 1.5:
		set_state(AIState.PATROL)

# Public API
func set_state(new_state: AIState) -> void:
	if current_state == new_state:
		return
	
	current_state = new_state
	print(character.character_name, " AI state: ", AIState.keys()[new_state])

func set_target(new_target) -> void:
	target = new_target

func target_lost() -> void:
	target = null
	set_state(AIState.PATROL)
	print(character.character_name, " lost target, returning to patrol")

func can_see_target(check_target) -> bool:
	if not check_target or not is_instance_valid(check_target):
		return false
	
	var distance = character.global_position.distance_to(check_target.global_position)
	if distance > fov_distance:
		return false
	
	var direction_to_target = (check_target.global_position - character.global_position).normalized()
	var forward = -character.global_transform.basis.z
	var angle = rad_to_deg(forward.angle_to(direction_to_target))
	
	return angle <= fov_angle
