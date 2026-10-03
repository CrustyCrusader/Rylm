class_name PlayerCharacter
extends BaseCharacter3D

# Player-specific nodes
@onready var camera_mount: Node3D = get_node_or_null("Camera_Mount")
@onready var camera: Camera3D = get_node_or_null("Camera_Mount/Camera3D")

# Player settings
@export var mouse_sensitivity: float = 0.002
@export var camera_pitch_limit: float = 80.0
@export var sprint_multiplier: float = 1.5

# Inventory UI
var simple_inventory_ui: Node
var inventory_open: bool = false

func _ready() -> void:
	character_name = "Player"
	character_type = "player"
	melee_attack_animation = "AnimationLibrary_Godot_Standard/Punch_Jab"
	
	super._ready()
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	add_to_group("player")
	call_deferred("setup_inventory_ui")

func setup_inventory_ui() -> void:
	if ResourceLoader.exists("res://Scenes/SimpleInventoryUI.tscn"):
		var ui_scene = load("res://Scenes/SimpleInventoryUI.tscn")
		if ui_scene:
			simple_inventory_ui = ui_scene.instantiate()
			get_tree().root.add_child(simple_inventory_ui)
			simple_inventory_ui.visible = false
			
			if simple_inventory_ui.has_signal("inventory_closed"):
				simple_inventory_ui.connect("inventory_closed", Callable(self, "_on_inventory_ui_closed"))

func _on_inventory_ui_closed() -> void:
	inventory_open = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		toggle_inventory()
		return
	
	if event.is_action_pressed("cancel") and inventory_open:
		toggle_inventory()
		return
	
	if not inventory_open:
		if event is InputEventMouseMotion:
			handle_mouse_look(event.relative)
		
		if event.is_action_pressed("melee_attack"):
			perform_melee_attack()

func toggle_inventory() -> void:
	if not simple_inventory_ui:
		return
	
	inventory_open = !inventory_open
	
	if inventory_open:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		if simple_inventory_ui.has_method("open"):
			simple_inventory_ui.open(self)
		else:
			simple_inventory_ui.visible = true
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		if simple_inventory_ui.has_method("close"):
			simple_inventory_ui.close()
		else:
			simple_inventory_ui.visible = false

func handle_mouse_look(mouse_input: Vector2) -> void:
	rotate_y(-mouse_input.x * mouse_sensitivity)
	
	if camera_mount:
		camera_mount.rotate_x(-mouse_input.y * mouse_sensitivity)
		camera_mount.rotation.x = clamp(
			camera_mount.rotation.x,
			deg_to_rad(-camera_pitch_limit),
			deg_to_rad(camera_pitch_limit)
		)

func _physics_process(delta: float) -> void:
	if inventory_open or not is_alive or movement_locked:
		stop_movement()
		return

	# Calculate camera-relative movement direction
	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Apply sprint multiplier
	var is_sprinting := Input.is_action_pressed("sprint")
	var speed_mult := sprint_multiplier if is_sprinting else 1.0

	# Assign direction to base character movement vector
	movement = direction * speed_mult

	if Input.is_action_just_pressed("jump"):
		jump()

	# Process movement & gravity from BaseCharacter3D
	super._physics_process(delta)
