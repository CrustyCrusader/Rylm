# SurvivalSystem/HungerThirst.gd
extends Node
class_name HungerThirstSystem

signal hunger_changed(new_value: float)
signal thirst_changed(new_value: float)
signal starvation_started
signal dehydration_started
signal needs_met

# Base rates (per real minute)
@export var base_hunger_rate: float = 0.5  # 0 to 100 over 200 minutes
@export var base_thirst_rate: float = 0.8  # 0 to 100 over 125 minutes

# Modified rates based on activity
var current_hunger_rate: float = 0.5
var current_thirst_rate: float = 0.8

# Current values (0-100)
var hunger: float = 0.0
var thirst: float = 0.0

# Status flags
var is_starving: bool = false
var is_dehydrated: bool = false
var starvation_damage_timer: float = 0.0
var dehydration_damage_timer: float = 0.0

# Effects at different thresholds
var hunger_effects = {
	30: {"stamina_regen": -0.2, "name": "Peckish"},
	60: {"stamina_regen": -0.5, "health_regen": -0.3, "strength": -0.1, "name": "Hungry"},
	90: {"stamina_regen": -0.8, "health_regen": -0.7, "strength": -0.3, "health_drain": 0.5, "name": "Starving"}
}

var thirst_effects = {
	30: {"stamina_max": -0.1, "stamina_regen": -0.3, "name": "Thirsty"},
	60: {"stamina_max": -0.3, "stamina_regen": -0.6, "health_regen": -0.2, "name": "Very Thirsty"},
	90: {"stamina_max": -0.5, "stamina_regen": -0.9, "health_regen": -0.5, "health_drain": 1.0, "name": "Dehydrated"}
}

func _ready():
	print("HungerThirstSystem initialized")

func _process(delta):
	# Convert delta to approximate real-time
	var real_time_factor = delta * 60.0
	
	# Update hunger and thirst
	var old_hunger = hunger
	var old_thirst = thirst
	
	hunger = min(100.0, hunger + current_hunger_rate * real_time_factor)
	thirst = min(100.0, thirst + current_thirst_rate * real_time_factor)
	
	# Check thresholds and emit signals
	check_thresholds(old_hunger, hunger, "hunger")
	check_thresholds(old_thirst, thirst, "thirst")
	
	# Apply damage if starving/dehydrated
	if is_starving:
		starvation_damage_timer += delta
		if starvation_damage_timer >= 10.0:  # Damage every 10 seconds
			apply_starvation_damage()
			starvation_damage_timer = 0.0
	
	if is_dehydrated:
		dehydration_damage_timer += delta
		if dehydration_damage_timer >= 5.0:  # Damage every 5 seconds
			apply_dehydration_damage()
			dehydration_damage_timer = 0.0

func check_thresholds(old_value: float, new_value: float, type: String):
	var thresholds = hunger_effects if type == "hunger" else thirst_effects
	
	for threshold in thresholds.keys():
		if old_value < threshold and new_value >= threshold:
			if type == "hunger":
				if threshold == 90:
					starvation_started.emit()
					is_starving = true
			elif type == "thirst":
				if threshold == 90:
					dehydration_started.emit()
					is_dehydrated = true
		
		if old_value >= threshold and new_value < threshold:
			if type == "hunger" and threshold == 90:
				is_starving = false
			elif type == "thirst" and threshold == 90:
				is_dehydrated = false

func apply_starvation_damage():
	# Apply health damage
	var parent = get_parent()
	if parent and parent.has_method("take_damage"):
		parent.take_damage(2.0, "starvation", null)
		print("Taking starvation damage!")

func apply_dehydration_damage():
	# Apply health damage (more frequent than starvation)
	var parent = get_parent()
	if parent and parent.has_method("take_damage"):
		parent.take_damage(3.0, "dehydration", null)
		print("Taking dehydration damage!")

func eat(food_value: float, hydration_bonus: float = 0.0):
	var old_hunger = hunger
	hunger = max(0.0, hunger - food_value)
	thirst = max(0.0, thirst - hydration_bonus)
	
	if hunger <= 20.0 and old_hunger > 20.0:
		needs_met.emit()
	
	hunger_changed.emit(hunger)
	thirst_changed.emit(thirst)
	
	print("Ate food. Hunger:", hunger, " Thirst:", thirst)

func drink(water_value: float):
	var old_thirst = thirst
	thirst = max(0.0, thirst - water_value)
	
	if thirst <= 20.0 and old_thirst > 20.0:
		needs_met.emit()
	
	thirst_changed.emit(thirst)
	
	print("Drank water. Thirst:", thirst)

func update_rates(activity_multiplier: float = 1.0):
	# Adjust rates based on activity level
	current_hunger_rate = base_hunger_rate * activity_multiplier
	current_thirst_rate = base_thirst_rate * activity_multiplier * 1.2  # Thirst increases faster

func get_current_effects() -> Dictionary:
	var effects = {}
	
	# Add hunger effects
	for threshold in hunger_effects.keys():
		if hunger >= threshold:
			effects.merge(hunger_effects[threshold], true)
	
	# Add thirst effects
	for threshold in thirst_effects.keys():
		if thirst >= threshold:
			effects.merge(thirst_effects[threshold], true)
	
	return effects

func get_status() -> Dictionary:
	return {
		"hunger": hunger,
		"thirst": thirst,
		"is_starving": is_starving,
		"is_dehydrated": is_dehydrated,
		"effects": get_current_effects()
	}
