extends Node
class_name AIController

#region AI States
enum AIState { IDLE, PATROL, CHASE, ATTACK, INVESTIGATE }
var current_state = AIState.PATROL
#endregion

#region AI Properties
@export var patrol_points: Array[Vector3] = []
@export var move_speed: float = 4.0
@export var run_speed: float = 6.0
@export var detection_range: float = 10.0
@export var attack_range: float = 2.0
@export var fov_angle: float = 45.0
@export var fov_distance: float = 15.0
#endregion

#region Runtime Variables
var character: BaseCharacter3D = null
var target = null
var patrol_index: int = 0
var investigate_position: Vector3 = Vector3.ZERO
#endregion

func _ready():
	character = get_parent()
	if not character:
		push_error("AIController must be a child of a character!")
	
	# Initialize patrol points if empty
	if patrol_points.is_empty():
		initialize_default_patrol_points()

func initialize_default_patrol_points():
	# Create default patrol points around current position
	var positions = [
		Vector3(5, 0, 0),
		Vector3(0, 0, 5),
		Vector3(-5, 0, 0),
		Vector3(0, 0, -5)
	]
	
	for pos in positions:
		patrol_points.append(character.global_position + pos)

func process_ai(delta):
	if not character or not character.is_alive:
		return
	
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

#region State Processing
func process_idle(_delta):
	if character.movement:
		character.movement.set_move_state(character.movement.MoveState.STANDING)

func process_patrol(_delta):
	if patrol_points.is_empty():
		set_state(AIState.IDLE)
		return
	
	var target_pos = patrol_points[patrol_index]
	var direction = (target_pos - character.global_position).normalized()
	direction.y = 0
	
	if character.movement:
		character.movement.set_move_state(character.movement.MoveState.WALKING)
		character.velocity.x = direction.x * move_speed
		character.velocity.z = direction.z * move_speed
		character.look_at(character.global_position + direction, Vector3.UP)
	
	# Check if reached point
	if character.global_position.distance_to(target_pos) < 1.5:
		patrol_index = (patrol_index + 1) % patrol_points.size()
		set_state(AIState.IDLE)
		# Return to patrol after idle
		await get_tree().create_timer(1.0).timeout
		set_state(AIState.PATROL)

func process_chase(_delta):
	if not target or not is_instance_valid(target):
		set_state(AIState.PATROL)
		return
	
	# Only print state changes, not every frame
	# print(character.character_name, " chasing ", target.character_name)
	
	var direction = (target.global_position - character.global_position).normalized()
	direction.y = 0
	
	if character.movement:
		character.movement.set_move_state(character.movement.MoveState.RUNNING)
		character.velocity.x = direction.x * run_speed
		character.velocity.z = direction.z * run_speed
		character.look_at(target.global_position, Vector3.UP)
	
	# Check attack range
	var distance = character.global_position.distance_to(target.global_position)
	if distance <= attack_range:
		set_state(AIState.ATTACK)
	elif distance > detection_range * 1.5:
		target_lost()

func process_attack(_delta):
	if not target or not is_instance_valid(target):
		set_state(AIState.PATROL)
		return
	
	# Face target
	var direction = (target.global_position - character.global_position).normalized()
	direction.y = 0
	if direction.length() > 0:
		character.look_at(target.global_position, Vector3.UP)
	
	# Stop moving while attacking
	character.velocity = Vector3.ZERO
	
	# Let EnemyCharacter handle actual attack timing
	# We just check if target moved away
	var distance = character.global_position.distance_to(target.global_position)
	if distance > attack_range * 1.5:
		set_state(AIState.CHASE)
		
	
func process_investigate(_delta):
	var direction = (investigate_position - character.global_position).normalized()
	direction.y = 0
	
	if character.movement:
		character.movement.set_move_state(character.movement.MoveState.WALKING)
		character.velocity.x = direction.x * move_speed
		character.velocity.z = direction.z * move_speed
		character.look_at(character.global_position + direction, Vector3.UP)
	
	# Reached investigation point
	if character.global_position.distance_to(investigate_position) < 1.5:
		set_state(AIState.PATROL)
#endregion

#region Public API
func set_state(new_state):
	if current_state == new_state:
		return
	
	current_state = new_state
	
	# Print state changes (only when state actually changes)
	print(character.character_name, " state: ", AIState.keys()[new_state])

func set_target(new_target):
	target = new_target

func target_lost():
	target = null
	set_state(AIState.PATROL)
	print(character.character_name, " lost target, returning to patrol")

func can_see_target(check_target) -> bool:
	if not check_target:
		return false
	
	var distance = character.global_position.distance_to(check_target.global_position)
	if distance > fov_distance:
		return false
	
	var direction_to_target = (check_target.global_position - character.global_position).normalized()
	var forward = -character.global_transform.basis.z
	var angle = rad_to_deg(forward.angle_to(direction_to_target))
	
	return angle <= fov_angle
#endregion
