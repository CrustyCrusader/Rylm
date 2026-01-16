# Character/Movement/NavigationComponent.gd
extends Node
class_name NavigationComponent

signal destination_reached
signal path_changed(new_path)
signal obstacle_detected(obstacle)

@export var nav_agent: NavigationAgent3D
@export var move_speed: float = 5.0
@export var stopping_distance: float = 0.5
@export var repath_interval: float = 0.5  # seconds

var character: BaseCharacter3D
var current_path: PackedVector3Array = []
var current_target: Vector3 = Vector3.ZERO
var is_navigating: bool = false
var repath_timer: float = 0.0

func _ready():
	character = get_parent() as BaseCharacter3D
	
	if not nav_agent:
		nav_agent = NavigationAgent3D.new()
		add_child(nav_agent)
		nav_agent.path_desired_distance = 1.0
		nav_agent.target_desired_distance = stopping_distance
		nav_agent.path_max_distance = 50.0

func _process(delta):
	if not is_navigating or not character:
		return
	
	# Update repath timer
	repath_timer -= delta
	if repath_timer <= 0:
		update_navigation_path()
		repath_timer = repath_interval
	
	# Follow current path
	if current_path.size() > 0:
		follow_path(delta)

func set_destination(destination: Vector3) -> bool:
	if not character or not nav_agent:
		return false
	
	current_target = destination
	is_navigating = true
	
	# Set navigation agent target
	nav_agent.target_position = destination
	
	# Get initial path
	update_navigation_path()
	
	print(character.character_name, " navigating to ", destination)
	return true

func update_navigation_path():
	if not nav_agent:
		return
	
	# Get the next path point from navigation agent
	var next_position = nav_agent.get_next_path_position()
	
	# Update current path
	if current_path.size() > 0:
		current_path.remove_at(0)
	
	if next_position != Vector3.ZERO:
		current_path.append(next_position)
		path_changed.emit(current_path)

func follow_path(delta: float):
	if current_path.size() == 0:
		return
	
	var target_position = current_path[0]
	var direction = (target_position - character.global_position).normalized()
	
	# Move character
	if character.velocity:
		character.velocity.x = direction.x * move_speed
		character.velocity.z = direction.z * move_speed
	
	# Rotate toward movement direction
	if direction.length() > 0.1:
		var target_rotation = atan2(direction.x, direction.z)
		character.rotation.y = lerp_angle(character.rotation.y, target_rotation, 10.0 * delta)
	
	# Check if reached current waypoint
	if character.global_position.distance_to(target_position) < stopping_distance:
		current_path.remove_at(0)
		
		# Check if reached final destination
		if current_path.size() == 0 and character.global_position.distance_to(current_target) < stopping_distance:
			stop_navigation()
			destination_reached.emit()

func stop_navigation():
	is_navigating = false
	current_path.clear()
	
	if character.velocity:
		character.velocity.x = 0
		character.velocity.z = 0
	
	print(character.character_name, " stopped navigation")

func get_distance_to_destination() -> float:
	if not is_navigating:
		return 0.0
	
	return character.global_position.distance_to(current_target)

func is_destination_reachable() -> bool:
	if not nav_agent:
		return false
	
	# Check if path is valid
	return nav_agent.is_target_reachable()

func avoid_obstacle(obstacle_position: Vector3, avoidance_distance: float = 3.0):
	# Calculate avoidance direction
	var to_obstacle = character.global_position - obstacle_position
	var avoidance_direction = to_obstacle.normalized()
	
	# Calculate new target
	var avoidance_target = character.global_position + avoidance_direction * avoidance_distance
	
	# Set new destination
	set_destination(avoidance_target)
	obstacle_detected.emit(obstacle_position)
