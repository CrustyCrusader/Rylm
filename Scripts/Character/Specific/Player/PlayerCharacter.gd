extends BaseCharacter3D
class_name PlayerCharacter

# Player nodes
@onready var camera_mount = $Camera_Mount
@onready var camera = $Camera_Mount/Camera3D
@onready var visuals = $Visuals

# Systems
var health_system: BodyPartSystem
var skill_system: SkillSystem
var class_system: ClassSystem
var survival_system: SurvivalSystem
var hud: HUD = null

# Inventory system
var inventory_ui: SimpleInventoryUI = null
var inventory_open: bool = false
var inventory_ui_loaded: bool = false

# Player settings
@export var mouse_sensitivity: float = 0.002
@export var camera_pitch_limit: float = 80.0

# Temporary for testing
var damage_dealt: float = 10.0

func _ready():
	# Setup player
	character_name = "Player"
	character_type = "player"
	
	# Initialize parent
	super._ready()
	
	# Initialize systems
	initialize_systems()
	
	# Setup input
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Add to player group for enemies
	add_to_group("player")
	
	# Load inventory UI
	call_deferred("setup_inventory_ui_deferred")
	
	print("PlayerCharacter ready")

func initialize_systems():
	# Create systems
	health_system = BodyPartSystem.new()
	add_child(health_system)
	
	skill_system = SkillSystem.new()
	add_child(skill_system)
	
	class_system = ClassSystem.new()
	add_child(class_system)
	
	survival_system = SurvivalSystem.new()
	add_child(survival_system)
	
	# Connect signals
	if health_system.has_signal("health_changed"):
		health_system.health_changed.connect(_on_health_changed)
	
	# Find HUD
	hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("connect_to_player"):
		hud.connect_to_player(self)

func setup_inventory_ui_deferred():
	if inventory_ui_loaded:
		return
	
	var ui_scene = load("res://Scenes/SimpleInventoryUI.tscn")
	if ui_scene:
		inventory_ui = ui_scene.instantiate()
		get_tree().root.add_child.call_deferred(inventory_ui)
		inventory_ui.visible = false
		inventory_ui_loaded = true
		
		# WAIT for the UI to be ready
		await get_tree().create_timer(0.1).timeout
		
		# Disconnect first to avoid duplicates
		if inventory_ui.inventory_closed.is_connected(_on_inventory_ui_closed):
			inventory_ui.inventory_closed.disconnect(_on_inventory_ui_closed)
		
		# Connect the signal
		inventory_ui.inventory_closed.connect(_on_inventory_ui_closed)
		
		print("Inventory UI loaded and signal connected")
		print("Signal connected: ", inventory_ui.inventory_closed.is_connected(_on_inventory_ui_closed))
	else:
		push_error("Failed to load inventory UI scene!")

func _on_inventory_ui_closed():
	print("=== PLAYER: Got inventory_closed signal ===")
	print("BEFORE: inventory_open =", inventory_open)
	# Always set to false when UI closes (via button OR key)
	inventory_open = false
	print("AFTER: inventory_open =", inventory_open)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(_event):
	# Get InputManager singleton
	var input_manager = get_node("/root/InputManager")
	
	# ESC should close inventory if it's open
	if input_manager.is_action_just_pressed("ui_cancel"):
		if inventory_open:
			toggle_inventory()
			return
	
	# I key toggles inventory
	if input_manager.is_action_just_pressed("inventory"):
		toggle_inventory()
		return
	
	# Only handle other inputs if inventory is CLOSED
	if not inventory_open:
		# Mouse look
		var mouse_look = input_manager.get_mouse_look()
		if mouse_look.length_squared() > 0:
			handle_mouse_look_from_vector(mouse_look)
		
		# Jump
		if input_manager.is_action_just_pressed("jump"):
			if movement and movement.has_method("jump"):
				movement.jump()
		
		# Attack
		if input_manager.is_action_just_pressed("attack") and not movement_locked:
			perform_attack()

func toggle_inventory():
	print("=== TOGGLE INVENTORY called ===")
	print("Current state: inventory_open =", inventory_open)
	
	# Make sure UI is loaded
	if not inventory_ui_loaded:
		print("UI not loaded yet")
		setup_inventory_ui_deferred()
		await get_tree().create_timer(0.1).timeout
	
	if not inventory_ui:
		print("ERROR: No inventory UI!")
		return
	
	# Toggle the state
	inventory_open = !inventory_open
	print("New state: inventory_open =", inventory_open)
	
	if inventory_open:
		# Opening inventory
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		inventory_ui.open(self)
	else:
		# Closing inventory
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		# If UI is visible, call its close() method to ensure signal is emitted
		if inventory_ui.visible:
			inventory_ui.close()  # ✅ This will emit the signal!
		else:
			# Just emit signal manually if UI isn't visible
			inventory_ui.inventory_closed.emit()

func handle_mouse_look_from_vector(mouse_input: Vector2):
	# Horizontal rotation
	rotate_y(-mouse_input.x)
	
	# Vertical rotation on camera
	if camera_mount:
		camera_mount.rotate_x(-mouse_input.y)
		camera_mount.rotation.x = clamp(
			camera_mount.rotation.x,
			deg_to_rad(-camera_pitch_limit),
			deg_to_rad(camera_pitch_limit)
		)
	
	# Reset visuals rotation
	if visuals:
		visuals.rotation.y = 0
		visuals.rotation.x = 0

