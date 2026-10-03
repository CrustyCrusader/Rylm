class_name BaseCharacter3D
extends CharacterBody3D

signal health_changed(current_health: float, max_health: float)
signal died()

@export_group("Character Properties")
@export var character_name: String = "Survivor"
@export var character_type: String = "NPC"
@export var melee_attack_animation: String = "AnimationLibrary_Godot_Standard/Punch_Jab"
@export var max_health: float = 100.0
@export var move_speed: float = 5.0
@export var jump_velocity: float = 4.5

# Core State Variables
var current_health: float
var is_alive: bool = true
var is_attacking: bool = false
var movement_locked: bool = false
var speed_multiplier: float = 1.0
var movement: Vector3 = Vector3.ZERO

# --- COMPONENT & ANIMATION REFERENCES ---
@onready var inventory = get_node_or_null("InventoryComponent")
@onready var combat_component: CombatComponent = get_node_or_null("CombatComponent")
@onready var defense_component: DefenseComponent = get_node_or_null("DefenseComponent")

@onready var anim_player: AnimationPlayer = _find_anim_player()
@onready var anim_tree: AnimationTree = _find_anim_tree()


func _find_anim_player() -> AnimationPlayer:
	if has_node("%AnimationPlayer"):
		return get_node("%AnimationPlayer") as AnimationPlayer
	return find_child("AnimationPlayer", true, false) as AnimationPlayer


func _find_anim_tree() -> AnimationTree:
	if has_node("%AnimationTree"):
		return get_node("%AnimationTree") as AnimationTree
	return find_child("AnimationTree", true, false) as AnimationTree


# --- LIFECYCLE ---
func _ready() -> void:
	current_health = max_health
	_wire_component_signals()
	
	if anim_tree:
		anim_tree.active = true


func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	if not movement_locked:
		velocity.x = movement.x * move_speed * speed_multiplier
		velocity.z = movement.z * move_speed * speed_multiplier
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	if not is_on_floor():
		velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity", 9.8) * delta

	move_and_slide()
	update_animations()


# --- ANIMATION SYSTEM ---
func update_animations() -> void:
	var horizontal_speed := Vector3(velocity.x, 0.0, velocity.z).length()

	# 1. AnimationTree Path (BlendSpace)
	if anim_tree and anim_tree.active:
		anim_tree.set("parameters/locomotion/blend_position", horizontal_speed)
		return

	# 2. AnimationPlayer Path
	if not anim_player or is_attacking or movement_locked:
		return

	if horizontal_speed < 0.1:
		_play_anim_if_exists("AnimationLibrary_Godot_Standard/Idle")
	elif horizontal_speed > move_speed * 1.1:
		_play_anim_if_exists("AnimationLibrary_Godot_Standard/Sprint")
	else:
		_play_anim_if_exists("AnimationLibrary_Godot_Standard/Walk")


func _play_anim_if_exists(anim_name: String) -> void:
	if anim_player and anim_player.has_animation(anim_name):
		if anim_player.current_animation != anim_name:
			anim_player.play(anim_name)


# --- ACTION & COMBAT METHODS ---
func stop_movement() -> void:
	movement = Vector3.ZERO
	velocity.x = 0.0
	velocity.z = 0.0


func jump() -> void:
	if is_on_floor() and is_alive and not movement_locked:
		velocity.y = jump_velocity


func perform_melee_attack(target_character: BaseCharacter3D = null, armor_pen: float = 0.0) -> float:
	if not is_alive or movement_locked or is_attacking:
		return 0.0

	is_attacking = true
	movement_locked = true
	stop_movement()

	# 1. Play Punch Animation
	if anim_player and anim_player.has_animation(melee_attack_animation):
		anim_player.play(melee_attack_animation)
		if not anim_player.animation_finished.is_connected(_on_attack_animation_finished):
			anim_player.animation_finished.connect(_on_attack_animation_finished, CONNECT_ONE_SHOT)
	else:
		get_tree().create_timer(0.4).timeout.connect(func():
			is_attacking = false
			movement_locked = false
		)

	# 2. Find target in front if target_character wasn't passed directly
	var final_target: BaseCharacter3D = target_character
	if not final_target:
		final_target = _find_target_in_front()

	# 3. Apply Damage
	if combat_component and final_target:
		var target_defense: DefenseComponent = final_target.defense_component if final_target else null
		return combat_component.execute_attack(target_defense, armor_pen)

	return 0.0


