extends BaseCharacter3D
class_name EnemyCharacter

# AI Systems
@onready var ai_controller = $AIController
@onready var detection_area = $DetectionArea
@onready var attack_timer = $AttackTimer
@onready var movement_controller = $MovementController

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
		print("Enemy movement controller initialized")
	
	# Setup detection area signals
	if detection_area:
		detection_area.body_entered.connect(_on_body_entered)
		detection_area.body_exited.connect(_on_body_exited)
		print("Detection area signals connected")
	else:
		print("WARNING: No detection area found!")
	
	# Setup attack timer
	if attack_timer:
		attack_timer.timeout.connect(_on_attack_timer_timeout)
		print("Attack timer connected")
	
	print("Enemy spawned: ", character_name)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	# Skip if dead
	if not is_alive:
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
		check_and_perform_attack()

func check_and_perform_attack() -> void:
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

func start_waiting_at_point() -> void:
	is_waiting = true
	patrol_timer = randf_range(min_wait_time, max_wait_time)
	print(character_name, " waiting at patrol point for ", patrol_timer, " seconds")

func go_to_next_patrol_point() -> void:
	if ai_controller and ai_controller.patrol_points.size() == 0:
		return
	
	ai_controller.patrol_index = (ai_controller.patrol_index + 1) % ai_controller.patrol_points.size()
	print(character_name, " moving to patrol point ", ai_controller.patrol_index)

# Signal Handlers
func _on_body_entered(body: Node) -> void:
	print(character_name, ": Something entered detection area: ", body.name)
	
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
	can_attack = true
	print(character_name, " can attack again")

# AI Actions
func start_chase(target: Node) -> void:
	if ai_controller:
		ai_controller.set_target(target)
		ai_controller.set_state(AIController.AIState.CHASE)
		print(character_name, " chasing ", target.character_name if target.has_method("character_name") else target.name)

func perform_attack() -> void:
	if not can_attack or not ai_controller or not ai_controller.target:
		return
	
	var target = ai_controller.target
	
	print(character_name, " attacking ", target.character_name if target.has_method("character_name") else target.name)
	
	# Play attack animation
	if has_node("AnimationPlayer"):
		get_node("AnimationPlayer").play("AnimationLibrary_Godot_Standard/Punch_Cross")
	
	# Apply damage if target is in range
	if global_position.distance_to(target.global_position) <= attack_range:
		if target.has_method("take_damage"):
			target.take_damage(attack_damage, "physical", self)
			print(character_name, " hit for ", attack_damage, " damage!")
	
	# Start attack cooldown
	can_attack = false
	if attack_timer:
		attack_timer.start(attack_cooldown)

func alert_nearby_enemies(alert_pos: Vector3) -> void:
	var nearby_enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in nearby_enemies:
		if enemy != self and enemy.global_position.distance_to(alert_pos) < 15.0:
			if enemy.has_method("alert_to_position"):
				enemy.alert_to_position(alert_pos)

func alert_to_position(alert_pos: Vector3) -> void:
	if ai_controller:
		ai_controller.investigate_position = alert_pos
		ai_controller.set_state(AIController.AIState.INVESTIGATE)
		print(character_name, " alerted to position ", alert_pos)

# Override BaseCharacter3D methods
func on_attacked(attacker) -> void:
	super.on_attacked(attacker)
	
	print(character_name, " was attacked by ", attacker.character_name if attacker and attacker.has_method("character_name") else "unknown")
	
	# Enemy-specific behavior when attacked
	if ai_controller and attacker:
		ai_controller.set_target(attacker)
		ai_controller.set_state(AIController.AIState.CHASE)
		
		# Alert nearby enemies
		alert_nearby_enemies(global_position)

func die() -> void:
	# Enemy-specific death behavior
	print(character_name, " has been defeated!")
	
	# Stop any ongoing attacks
	can_attack = false
	if attack_timer:
		attack_timer.stop()
	
	# Play death animation
	if has_node("AnimationPlayer"):
		get_node("AnimationPlayer").play("AnimationLibrary_Godot_Standard/Death01")
	
	# Wait then cleanup
	await get_tree().create_timer(2.0).timeout
	super.die()
