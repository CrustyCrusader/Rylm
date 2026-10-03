class_name EnemyCharacter3D
extends BaseCharacter3D

@export_group("AI Settings")
@export var detection_radius: float = 12.0
@export var attack_range: float = 2.0
@export var attack_cooldown: float = 1.5
@onready var health_bar_sprite: Sprite3D = get_node_or_null("HealthBarSprite")
@onready var health_bar_viewport: SubViewport = get_node_or_null("HealthBarSprite/HealthBarViewport")
@onready var health_bar_2d: ProgressBar = get_node_or_null("HealthBarSprite/HealthBarViewport/HealthBar2D")



var player_target: BaseCharacter3D = null
var can_attack: bool = true


func _ready() -> void:
	character_name = "Zombie"
	character_type = "enemy"
	melee_attack_animation = "AnimationLibrary_Godot_Standard/Punch_Jab"
	
	super._ready()
	add_to_group("enemy")
	
	# Assign ViewportTexture dynamically if not set in Inspector
	if health_bar_sprite and health_bar_viewport and not health_bar_sprite.texture:
		health_bar_sprite.texture = health_bar_viewport.get_texture()

	# Initialize bar values
	if health_bar_2d:
		health_bar_2d.max_value = max_health
		health_bar_2d.value = current_health

	# Connect health signal from BaseCharacter3D
	if not health_changed.is_connected(_on_health_changed_ui):
		health_changed.connect(_on_health_changed_ui)

	# Start hidden until enemy takes damage
	if health_bar_sprite:
		health_bar_sprite.visible = false

func _on_health_changed_ui(new_health: float, maximum_health: float) -> void:
	if health_bar_2d:
		health_bar_2d.max_value = maximum_health
		health_bar_2d.value = new_health

	# Show bar when damaged; hide when dead or at full health
	if health_bar_sprite:
		health_bar_sprite.visible = (new_health > 0.0 and new_health < maximum_health)


func _physics_process(delta: float) -> void:
	# If enemy is dead, stunned, or currently swinging, halt movement & update physics/animations
	if not is_alive or movement_locked or is_attacking:
		stop_movement()
		super._physics_process(delta)
		return

	# Locate active Player node in group "player"
	if not player_target or not is_instance_valid(player_target) or not player_target.is_alive:
		_find_player_target()

	if player_target and player_target.is_alive:
		var dist := global_position.distance_to(player_target.global_position)

		if dist <= detection_radius:
			# Face player on Y-axis (prevents mesh tilting up/down)
			var look_pos := player_target.global_position
			look_pos.y = global_position.y
			if global_position.distance_squared_to(look_pos) > 0.001:
				look_at(look_pos, Vector3.UP)

			if dist <= attack_range:
				# Within range: stop moving and punch
				stop_movement()
				if can_attack:
					_attack_player()
			else:
				# Outside attack range: move towards player
				var dir := (player_target.global_position - global_position).normalized()
				movement = Vector3(dir.x, 0, dir.z)
		else:
			stop_movement()
	else:
		stop_movement()

	# Process velocity, gravity, move_and_slide(), and update_animations() from BaseCharacter3D
	super._physics_process(delta)


func _find_player_target() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_target = players[0] as BaseCharacter3D


func _attack_player() -> void:
	can_attack = false
	perform_melee_attack(player_target)
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true