func _physics_process(delta):
	# DEBUG: Print current state (less spam)
	if Engine.get_frames_drawn() % 60 == 0:  # Every second at 60 FPS
		print("[Frame %d] inventory_open: %s" % [Engine.get_frames_drawn(), inventory_open])
	
	# Skip ALL movement if inventory is open
	if inventory_open:
		velocity = Vector3.ZERO
		return
	
	# Skip if dead
	if not is_alive:
		return
	
	# Get movement input
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	
	# Update movement state
	if input_dir.length() > 0:
		if Input.is_action_pressed("run") and can_run():
			set_movement_state("running")
		else:
			set_movement_state("walking")
	else:
		set_movement_state("standing")
	
	# Call parent physics
	super._physics_process(delta)

func can_run() -> bool:
	if stats:
		return stats.current_stamina > 10.0
	return false

func set_movement_state(state: String):
	movement_state = state
	
	if movement:
		match state:
			"standing":
				movement.set_move_state(movement.MoveState.STANDING)
			"walking":
				movement.set_move_state(movement.MoveState.WALKING)
			"running":
				movement.set_move_state(movement.MoveState.RUNNING)

func perform_attack():
	if not is_alive or not is_conscious:
		return
	
	movement_locked = true
	print("Performing attack")
	
	# Play animation
	if has_node("AnimationPlayer"):
		get_node("AnimationPlayer").play("AnimationLibrary_Godot_Standard/Punch_Jab")
	
	# Attack logic
	await get_tree().create_timer(0.2).timeout
	check_attack_hit()

func check_attack_hit():
	# Raycast for attack
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		global_position,
		global_position - global_transform.basis.z * 2.0
	)
	query.exclude = [self]
	
	var result = space_state.intersect_ray(query)
	if result:
		var target = result.collider
		if target.has_method("take_damage"):
			target.take_damage(10, "physical", self)
			print("Player hit:", target.name)
	
	movement_locked = false

func take_damage(damage: float, damage_type: String = "physical", source = null):
	# Determine hit location (simplified)
	var hit_location = calculate_hit_location()
	
	# Apply damage to body part
	if health_system:
		health_system.apply_damage(hit_location, damage)
	
	# Show damage indicator on HUD
	if source and hud:
		var direction = (global_position - source.global_position).normalized()
		hud.show_damage_indicator(direction, damage)
	
	# Check for injuries
	if damage > 10.0:
		var injury_type = determine_injury_type(damage, damage_type)
		if health_system:
			health_system.add_injury(hit_location, injury_type, damage/100.0)

func calculate_hit_location() -> BodyPartSystem.BodyPart:
	# Simple random hit location for now
	var parts = BodyPartSystem.BodyPart.values()
	return parts[randi() % parts.size()]

func determine_injury_type(damage: float, damage_type: String) -> BodyPartSystem.InjuryType:
	if damage_type == "fire" or damage_type == "burn":
		return BodyPartSystem.InjuryType.BURN
	elif damage > 25.0:
		return BodyPartSystem.InjuryType.DEEP_WOUND
	elif damage > 15.0:
		return BodyPartSystem.InjuryType.CUT
	elif damage > 5.0:
		return BodyPartSystem.InjuryType.SCRATCH
	else:
		return BodyPartSystem.InjuryType.BRUISE

func perform_melee_attack():
	# Attack logic
	var damage = 10.0  # Base damage
	
	# Gain skill XP
	if skill_system:
		skill_system.on_melee_attack(damage)
	
	# Apply class bonuses
	if class_system:
		var class_bonus = class_system.get_class_bonus("melee_damage_bonus")
		damage *= (1.0 + class_bonus)
	
	damage_dealt = damage
	return damage

func craft_item(item_id: String):
	# Crafting logic
	print("Crafting item:", item_id)
	
	# Gain crafting XP
	var item_database = get_node("/root/ItemDatabase")
	var item_complexity = 1.0
	
	if item_database and item_database.has_method("get_item_complexity"):
		item_complexity = item_database.get_item_complexity(item_id)
	
	if skill_system:
		skill_system.on_craft_item(item_complexity)

func get_health():
	if health_system:
		return {
			"current": health_system.total_health,
			"max": 100.0
		}
	return {"current": 100.0, "max": 100.0}

func get_body_part_status(part: BodyPartSystem.BodyPart):
	if health_system:
		return health_system.get_body_part_status(part)
	return {}

func _on_health_changed(new_health: float, old_health: float):
	print("Health changed from ", old_health, " to ", new_health)
	if new_health <= 0:
		die()

func _on_animation_player_animation_finished(anim_name: StringName):
	if anim_name == "AnimationLibrary_Godot_Standard/Punch_Jab":
		movement_locked = false
		print("Attack animation finished")

# Test functions
func test_injury():
	if health_system:
		health_system.apply_damage(BodyPartSystem.BodyPart.LEFT_ARM, 25.0)
		print("Test injury applied to left arm")

func test_hunger():
	if survival_system:
		survival_system.hunger = 75.0
		print("Hunger set to 75%")

func test_skills():
	if skill_system:
		skill_system.gain_experience(SkillSystem.SkillType.STRENGTH, 50.0, "test")
