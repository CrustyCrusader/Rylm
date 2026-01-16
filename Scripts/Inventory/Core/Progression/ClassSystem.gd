extends Node
class_name ClassSystem

enum PlayerClass {
	WARRIOR,      # Combat focus
	SCOUT,        # Stealth & mobility
	CRAFTER,      # Building & crafting
	SURVIVALIST,  # Outdoor skills
	MEDIC,        # Healing & support
	HYBRID        # Balanced
}

# Class Data
var current_class: PlayerClass = PlayerClass.HYBRID
var class_level: int = 1
var class_experience: float = 0.0

# Class Bonuses
var class_bonuses = {
	PlayerClass.WARRIOR: {
		"strength_xp_gain": 1.5,
		"combat_xp_gain": 2.0,
		"max_health_bonus": 20.0,
		"melee_damage_bonus": 0.3
	},
	PlayerClass.SCOUT: {
		"dexterity_xp_gain": 1.5,
		"stealth_xp_gain": 2.0,
		"movement_speed_bonus": 0.2,
		"stamina_regen_bonus": 0.5
	},
	PlayerClass.CRAFTER: {
		"crafting_xp_gain": 2.0,
		"dexterity_xp_gain": 1.5,
		"crafting_speed_bonus": 0.4,
		"resource_gather_bonus": 0.3
	},
	PlayerClass.SURVIVALIST: {
		"survival_xp_gain": 2.0,
		"endurance_xp_gain": 1.5,
		"hunger_thirst_rate": 0.7,
		"environment_resistance": 0.4
	},
	PlayerClass.MEDIC: {
		"medical_xp_gain": 2.0,
		"healing_efficiency": 1.5,
		"treatment_speed_bonus": 0.4,
		"infection_resistance": 0.5
	},
	PlayerClass.HYBRID: {
		"all_xp_gain": 1.1,  # Small bonus to all
		"versatility_bonus": 0.1
	}
}

func _ready():
	print("ClassSystem initialized")
	set_class(PlayerClass.HYBRID)

func set_class(new_class: PlayerClass):
	current_class = new_class
	class_level = 1
	class_experience = 0.0
	print("Class set to: ", PlayerClass.keys()[new_class])

func get_class_bonus(bonus_name: String) -> float:
	var bonuses = class_bonuses.get(current_class, {})
	return bonuses.get(bonus_name, 1.0)

func apply_xp_modifier(skill_type: SkillSystem.SkillType, base_xp: float) -> float:
	var modifier = 1.0
	
	match skill_type:
		SkillSystem.SkillType.STRENGTH:
			modifier = get_class_bonus("strength_xp_gain")
		SkillSystem.SkillType.DEXTERITY:
			modifier = get_class_bonus("dexterity_xp_gain")
		SkillSystem.SkillType.CRAFTING:
			modifier = get_class_bonus("crafting_xp_gain")
		SkillSystem.SkillType.SURVIVAL:
			modifier = get_class_bonus("survival_xp_gain")
		SkillSystem.SkillType.MEDICAL:
			modifier = get_class_bonus("medical_xp_gain")
		SkillSystem.SkillType.COMBAT:
			modifier = get_class_bonus("combat_xp_gain")
		SkillSystem.SkillType.STEALTH:
			modifier = get_class_bonus("stealth_xp_gain")
		_:
			modifier = get_class_bonus("all_xp_gain")
	
	return base_xp * modifier

func get_current_class_data() -> Dictionary:
	return {
		"class": PlayerClass.keys()[current_class],
		"level": class_level,
		"experience": class_experience,
		"bonuses": class_bonuses[current_class]
	}
