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
var target: Node3D = null
var patrol_index: int = 0
var investigate_position: Vector3 = Vector3.ZERO


func _ready() -> void:
	# Safe casting to avoid GDScript type assignment errors
	character = get_parent() as BaseCharacter3D
	if not character:
		push_error("AIController must be a child of a BaseCharacter3D node!")
		return
	
	# Initialize patrol points if empty
	if patrol_points.is_empty():
		initialize_default_patrol_points()
	
	print("AIController ready for ", character.character_name)


func _process(delta: float) -> void:
	process_ai(delta)


func initialize_default_patrol_points() -> void:
	if character:
		var base_pos: Vector3 = character.global_position
		patrol_points = [
			base_pos + Vector3(5, 0, 0),
			base_pos + Vector3(0, 0, 5),
			base_pos + Vector3(-5, 0, 0),
			base_pos + Vector3(0, 0, -5)
		]
		print("Generated default patrol points for ", character.character_name)


func process_ai(delta: float) -> void:
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


# --- State Handlers ---

func process_idle(_delta: float) -> void:
	if character:
		character.movement = Vector3.ZERO


func process_patrol(_delta: float) -> void:
	if patrol_points.is_empty():
		set_state(AIState.IDLE)
		return
	
	var target_pos: Vector3 = patrol_points[patrol_index]
	var direction: Vector3 = (target_pos - character.global_position).normalized()
	direction.y = 0
	
	if character.global_position.distance_to(target_pos) < 1.5:
		patrol_index = (patrol_index + 1) % patrol_points.size()
		return
	
	if character:
		character.movement = direction
	
	if direction.length_squared() > 0.01:
		look_at_safe(character.global_position + direction)


func process_chase(_delta: float) -> void:
	if not target or not is_instance_valid(target):
		set_state(AIState.PATROL)
		return
	
	var direction: Vector3 = (target.global_position - character.global_position).normalized()
	direction.y = 0
	
	var distance: float = character.global_position.distance_to(target.global_position)
	
	if distance <= attack_range:
		set_state(AIState.ATTACK)
		return
	elif distance > detection_range * 1.5:
		target_lost()
		return
	
	if character:
		var run_multiplier: float = run_speed / move_speed if move_speed > 0 else 1.5
		character.movement = direction * run_multiplier
	
	look_at_safe(target.global_position)


func process_attack(_delta: float) -> void:
	if not target or not is_instance_valid(target):
		set_state(AIState.PATROL)
		return
	
	look_at_safe(target.global_position)
	
	if character:
		character.movement = Vector3.ZERO
	
	var distance: float = character.global_position.distance_to(target.global_position)
	if distance > attack_range * 1.5:
		set_state(AIState.CHASE)


func process_investigate(_delta: float) -> void:
	if investigate_position == Vector3.ZERO:
		set_state(AIState.PATROL)
		return
	
	var direction: Vector3 = (investigate_position - character.global_position).normalized()
	direction.y = 0
	
	if character.global_position.distance_to(investigate_position) < 1.5:
		set_state(AIState.PATROL)
		return
	
	if character:
		character.movement = direction
	
	if direction.length_squared() > 0.01:
		look_at_safe(character.global_position + direction)


# --- Helper Functions ---

## Safe wrapper for look_at to avoid Godot errors when target vector is identical or collinear
func look_at_safe(target_pos: Vector3) -> void:
	if not character:
		return
	
	var look_target: Vector3 = Vector3(target_pos.x, character.global_position.y, target_pos.z)
	if character.global_position.distance_squared_to(look_target) > 0.001:
		character.look_at(look_target, Vector3.UP)


# --- Public API ---

func set_state(new_state: AIState) -> void:
	if current_state == new_state:
		return
	
	current_state = new_state
	if character:
		print(character.character_name, " AI state: ", AIState.keys()[new_state])


func set_target(new_target: Node3D) -> void:
	target = new_target


func target_lost() -> void:
	target = null
	set_state(AIState.PATROL)
	if character:
		if character.has_node("AttackTimer"):
			character.get_node("AttackTimer").stop()
		if "can_attack" in character:
			character.can_attack = true
		if "is_attacking" in character:
			character.is_attacking = false
		print(character.character_name, " lost target, returning to patrol")


func can_see_target(check_target: Node3D) -> bool:
	if not check_target or not is_instance_valid(check_target) or not character:
		return false
	
	# 1. Distance Check
	var origin_pos: Vector3 = character.global_position + Vector3(0, 1.5, 0) # Eye offset
	var target_pos: Vector3 = check_target.global_position + Vector3(0, 1.5, 0)
	
	var distance: float = origin_pos.distance_to(target_pos)
	if distance > fov_distance:
		return false
	
	# 2. Field of View (FOV) Angle Check
	var direction_to_target: Vector3 = (target_pos - origin_pos).normalized()
	var forward: Vector3 = -character.global_transform.basis.z
	var angle: float = rad_to_deg(forward.angle_to(direction_to_target))
	
	if angle > fov_angle:
		return false
	
	# 3. Raycast Occlusion Check (Physics Direct Space State)
	var space_state = character.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(origin_pos, target_pos)
	
	# Exclude the character doing the raycast so it doesn't hit itself
	query.exclude = [character.get_rid()]
	
	# Set collision mask to check world geometry (e.g., Layer 1 for terrain/walls)
	query.collision_mask = 1
	
	var result = space_state.intersect_ray(query)
	
	if result:
		# If the ray hit something that isn't the target (or a child of target), sight is occluded by a wall/obstacle
		var hit_collider = result.collider
		if hit_collider != check_target and not check_target.is_ancestor_of(hit_collider):
			return false
	
	return true
