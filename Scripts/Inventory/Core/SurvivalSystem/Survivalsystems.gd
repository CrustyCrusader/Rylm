extends Node
class_name SurvivalSystem

# Survival needs
var hunger: float = 0.0  # 0 = full, 100 = starving
var thirst: float = 0.0  # 0 = hydrated, 100 = dehydrated
var fatigue: float = 0.0  # 0 = rested, 100 = exhausted
var body_temperature: float = 37.0  # Celsius
var infection_level: float = 0.0  # 0 = healthy, 100 = severely infected

# Rates (per real-time minute)
var hunger_rate: float = 0.5
var thirst_rate: float = 0.8
var fatigue_rate: float = 0.3
var infection_rate: float = 0.0  # Depends on injuries

# Effects
var hunger_effects: Dictionary = {}
var thirst_effects: Dictionary = {}
var fatigue_effects: Dictionary = {}
var infection_effects: Dictionary = {}

signal needs_updated(hunger: float, thirst: float, fatigue: float)
signal infection_changed(level: float)
signal body_temperature_changed(temp: float)

func _ready():
	print("SurvivalSystem initialized")
	load_effect_thresholds()

func _process(delta):
	# Convert delta to approximate real-time (adjust as needed)
	var real_time_factor = delta * 60.0  # Assuming 1 sec game time = 1 sec real time
	
	# Update needs
	hunger = min(100.0, hunger + hunger_rate * real_time_factor)
	thirst = min(100.0, thirst + thirst_rate * real_time_factor)
	fatigue = min(100.0, fatigue + fatigue_rate * real_time_factor)
	
	# Update infection if there are open wounds
	update_infection(delta)
	
	# Emit signals
	needs_updated.emit(hunger, thirst, fatigue)

func eat(food_value: float, hydration: float = 0.0):
	hunger = max(0.0, hunger - food_value)
	thirst = max(0.0, thirst - hydration)
	print("Ate food: Hunger -", food_value, ", Thirst -", hydration)

func drink(hydration_value: float):
	thirst = max(0.0, thirst - hydration_value)
	print("Drank: Thirst -", hydration_value)

func rest(rest_value: float):
	fatigue = max(0.0, fatigue - rest_value)
	print("Rested: Fatigue -", rest_value)

func update_infection(delta: float):
	# Infection grows from untreated wounds
	# Base infection rate from environment + wound contribution
	var wound_infection_risk = 0.0
	
	# This would come from BodyPartSystem
	# For now, simulate
	wound_infection_risk = randf() * 0.1
	
	infection_rate = wound_infection_risk
	infection_level = min(100.0, infection_level + infection_rate * delta)
	
	if infection_level > 0:
		infection_changed.emit(infection_level)

func treat_infection(treatment_strength: float):
	infection_level = max(0.0, infection_level - treatment_strength)
	print("Infection treated: -", treatment_strength, " now at ", infection_level)

func load_effect_thresholds():
	# Define effects at different need levels
	hunger_effects = {
		30.0: {"stamina_regen": -0.2, "health_regen": -0.1},
		60.0: {"stamina_regen": -0.5, "health_regen": -0.3, "strength": -0.1},
		90.0: {"stamina_regen": -0.8, "health_regen": -0.7, "strength": -0.3, "health_drain": 0.5}
	}
	
	thirst_effects = {
		30.0: {"stamina_max": -0.1, "stamina_regen": -0.3},
		60.0: {"stamina_max": -0.3, "stamina_regen": -0.6, "health_regen": -0.2},
		90.0: {"stamina_max": -0.5, "stamina_regen": -0.9, "health_regen": -0.5, "health_drain": 1.0}
	}
	
	fatigue_effects = {
		40.0: {"stamina_regen": -0.3, "movement_speed": -0.1},
		70.0: {"stamina_regen": -0.6, "movement_speed": -0.2, "accuracy": -0.2},
		90.0: {"stamina_regen": -0.9, "movement_speed": -0.4, "accuracy": -0.4, "chance_to_fall": 0.1}
	}

func get_current_effects() -> Dictionary:
	var effects = {}
	
	# Combine effects from all needs
	for threshold in hunger_effects.keys():
		if hunger >= threshold:
			effects.merge(hunger_effects[threshold], true)
	
	for threshold in thirst_effects.keys():
		if thirst >= threshold:
			effects.merge(thirst_effects[threshold], true)
	
	for threshold in fatigue_effects.keys():
		if fatigue >= threshold:
			effects.merge(fatigue_effects[threshold], true)
	
	return effects

func get_needs() -> Dictionary:
	return {
		"hunger": hunger,
		"thirst": thirst,
		"fatigue": fatigue,
		"infection": infection_level,
		"body_temperature": body_temperature
	}
