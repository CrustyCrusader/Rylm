# Physics/PhysicsHandler.gd
class_name PhysicsHandler
extends Node

# Signals
signal collision_detected(collision_point: Vector3, force: float, object: Node)
signal surface_changed(surface_type: String, friction: float, normal: Vector3)

# Physics properties
var current_surface_type: String = "default"
var current_friction: float = 1.0
var gravity_multiplier: float = 1.0
var mass: float = 70.0  # kg

# Character reference
var character: BaseCharacter3D

func initialize(character_ref: BaseCharacter3D) -> void:
	character = character_ref
	print("PhysicsHandler initialized for: ", character.character_name)

func process_physics(delta: float) -> void:
	if not character or not character.is_alive:
		return
	
	# Apply gravity
	apply_gravity(delta)
	
	# Check for collisions
	check_collisions(delta)
	
	# Update surface information
	update_surface_info()

func apply_gravity(delta: float) -> void:
	if not character:
		return
	
	var gravity = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
	character.velocity.y -= gravity * gravity_multiplier * delta

func check_collisions(delta: float) -> void:
	if not character:
		return
	
	# Raycast for ground detection
	var space_state = character.get_world_3d().direct_space_state
	var origin = character.global_position
	var end = origin - Vector3(0, 2.0, 0)
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.exclude = [character]
	
	var result = space_state.intersect_ray(query)
	if result:
		var collision_point = result.position
		var normal = result.normal
		var collision_force = character.velocity.length() * mass
		
		if collision_force > 10.0:
			collision_detected.emit(collision_point, collision_force, result.collider)

func update_surface_info() -> void:
	if not character:
		return
	
	# Raycast for surface detection
	var space_state = character.get_world_3d().direct_space_state
	var origin = character.global_position
	var end = origin - Vector3(0, 1.0, 0)
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.exclude = [character]
	
	var result = space_state.intersect_ray(query)
	if result:
		var collider = result.collider
		var new_surface_type = detect_surface_type(collider)
		var new_friction = detect_friction(collider)
		var normal = result.normal
		
		if new_surface_type != current_surface_type or abs(new_friction - current_friction) > 0.1:
			current_surface_type = new_surface_type
			current_friction = new_friction
			surface_changed.emit(new_surface_type, new_friction, normal)
			
			# Update character movement based on surface
			if character and character.movement:
				character.movement.set_friction_multiplier(new_friction)

func detect_surface_type(collider: Node) -> String:
	if collider.is_in_group("water"):
		return "water"
	elif collider.is_in_group("ice"):
		return "ice"
	elif collider.is_in_group("mud"):
		return "mud"
	elif collider.is_in_group("sand"):
		return "sand"
	elif collider.is_in_group("grass"):
		return "grass"
	else:
		return "default"

func detect_friction(collider: Node) -> float:
	match detect_surface_type(collider):
		"water":
			return 0.3
		"ice":
			return 0.1
		"mud":
			return 0.4
		"sand":
			return 0.6
		"grass":
			return 0.8
		_:
			return 1.0

func set_gravity_multiplier(multiplier: float) -> void:
	gravity_multiplier = multiplier

func get_gravity_multiplier() -> float:
	return gravity_multiplier

func set_mass(new_mass: float) -> void:
	mass = new_mass

func get_mass() -> float:
	return mass

func get_surface_info() -> Dictionary:
	return {
		"surface_type": current_surface_type,
		"friction": current_friction
	}

# Helper methods to emit signals
func emit_collision_signal(collision_point: Vector3, force: float, object: Node) -> void:
	collision_detected.emit(collision_point, force, object)

func emit_surface_signal(surface_type: String, friction: float, normal: Vector3) -> void:
	surface_changed.emit(surface_type, friction, normal)

func apply_impulse(impulse: Vector3) -> void:
	if character:
		character.velocity += impulse / mass
