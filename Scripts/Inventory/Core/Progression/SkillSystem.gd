extends Node
class_name SkillSystem

# Skill Types
enum SkillType {
	STRENGTH,       # Melee damage, carrying capacity
	DEXTERITY,      # Crafting speed, ranged accuracy
	ENDURANCE,      # Stamina, resistance to elements
	SURVIVAL,       # Foraging, tracking, animal handling
	MEDICAL,        # Healing efficiency, diagnosis
	CRAFTING,       # Item quality, recipe unlocking
	STEALTH,        # Noise reduction, detection avoidance
	COMBAT          # Attack speed, critical chance
}

# Skill Data Structure
class SkillData:
	var type: SkillType
	var level: int = 1
	var experience: float = 0.0
	var next_level_xp: float = 100.0
	
	func _init(skill_type: SkillType):
		type = skill_type
	
	func add_xp(amount: float) -> bool:
		experience += amount
		if experience >= next_level_xp:
			level_up()
			return true
		return false
	
	func level_up():
		level += 1
		experience = 0.0
		next_level_xp = calculate_next_xp()
		print("Skill leveled up: ", SkillType.keys()[type], " to level ", level)
	
	func calculate_next_xp() -> float:
		return 100.0 * pow(1.5, level - 1)

# Main System
var skills: Dictionary = {}
var skill_modifiers: Dictionary = {}  # Active modifiers

func _ready():
	initialize_skills()
	print("SkillSystem initialized")

func initialize_skills():
	for skill in SkillType.values():
		skills[skill] = SkillData.new(skill)

func gain_experience(skill_type: SkillType, xp_amount: float, source: String = ""):
	var skill = skills.get(skill_type)
	if skill:
		var leveled_up = skill.add_xp(xp_amount)
		print("Gained ", xp_amount, " XP in ", SkillType.keys()[skill_type], 
			  " from ", source, " (Level: ", skill.level, ")")
		
		if leveled_up:
			on_skill_level_up(skill_type, skill.level)

func on_skill_level_up(skill_type: SkillType, new_level: int):
	print("=== SKILL LEVEL UP ===")
	print(SkillType.keys()[skill_type], " is now level ", new_level)
	# Here you can add level-up effects, unlock abilities, etc.

# Skill gain triggers
func on_melee_attack(damage_dealt: float):
	gain_experience(SkillType.STRENGTH, damage_dealt * 0.5, "combat")
	gain_experience(SkillType.COMBAT, damage_dealt * 0.3, "melee")

func on_craft_item(item_complexity: float):
	gain_experience(SkillType.DEXTERITY, item_complexity * 2.0, "crafting")
	gain_experience(SkillType.CRAFTING, item_complexity * 3.0, "crafting")

func on_heal_wound(heal_amount: float):
	gain_experience(SkillType.MEDICAL, heal_amount * 1.5, "healing")

func on_survival_action(action_type: String):
	match action_type:
		"forage":
			gain_experience(SkillType.SURVIVAL, 15.0, "foraging")
		"track":
			gain_experience(SkillType.SURVIVAL, 10.0, "tracking")
		"build_shelter":
			gain_experience(SkillType.SURVIVAL, 25.0, "shelter_building")

# Skill effects
func get_skill_bonus(skill_type: SkillType) -> float:
	var skill = skills.get(skill_type)
	if not skill:
		return 1.0
	
	# Base bonus from level
	var bonus = 1.0 + (skill.level * 0.05)
	
	# Apply any active modifiers
	if skill_modifiers.has(skill_type):
		bonus += skill_modifiers[skill_type]
	
	return bonus

func get_carry_capacity() -> float:
	var strength = skills[SkillType.STRENGTH]
	return 25.0 + (strength.level * 5.0)  # Base 25kg + 5kg per strength level

func get_crafting_speed() -> float:
	return get_skill_bonus(SkillType.DEXTERITY)

func get_melee_damage_multiplier() -> float:
	return get_skill_bonus(SkillType.STRENGTH) * get_skill_bonus(SkillType.COMBAT)

func get_all_skills() -> Dictionary:
	var skill_data = {}
	for skill_type in skills.keys():
		var skill = skills[skill_type]
		skill_data[skill_type] = {
			"level": skill.level,
			"experience": skill.experience,
			"next_level_xp": skill.next_level_xp,
			"progress_percent": (skill.experience / skill.next_level_xp) * 100.0
		}
	return skill_data
