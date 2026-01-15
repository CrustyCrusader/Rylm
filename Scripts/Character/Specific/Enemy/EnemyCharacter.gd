# EnemyCharacter.gd
extends BaseCharacter3D
class_name EnemyCharacter

#region AI Systems
@onready var ai_controller = $AIController
@onready var detection_area = $DetectionArea
@onready var attack_timer = $AttackTimer
#endregion

#region Patrol Settings
@export var patrol_radius: float = 10.0
@export var min_wait_time: float = 1.0
@export var max_wait_time: float = 3.0
var current_patrol_index: int = 0
var patrol_timer: float = 0.0
var is_waiting: bool = false
#endregion

#region Attack Settings
@export var attack_damage: float = 10.0
@export var attack_range: float = 2.0
@export var attack_cooldown: float = 1.0
var can_attack: bool = true
#endregion

func _ready():
	character_type = "enemy"
	
	# Set enemy name if not set
	if character_name == "Unnamed":
		character_name = "Zombie" if character_race == "zombie" else "Enemy"
	
	# CRITICAL: Add enemy to group for easy targeting
	add_to_group("enemies")
	
	super._ready()  # Call parent _ready
	
	# Enemy-specific initialization
	if detection_area:
		detection_area.body_entered.connect(_on_body_entered)
		detection_area.body_exited.connect(_on_body_exited)
		print("Enemy detection area ready")
	
	if attack_timer:
		attack_timer.timeout.connect(_on_attack_timer_timeout)
	
	print("Enemy spawned: ", character_name)
	print("Enemy attack settings: Damage=", attack_damage, ", Range=", attack_range, ", Cooldown=", attack_cooldown)

func _physics_process(delta):
	# Call parent physics first
	super._physics_process(delta)
	
	# Enemy-specific AI processing
	if ai_controller and is_alive:
		ai_controller.process_ai(delta)
	
	# Handle patrol waiting timer
	if ai_controller and ai_controller.current_state == AIController.AIState.PATROL and is_waiting:
		patrol_timer -= delta
		if patrol_timer <= 0:
			is_waiting = false
			go_to_next_patrol_point()
	
	# Check if reached patrol point
	if ai_controller and ai_controller.current_state == AIController.AIState.PATROL and not is_waiting:
		if movement and ai_controller.patrol_points.size() > 0:
			var target_pos = ai_controller.patrol_points[current_patrol_index]
			if global_position.distance_to(target_pos) < 1.5:
				start_waiting_at_point()
	
	# Check if we should attack
	if ai_controller and ai_controller.current_state == AIController.AIState.ATTACK:
		check_and_perform_attack()

func check_and_perform_attack():
	if not ai_controller or not ai_controller.target:
		return
	
	var target = ai_controller.target
	var distance = global_position.distance_to(target.global_position)
	
	# If target is in range and we can attack
	if distance <= attack_range and can_attack:
		perform_attack()
	# If target moved out of range, chase again
	elif distance > attack_range:
		ai_controller.set_state(AIController.AIState.CHASE)

func start_waiting_at_point():
	is_waiting = true
	patrol_timer = randf_range(min_wait_time, max_wait_time)
	print(character_name, " waiting at patrol point for ", patrol_timer, " seconds")
	
	# Look around while waiting
	if has_node("Visuals"):
		var random_rotation = randf_range(-30, 30)
		get_node("Visuals").rotate_y(deg_to_rad(random_rotation))

func go_to_next_patrol_point():
	if ai_controller and ai_controller.patrol_points.size() == 0:
		return
	
	current_patrol_index = (current_patrol_index + 1) % ai_controller.patrol_points.size()
	
	if ai_controller.current_state == AIController.AIState.PATROL:
		print(character_name, " patrolling to point ", current_patrol_index)

