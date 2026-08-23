extends BaseCharacter3D
class_name EnemyCharacter

# AI Systems
@onready var ai_controller = $AIController
@onready var detection_area = $DetectionArea
@onready var attack_timer = $AttackTimer
@onready var movement_controller = $MovementController
@onready var collision_shape = $CollisionShape3D

# Patrol Settings
@export var patrol_radius: float = 10.0
@export var min_wait_time: float = 1.0
@export var max_wait_time: float = 3.0
@export var attack_damage: float = 10.0
@export var attack_range: float = 2.0
@export var attack_cooldown: float = 1.0

var current_patrol_index: int = 0
var patrol_timer: float = 0.0
var is_waiting: bool = false
var can_attack: bool = true
var is_attacking: bool = false

func _ready() -> void:
	character_type = "enemy"
	
	# Set default name
	if character_name == "Unnamed":
		character_name = "Zombie" if character_race == "zombie" else "Enemy"
	
	# Add to enemy group
	add_to_group("enemies")
	
	# Parent initialization
	super._ready()
	
	# Initialize movement controller
	if movement_controller:
		movement_controller.initialize(self)
		
		# Connect animation signals
		movement_controller.animation_requested.connect(_on_movement_animation_requested)
		movement_controller.movement_state_changed.connect(_on_movement_state_changed)
		
		print("Enemy movement controller initialized with animations")
	else:
		print("ERROR: No MovementController found!")
	
	# Setup detection area signals
	if detection_area:
		detection_area.body_entered.connect(_on_body_entered)
		detection_area.body_exited.connect(_on_body_exited)
		print("Detection area signals connected")
	else:
		print("WARNING: No detection area found!")
	
	# Setup attack timer
	if attack_timer:
		attack_timer.wait_time = attack_cooldown
		attack_timer.timeout.connect(_on_attack_timer_timeout)
		print("Attack timer connected with cooldown: ", attack_cooldown)
	
	print("Enemy spawned: ", character_name)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	# CRITICAL: Skip all logic if dead
	if not is_alive:
		return
	
	# Skip AI if currently attacking
	if is_attacking:
		return
	
	# AI processing
	if ai_controller:
		ai_controller.process_ai(delta)
	
	# Handle patrol waiting timer
	if ai_controller and ai_controller.current_state == AIController.AIState.PATROL and is_waiting:
		patrol_timer -= delta
		if patrol_timer <= 0:
			is_waiting = false
			go_to_next_patrol_point()
	
	# Check if reached patrol point
	if ai_controller and ai_controller.current_state == AIController.AIState.PATROL and not is_waiting:
		if ai_controller.patrol_points.size() > 0:
			var target_pos = ai_controller.patrol_points[ai_controller.patrol_index]
			if global_position.distance_to(target_pos) < 1.5:
				start_waiting_at_point()
	
	# Check if we should attack
	if ai_controller and ai_controller.current_state == AIController.AIState.ATTACK:
		check_and_perform_melee_attack()

func _on_movement_animation_requested(animation_name: String) -> void:
	# Only play movement animations if not attacking and alive
	if not is_attacking and is_alive and animation_player:
		if animation_player.has_animation(animation_name):
			animation_player.play(animation_name)
			#print(character_name, " playing animation: ", animation_name)
		else:
			print(character_name, " WARNING: Animation not found: ", animation_name)

func _on_movement_state_changed(_new_state: int) -> void:
	#print(character_name, " movement state: ", movement_controller.MoveState.keys()[new_state])
	pass

func check_and_perform_melee_attack() -> void:
	if not is_alive or not ai_controller or not ai_controller.target or is_attacking or not can_attack:
		return
	
	if not ai_controller.target.is_alive:
		ai_controller.target_lost()
		return
	
	var target = ai_controller.target
	var distance = global_position.distance_to(target.global_position)
	
	if distance <= attack_range:
		perform_melee_attack()
	elif distance > attack_range:
		ai_controller.set_state(AIController.AIState.CHASE)

func start_waiting_at_point() -> void:
	is_waiting = true
	patrol_timer = randf_range(min_wait_time, max_wait_time)
	
	# Set movement state to standing
	if movement_controller:
		movement_controller.set_move_state(movement_controller.MoveState.STANDING)
	
	print(character_name, " waiting at patrol point for ", patrol_timer, " seconds")

