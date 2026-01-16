# Combat/DefenseComponent.gd
class_name DefenseComponent
extends Node

# Signals
signal armor_penetrated(damage: float, location: String)
signal damage_blocked(damage: float, block_amount: float)
signal defense_stat_changed(stat: String, new_value: float)

# Defense stats
var base_armor: float = 0.0
var current_armor: float = 0.0
var block_chance: float = 0.1  # 10% base block chance
var dodge_chance: float = 0.05  # 5% base dodge chance
var damage_reduction: float = 0.0

# Character reference
var character: BaseCharacter3D

func initialize(character_ref: BaseCharacter3D) -> void:
	character = character_ref
	current_armor = base_armor
	print("DefenseComponent initialized for: ", character.character_name)

# Fixed: added underscore to unused damage_type parameter
func calculate_defense(damage: float, _damage_type: String = "physical") -> float:
	var final_damage = damage
	
	# Apply damage reduction
	final_damage -= final_damage * damage_reduction
	
	# Check for block
	if try_block():
		var blocked_amount = final_damage * 0.5  # Block 50% of damage
		final_damage -= blocked_amount
		damage_blocked.emit(damage, blocked_amount)
		print("Damage blocked: ", blocked_amount)
	
	# Check for dodge
	if try_dodge():
		print("Attack dodged!")
		return 0.0
	
	# Apply armor
	if current_armor > 0:
		var armor_reduction = min(current_armor * 0.1, final_damage * 0.8)  # Armor reduces damage
		final_damage -= armor_reduction
		
		# Armor can be penetrated
		if damage > current_armor * 2:
			armor_penetrated.emit(damage, "center")
			print("Armor penetrated!")
	
	return max(final_damage, 0.0)

func try_block() -> bool:
	return randf() < block_chance

func try_dodge() -> bool:
	return randf() < dodge_chance

func set_armor(value: float) -> void:
	current_armor = value
	defense_stat_changed.emit("armor", value)

func set_block_chance(value: float) -> void:
	block_chance = clamp(value, 0.0, 1.0)
	defense_stat_changed.emit("block_chance", value)

func set_dodge_chance(value: float) -> void:
	dodge_chance = clamp(value, 0.0, 1.0)
	defense_stat_changed.emit("dodge_chance", value)

func set_damage_reduction(value: float) -> void:
	damage_reduction = clamp(value, 0.0, 0.95)  # Max 95% reduction
	defense_stat_changed.emit("damage_reduction", value)

func take_armor_damage(damage: float) -> void:
	current_armor = max(current_armor - damage, 0.0)
	defense_stat_changed.emit("armor", current_armor)

func repair_armor(amount: float) -> void:
	current_armor = min(current_armor + amount, base_armor)
	defense_stat_changed.emit("armor", current_armor)

func get_defense_stats() -> Dictionary:
	return {
		"armor": current_armor,
		"block_chance": block_chance,
		"dodge_chance": dodge_chance,
		"damage_reduction": damage_reduction
	}

# Emit armor penetrated signal manually if needed
func emit_armor_penetrated_signal(damage: float, location: String) -> void:
	armor_penetrated.emit(damage, location)