#region Signal Handlers
func _on_body_entered(body):
	print("Enemy: Something entered detection area: ", body.name)
	
	# Multiple ways to detect player
	var is_player = false
	
	# Method 1: Check group
	if body.is_in_group("player"):
		print("  Detected via group")
		is_player = true
	
	# Method 2: Check type
	elif body is PlayerCharacter:
		print("  Detected via type")
		is_player = true
	
	# Method 3: Check method
	elif body.has_method("get_character_type") and body.get_character_type() == "player":
		print("  Detected via character type method")
		is_player = true
	
	if is_player:
		print(character_name, " detected player")
		start_chase(body)
	else:
		print("  Not a player: ", body.get_class())

func _on_body_exited(body):
	if body.is_in_group("player") and ai_controller:
		print(character_name, " lost sight of player")
		ai_controller.target_lost()

func _on_attack_timer_timeout():
	# Reset attack cooldown
	can_attack = true
	print(character_name, " can attack again")
#endregion

#region AI Actions
func start_chase(target):
	if ai_controller:
		ai_controller.set_target(target)
		ai_controller.set_state(AIController.AIState.CHASE)
		print(character_name, " chasing ", target.character_name)

func perform_attack():
	if not can_attack or not ai_controller or not ai_controller.target:
		return
	
	var target = ai_controller.target
	
	print(character_name, " attacking ", target.character_name)
	
	# Play attack animation
	if has_node("AnimationPlayer"):
		get_node("AnimationPlayer").play("AnimationLibrary_Godot_Standard/Punch_Cross")
	
	# Apply damage if target is in range
	if global_position.distance_to(target.global_position) <= attack_range:
		if target.has_method("take_damage"):
			# Note: The take_damage method might return void, so don't expect a return value
			target.take_damage(attack_damage, "physical", self)
			print(character_name, " hit ", target.character_name, " for ", attack_damage, " damage!")
	
	# Start attack cooldown
	can_attack = false
	if attack_timer:
		attack_timer.start(attack_cooldown)

func alert_nearby_enemies(alert_pos: Vector3):
	var nearby_enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in nearby_enemies:
		if enemy != self and enemy.global_position.distance_to(alert_pos) < 15.0:
			if enemy.has_method("alert_to_position"):
				enemy.alert_to_position(alert_pos)

func alert_to_position(alert_pos: Vector3):
	if ai_controller:
		ai_controller.investigate_position = alert_pos
		ai_controller.set_state(AIController.AIState.INVESTIGATE)
		print(character_name, " alerted to position ", alert_pos)
#endregion

#region Override BaseCharacter3D methods
func on_attacked(attacker):
	super.on_attacked(attacker)
	
	print(character_name, " was attacked by ", attacker.character_name if attacker else "unknown")
	
	# Enemy-specific behavior when attacked
	if ai_controller and attacker:
		ai_controller.set_target(attacker)
		ai_controller.set_state(AIController.AIState.CHASE)
		
		# Alert nearby enemies
		alert_nearby_enemies(global_position)
		
		# Enrage when wounded
		if stats and stats.current_health < stats.max_health * 0.5:
			print(character_name, " is enraged!")
			if movement:
				movement.run_speed *= 1.3
			
			# Increase our attack range when enraged
			attack_range *= 1.2
			print("  New attack range: ", attack_range)

func die():
	# Enemy-specific death behavior
	print(character_name, " has been defeated!")
	
	# Stop any ongoing attacks
	can_attack = false
	if attack_timer:
		attack_timer.stop()
	
	# Chance to drop loot
	if randf() < 0.3:  # 30% chance
		drop_random_loot()
	
	# Play death animation
	if has_node("AnimationPlayer"):
		get_node("AnimationPlayer").play("AnimationLibrary_Godot_Standard/Death01")
	
	# Call parent die() for cleanup after animation
	await get_tree().create_timer(2.0).timeout
	super.die()

func drop_random_loot():
	# Implementation for dropping loot
	print(character_name, " dropped some loot!")
	# TODO: Actually drop loot items
#endregion
