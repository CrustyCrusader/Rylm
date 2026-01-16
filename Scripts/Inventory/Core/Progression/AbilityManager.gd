# Inventory/Core/Progression/AbilityManager.gd
class_name AbilityManager
extends Node

# Ability types
enum AbilityType {
	PASSIVE,
	ACTIVE,
	UTILITY
}

# Ability data structure
class AbilityData:
	var id: String
	var name: String
	var description: String
	var ability_type: AbilityType
	var requirements: Dictionary
	var effects: Array
	
	func _init(p_id: String, p_name: String, p_description: String, p_type: AbilityType = AbilityType.PASSIVE) -> void:
		id = p_id
		name = p_name
		description = p_description
		ability_type = p_type
		requirements = {}
		effects = []

# Character reference
var character: BaseCharacter3D

# Learned abilities
var learned_abilities: Array[String] = []
var active_abilities: Array[String] = []

# Ability cooldowns
var cooldowns: Dictionary = {}

func initialize_abilities() -> void:
	if character:
		print("AbilityManager initialized for: ", character.character_name)
	# Load default abilities based on character class/race
	load_default_abilities()

func load_default_abilities() -> void:
	# Load abilities based on character type
	match character.character_type:
		"player":
			learned_abilities.append("basic_attack")
			learned_abilities.append("block")
		"npc":
			learned_abilities.append("basic_attack")
		"enemy":
			learned_abilities.append("basic_attack")
			learned_abilities.append("roar")

func learn_ability(ability_id: String) -> bool:
	if not has_ability(ability_id):
		learned_abilities.append(ability_id)
		print("Learned ability: ", ability_id)
		return true
	return false

func has_ability(ability_id: String) -> bool:
	return ability_id in learned_abilities

func can_use_ability(ability_id: String) -> bool:
	if not has_ability(ability_id):
		return false
	
	# Check cooldown
	if ability_id in cooldowns:
		var cooldown_time = cooldowns[ability_id]
		if Time.get_unix_time_from_system() < cooldown_time:
			return false
	
	# Check requirements (stamina, mana, etc.)
	if character and character.stats:
		return character.stats.current_stamina > 10.0
	
	return true

func use_ability(ability_id: String, target = null) -> bool:
	if not can_use_ability(ability_id):
		return false
	
	print("Using ability: ", ability_id)
	
	# Set cooldown (example: 5 seconds)
	cooldowns[ability_id] = Time.get_unix_time_from_system() + 5.0
	
	# Apply ability effects
	apply_ability_effects(ability_id, target)
	
	return true

func apply_ability_effects(ability_id: String, target) -> void:
	match ability_id:
		"basic_attack":
			if character and target:
				character.perform_melee_attack()
		"block":
			if character and character.stats:
				character.stats.add_temporary_buff("block", 2.0, {"damage_reduction": 0.5})
		"roar":
			if character:
				# Area effect that scares enemies
				character.apply_area_effect("fear", 10.0, 5.0)

func get_learned_abilities() -> Array:
	return learned_abilities

func get_active_abilities() -> Array:
	return active_abilities

func get_ability_cooldown(ability_id: String) -> float:
	if ability_id in cooldowns:
		var remaining = cooldowns[ability_id] - Time.get_unix_time_from_system()
		return max(0.0, remaining)
	return 0.0
