extends BaseCharacter3D
class_name PlayerCharacter

# Player nodes
@onready var camera_mount = $Camera_Mount
@onready var camera = $Camera_Mount/Camera3D
@onready var visuals = $Visuals

# Inventory system
var inventory_ui: SimpleInventoryUI = null
var inventory_open: bool = false
var inventory_ui_loaded: bool = false

# Player settings
@export var mouse_sensitivity: float = 0.002
@export var camera_pitch_limit: float = 80.0

func _ready():
	# Setup player
	character_name = "Player"
	character_type = "player"
	
	# Initialize parent
	super._ready()
	
	# Setup input
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Add to player group for enemies
	add_to_group("player")
	
	# Load inventory UI
	call_deferred("setup_inventory_ui_deferred")
	
	print("PlayerCharacter ready")

func setup_inventory_ui_deferred():
	if inventory_ui_loaded:
		return
	
	var ui_scene = load("res://Scenes/SimpleInventoryUI.tscn")
	if ui_scene:
		inventory_ui = ui_scene.instantiate()
		get_tree().root.add_child.call_deferred(inventory_ui)
		inventory_ui.visible = false
		inventory_ui_loaded = true
		
		# Connect the UI's signal
		inventory_ui.inventory_closed.connect(_on_inventory_ui_closed)
		
		print("Inventory UI loaded and signal connected")
	else:
		push_error("Failed to load inventory UI scene!")

func _on_inventory_ui_closed():
	print("=== PLAYER: Got inventory_closed signal ===")
	print("BEFORE: inventory_open =", inventory_open)
	# Always set to false when UI closes (via button OR key)
	inventory_open = false
	print("AFTER: inventory_open =", inventory_open)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event):
	# ESC should close inventory if it's open
	if event.is_action_pressed("ui_cancel"):
		print("=== ESC pressed ===")
		if inventory_open:
			toggle_inventory()
			return
	
	# I key toggles inventory
	if event.is_action_pressed("inventory"):
		print("=== I pressed ===")
		toggle_inventory()
		return
	
	# Only handle other inputs if inventory is CLOSED
	if not inventory_open:
		# Mouse look
		if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			handle_mouse_look(event)
		
		# Jump
		if event.is_action_pressed("jump"):
			if movement and movement.has_method("jump"):
				movement.jump()
		
		# Attack
		if event.is_action_pressed("attack") and not movement_locked:
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

func handle_mouse_look(event: InputEventMouseMotion):
	# Horizontal rotation
	rotate_y(-event.relative.x * mouse_sensitivity)
	
	# Vertical rotation on camera
	if camera_mount:
		camera_mount.rotate_x(-event.relative.y * mouse_sensitivity)
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
		#print("SKIPPING MOVEMENT - inventory is open")
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

func _on_animation_player_animation_finished(anim_name: StringName):
	if anim_name == "AnimationLibrary_Godot_Standard/Punch_Jab":
		movement_locked = false
		print("Attack animation finished")