func _find_target_in_front() -> BaseCharacter3D:
	# Check RayCast3D if attached to character/camera
	var raycast = get_node_or_null("MeleeRayCast3D")
	if raycast and raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider is BaseCharacter3D and collider != self:
			return collider

	# Fallback distance check to any target node within 2.2 meters
	var target_group := "enemy" if is_in_group("player") else "player"
	for node in get_tree().get_nodes_in_group(target_group):
		if node is BaseCharacter3D and node != self and node.is_alive:
			var dist = global_position.distance_to(node.global_position)
			if dist <= 2.2:
				return node

	return null


func _on_attack_animation_finished(_anim_name: String) -> void:
	is_attacking = false
	movement_locked = false


# --- DAMAGE & HEALTH ---
func take_damage(raw_damage: float, armor_pen: float = 0.0) -> void:
	if not is_alive:
		return

	var final_damage := raw_damage
	if defense_component:
		final_damage = defense_component.calculate_incoming_damage(raw_damage, armor_pen)

	_apply_damage(final_damage)


func _apply_damage(amount: float) -> void:
	current_health = maxf(0.0, current_health - amount)
	health_changed.emit(current_health, max_health)

	if current_health <= 0.0:
		_on_death()


func apply_stun(duration: float) -> void:
	if not is_alive:
		return
	movement_locked = true
	stop_movement()
	_play_anim_if_exists("AnimationLibrary_Godot_Standard/Hit_Chest")
	await get_tree().create_timer(duration).timeout
	if is_alive:
		movement_locked = false


func _on_death() -> void:
	is_alive = false
	movement_locked = true
	stop_movement()
	died.emit()
	
	_play_anim_if_exists("AnimationLibrary_Godot_Standard/Death01")
	
	set_physics_process(false)
	if has_node("CollisionShape3D"):
		get_node("CollisionShape3D").set_deferred("disabled", true)


# --- INVENTORY ---
func pickup_item(item) -> bool:
	if inventory and inventory.has_method("add_item"):
		return inventory.add_item(item)
	
	print(character_name, " picked up: ", item)
	return true


# --- SIGNAL WIRING ---
func _wire_component_signals() -> void:
	if defense_component:
		if not defense_component.damage_mitigated.is_connected(_on_damage_mitigated):
			defense_component.damage_mitigated.connect(_on_damage_mitigated)
		if not defense_component.dodge_executed.is_connected(_on_dodge_executed):
			defense_component.dodge_executed.connect(_on_dodge_executed)
		if not defense_component.damage_blocked.is_connected(_on_damage_blocked):
			defense_component.damage_blocked.connect(_on_damage_blocked)

	if combat_component:
		if not combat_component.hit_landed.is_connected(_on_hit_landed):
			combat_component.hit_landed.connect(_on_hit_landed)


func _on_damage_mitigated(original_damage: float, final_damage: float) -> void:
	print("%s took %f damage (reduced from %f)" % [character_name, final_damage, original_damage])


func _on_dodge_executed() -> void:
	print("%s dodged!" % character_name)


func _on_damage_blocked() -> void:
	print("%s blocked damage!" % character_name)


func _on_hit_landed(_target: Node, damage: float, is_critical: bool) -> void:
	var crit_msg := " (CRITICAL!)" if is_critical else ""
	print("%s dealt %f damage%s to target." % [character_name, damage, crit_msg])
