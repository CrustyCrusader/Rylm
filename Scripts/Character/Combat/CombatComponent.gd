# Character/Combat/CombatComponent.gd
extends Node
class_name CombatComponent

signal attack_triggered(damage, target)
signal attack_missed
signal attack_blocked
signal critical_hit(damage_multiplier)

@export_category("Combat Stats")
@export var base_damage: float = 10.0
@export var attack_speed: float = 1.0  # attacks per second
@export var critical_chance: float = 0.1  # 10%
@export var critical_multiplier: float = 2.0
@export var attack_range: float = 2.0
@export var stamina_cost_per_attack: float = 10.0

@export_category("Damage Types")
@export var physical_damage: float = 10.0
@export var piercing_damage: float = 0.0
@export var blunt_damage: float = 0.0

var character: BaseCharacter3D
var current_target = null
var is_attacking: bool = false
var attack_timer: float = 0.0
var last_attack_time: float = 0.0

func _ready():
	character = get_parent() as BaseCharacter3D
	if not character:
		push_warning("CombatComponent requires a BaseCharacter3D parent")

func _process(delta):
	if is_attacking and attack_timer > 0:
		attack_timer -= delta
		if attack_timer <= 0:
			perform_attack()

func initiate_attack(target) -> bool:
	if not character or not character.is_alive:
		return false
	
	# Check if can attack (cooldown, stamina, etc.)
	if not can_attack():
		return false
	
	# Check range
	if character.global_position.distance_to(target.global_position) > attack_range:
		return false
	
	# Pay stamina cost
	if character.stats and not character.stats.use_stamina(stamina_cost_per_attack):
		return false
	
	current_target = target
	is_attacking = true
	attack_timer = 1.0 / attack_speed  # Cooldown based on attack speed
	
	print(character.character_name, " initiating attack on ", target.character_name)
	return true

func can_attack() -> bool:
	if not character:
		return false
	
	return (character.is_alive and 
			character.is_conscious and 
			not is_attacking and 
			Time.get_ticks_msec() - last_attack_time > 1000 / attack_speed)

func perform_attack():
	if not current_target or not current_target.has_method("take_damage"):
		attack_missed.emit()
		reset_attack()
		return
	
	# Calculate damage
	var damage = calculate_damage()
	var is_critical = randf() < critical_chance
	
	if is_critical:
		damage *= critical_multiplier
		critical_hit.emit(critical_multiplier)
	
	# Apply damage
	var damage_dealt = current_target.take_damage(damage, "physical", character)
	
	if damage_dealt > 0:
		attack_triggered.emit(damage_dealt, current_target)
	else:
		attack_blocked.emit()
	
	last_attack_time = Time.get_ticks_msec()
	reset_attack()

func calculate_damage() -> float:
	var total_damage = base_damage + physical_damage
	
	# Apply character stats (strength, etc.)
	if character and character.has_method("get_stat_bonus"):
		var strength_bonus = character.get_stat_bonus("strength", 0.0)
		total_damage *= (1.0 + strength_bonus * 0.01)
	
	# Apply equipment bonuses
	if character and character.equipment:
		var weapon = character.equipment.equipped_items.get("weapon", null)
		if weapon and weapon.has("damage_bonus"):
			total_damage += weapon.damage_bonus
	
	# Random variation (±10%)
	total_damage *= randf_range(0.9, 1.1)
	
	return max(total_damage, 0.0)

func reset_attack():
	is_attacking = false
	current_target = null
	attack_timer = 0.0

func cancel_attack():
	reset_attack()

func get_attack_cooldown_percentage() -> float:
	if attack_speed <= 0:
		return 0.0
	
	var time_since_last = Time.get_ticks_msec() - last_attack_time
	var cooldown_time = 1000.0 / attack_speed
	return min(time_since_last / cooldown_time, 1.0)