func go_to_next_patrol_point() -> void:
	if ai_controller and ai_controller.patrol_points.size() == 0:
		return
	
	ai_controller.patrol_index = (ai_controller.patrol_index + 1) % ai_controller.patrol_points.size()
	print(character_name, " moving to patrol point ", ai_controller.patrol_index)

# Signal Handlers
func _on_body_entered(body: Node) -> void:
	# Check if it's the player
	if body.is_in_group("player"):
		print(character_name, " detected player!")
		start_chase(body)

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player") and ai_controller:
		print(character_name, " lost sight of player")
		ai_controller.target_lost()

func _on_attack_timer_timeout() -> void:
	# Reset attack cooldown
	if is_alive:  # Only reset if still alive
		can_attack = true
		print(character_name, " can attack again")

# AI Actions
func start_chase(target: Node) -> void:
	if ai_controller and is_alive:
		ai_controller.set_target(target)
		ai_controller.set_state(AIController.AIState.CHASE)
		print(character_name, " chasing ", target.character_name if target.has_method("character_name") else target.name)

func perform_melee_attack() -> void:
	# CRITICAL: Check all conditions before attacking
	if not is_alive or not ai_controller or not ai_controller.target or is_attacking or not can_attack or not ai_controller.target.is_alive:
		return
	
	var target = ai_controller.target
	is_attacking = true
	can_attack = false
	
	print(character_name, " attacking ", target.character_name if target.has_method("character_name") else target.name)
	
	# Stop movement during attack
	if movement_controller:
		movement_controller.set_move_state(movement_controller.MoveState.STANDING)
	
	# Play attack animation
	if animation_player and animation_player.has_animation("AnimationLibrary_Godot_Standard/Punch_Cross"):
		animation_player.play("AnimationLibrary_Godot_Standard/Punch_Cross")
		
		# Wait for attack animation to complete
		await animation_player.animation_finished
		
		# Apply damage after animation (if still alive and target valid)
		if not is_instance_valid(target) or not target.is_alive:
			is_attacking = false
			ai_controller.target_lost()
			return
		if is_alive and global_position.distance_to(target.global_position) <= attack_range:
			if target.has_method("take_damage"):
				target.take_damage(attack_damage, "physical", self)
				print(character_name, " hit for ", attack_damage, " damage!")
		
		# Reset attack state
		is_attacking = false
		
		# Start attack cooldown
		if attack_timer:
			attack_timer.start()
	else:
		print("ERROR: No attack animation found!")
		is_attacking = false
		can_attack = true

func alert_nearby_enemies(alert_pos: Vector3) -> void:
	var nearby_enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in nearby_enemies:
		if enemy != self and enemy.is_alive and enemy.global_position.distance_to(alert_pos) < 15.0:
			if enemy.has_method("alert_to_position"):
				enemy.alert_to_position(alert_pos)

func alert_to_position(alert_pos: Vector3) -> void:
	if ai_controller and is_alive:
		ai_controller.investigate_position = alert_pos
		ai_controller.set_state(AIController.AIState.INVESTIGATE)
		print(character_name, " alerted to position ", alert_pos)

# Override BaseCharacter3D methods
func on_attacked(attacker) -> void:
	# CRITICAL: Only respond if alive
	if not is_alive:
		return
	
	super.on_attacked(attacker)
	
	print(character_name, " was attacked by ", attacker.character_name if attacker and attacker.has_method("character_name") else "unknown")
	
	# Enemy-specific behavior when attacked
	if ai_controller and attacker and not is_attacking:
		ai_controller.set_target(attacker)
		ai_controller.set_state(AIController.AIState.CHASE)
		
		# Alert nearby enemies
		alert_nearby_enemies(global_position)

func get_death_animation_name() -> String:
	return "AnimationLibrary_Godot_Standard/Death01"

func _on_death_started() -> void:
	if movement_controller:
		movement_controller.set_move_state(movement_controller.MoveState.STANDING)
	if attack_timer:
		attack_timer.stop()
	if collision_shape:
		collision_shape.disabled = true
	if detection_area:
		detection_area.monitoring = false
		detection_area.monitorable = false
	if ai_controller:
		ai_controller.set_state(AIController.AIState.IDLE)
		ai_controller.target = null
