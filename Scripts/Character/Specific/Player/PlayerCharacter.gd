extends BaseCharacter3D
class_name PlayerCharacter

# Player-specific nodes
@onready var camera_mount = $Camera_Mount
@onready var camera = $Camera_Mount/Camera3D
@onready var movement_controller = $PlayerMovementController
@onready var animation_player = $AnimationPlayer

# Player settings
@export var mouse_sensitivity: float = 0.002
@export var camera_pitch_limit: float = 80.0

# Inventory UI
var simple_inventory_ui: SimpleInventoryUI
var inventory_open: bool = false

func _ready() -> void:
	# Setup player
	character_name = "Player"
	character_type = "player"
	
	# Parent initialization
	super._ready()
	
	# Initialize movement controller
	movement_controller.initialize(self)
	
	# Connect signals
	movement_controller.movement_state_changed.connect(_on_movement_state_changed)
	movement_controller.animation_requested.connect(_on_animation_requested)
	
	# Setup input
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Add to player group
	add_to_group("player")
	
	# Load inventory UI
	call_deferred("setup_inventory_ui")
	
	print("PlayerCharacter ready")

func setup_inventory_ui() -> void:
	var ui_scene = load("res://Scenes/SimpleInventoryUI.tscn")
	if ui_scene:
		simple_inventory_ui = ui_scene.instantiate()
		get_tree().root.add_child(simple_inventory_ui)
		simple_inventory_ui.visible = false
		
		if simple_inventory_ui.has_signal("inventory_closed"):
			simple_inventory_ui.inventory_closed.connect(_on_inventory_ui_closed)
		
		print("Inventory UI loaded")
	else:
		print("ERROR: Failed to load inventory UI scene!")

func _on_movement_state_changed(new_state: int) -> void:
	print("Movement state changed to: ", MovementController.MoveState.keys()[new_state])

func _on_animation_requested(animation_name: String) -> void:
	if animation_player:
		animation_player.play(animation_name)
		print("Playing: ", animation_name)

func _on_inventory_ui_closed() -> void:
	print("Inventory closed")
	inventory_open = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void:
	# Inventory toggle
	if event.is_action_pressed("inventory"):
		toggle_inventory()
	
	# Close inventory with ESC
	if event.is_action_pressed("ui_cancel") and inventory_open:
		toggle_inventory()
		return
	
	# Handle other inputs only if inventory closed
	if not inventory_open:
		# Mouse look
		if event is InputEventMouseMotion:
			handle_mouse_look(event.relative)
		
		# Attack
		if event.is_action_pressed("attack") and not movement_locked:
			perform_attack()

func toggle_inventory() -> void:
	print("Toggle inventory called")
	
	if not simple_inventory_ui:
		print("ERROR: No inventory UI!")
		return
	
	inventory_open = !inventory_open
	
	if inventory_open:
		# Open inventory
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		simple_inventory_ui.open(self)
	else:
		# Close inventory
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		if simple_inventory_ui.visible:
			simple_inventory_ui.close()
		else:
			simple_inventory_ui.inventory_closed.emit()

func handle_mouse_look(mouse_input: Vector2) -> void:
	# Horizontal rotation
	rotate_y(-mouse_input.x * mouse_sensitivity)
	
	# Vertical rotation on camera
	if camera_mount:
		camera_mount.rotate_x(-mouse_input.y * mouse_sensitivity)
		camera_mount.rotation.x = clamp(
			camera_mount.rotation.x,
			deg_to_rad(-camera_pitch_limit),
			deg_to_rad(camera_pitch_limit)
		)

func _physics_process(delta: float) -> void:
	# Parent physics
	super._physics_process(delta)
	
	# Skip movement if inventory open or dead
	if inventory_open or not is_alive:
		velocity = Vector3.ZERO
		move_and_slide()
		return

func perform_attack() -> void:
	if not is_alive or not is_conscious:
		return
	
	movement_locked = true
	print("Performing attack")
	
	# Play attack animation
	if animation_player:
		animation_player.play("AnimationLibrary_Godot_Standard/Punch_Jab")
	
	# Attack logic
	await get_tree().create_timer(0.2).timeout
	check_attack_hit()

func check_attack_hit() -> void:
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
			print("Player hit: ", target.name)
	
	movement_locked = false

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "AnimationLibrary_Godot_Standard/Punch_Jab":
		movement_locked = false
		print("Attack animation finished")
		# Return to movement animation
		movement_controller._update_animations()
