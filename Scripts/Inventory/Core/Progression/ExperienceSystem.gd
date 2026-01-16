# Progression/ExperienceSystem.gd
class_name ExperienceSystem
extends Node

# Signals
signal experience_gained(amount: float, source: String)
signal level_up(new_level: int)
signal skill_increased(skill_type: String, new_level: int)

# Experience data
var current_experience: float = 0.0
var current_level: int = 1
var experience_to_next_level: float = 100.0
var level_multiplier: float = 1.5

# Character reference
var character: BaseCharacter3D

func initialize(character_ref: BaseCharacter3D) -> void:
	character = character_ref
	update_experience_requirements()
	print("ExperienceSystem initialized for: ", character.character_name)

func add_experience(amount: float, source: String = "", skill_type: String = "") -> bool:
	if not character or amount <= 0:
		return false
	
	current_experience += amount
	experience_gained.emit(amount, source)
	
	# Check for level up
	while current_experience >= experience_to_next_level:
		level_up()
	
	# Apply skill experience if skill_type provided
	if not skill_type.is_empty() and character.skill_system:
		character.skill_system.gain_experience(skill_type, amount)
	
	return true

func level_up() -> void:
	var _old_level = current_level  # Prefix with underscore since not used
	current_level += 1
	current_experience -= experience_to_next_level
	update_experience_requirements()
	level_up.emit(current_level)
	
	# Apply level up benefits
	apply_level_up_benefits()

func update_experience_requirements() -> void:
	experience_to_next_level = 100.0 * pow(level_multiplier, current_level - 1)

func apply_level_up_benefits() -> void:
	if character and character.stats:
		# Increase health and stamina
		character.stats.max_health += 10.0
		character.stats.max_stamina += 5.0
		
		# Heal character on level up
		character.heal(character.stats.max_health * 0.25)
		
		print(character.character_name, " reached level ", current_level)

func get_experience_progress() -> float:
	if experience_to_next_level <= 0:
		return 0.0
	return current_experience / experience_to_next_level

func get_experience_summary() -> Dictionary:
	return {
		"current_level": current_level,
		"current_experience": current_experience,
		"experience_to_next_level": experience_to_next_level,
		"progress_percentage": get_experience_progress() * 100.0
	}

func set_level(target_level: int) -> void:
	if target_level < 1:
		target_level = 1
	
	current_level = target_level
	current_experience = 0.0
	update_experience_requirements()
	level_up.emit(current_level)
