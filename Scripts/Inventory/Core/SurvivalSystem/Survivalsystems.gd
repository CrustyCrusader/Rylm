# Survival/SurvivalSystems.gd
class_name SurvivalSystem
extends Node

# Signals
signal hunger_changed(new_value: float, old_value: float)
signal thirst_changed(new_value: float, old_value: float)
signal fatigue_changed(new_value: float, old_value: float)
signal body_temperature_changed(new_temp: float, old_temp: float)
signal need_critical(need_type: String, value: float)

# Survival stats
var hunger: float = 0.0
var thirst: float = 0.0
var fatigue: float = 0.0
var body_temperature: float = 37.0  # Celsius

# Rates (per second)
var hunger_rate: float = 0.1
var thirst_rate: float = 0.15
var fatigue_rate: float = 0.05
var temperature_change_rate: float = 0.01

# Critical thresholds
var critical_hunger: float = 90.0
var critical_thirst: float = 90.0
var critical_fatigue: float = 90.0
var critical_temperature_low: float = 35.0
var critical_temperature_high: float = 39.0

# Character reference
var character: BaseCharacter3D

func initialize(character_ref: BaseCharacter3D) -> void:
	character = character_ref
	print("SurvivalSystem initialized for: ", character.character_name)

func _process(delta: float) -> void:
	process_needs(delta)
	process_temperature(delta)
	check_critical_needs()

func process_needs(delta: float) -> void:
	# Update hunger
	var old_hunger = hunger
	hunger = min(hunger + hunger_rate * delta, 100.0)
	if abs(hunger - old_hunger) > 0.1:
		hunger_changed.emit(hunger, old_hunger)
	
	# Update thirst
	var old_thirst = thirst
	thirst = min(thirst + thirst_rate * delta, 100.0)
	if abs(thirst - old_thirst) > 0.1:
		thirst_changed.emit(thirst, old_thirst)
	
	# Update fatigue
	var old_fatigue = fatigue
	fatigue = min(fatigue + fatigue_rate * delta, 100.0)
	if abs(fatigue - old_fatigue) > 0.1:
		fatigue_changed.emit(fatigue, old_fatigue)

func process_temperature(delta: float) -> void:
	if not character:
		return
	
	var old_temp = body_temperature
	
	# Environmental temperature effect (simplified)
	var environment_temp = get_environment_temperature()
	var temp_difference = environment_temp - body_temperature
	
	# Adjust body temperature toward environment
	body_temperature += temp_difference * temperature_change_rate * delta
	
	# Clamp to reasonable range
	body_temperature = clamp(body_temperature, 30.0, 42.0)
	
	if abs(body_temperature - old_temp) > 0.1:
		body_temperature_changed.emit(body_temperature, old_temp)

func get_environment_temperature() -> float:
	# Simplified: return base temperature
	return 20.0  # 20°C room temperature

func check_critical_needs() -> void:
	if hunger >= critical_hunger:
		need_critical.emit("hunger", hunger)
	
	if thirst >= critical_thirst:
		need_critical.emit("thirst", thirst)
	
	if fatigue >= critical_fatigue:
		need_critical.emit("fatigue", fatigue)
	
	if body_temperature <= critical_temperature_low:
		need_critical.emit("temperature_low", body_temperature)
	elif body_temperature >= critical_temperature_high:
		need_critical.emit("temperature_high", body_temperature)

func eat(food_value: float) -> void:
	var old_hunger = hunger
	hunger = max(hunger - food_value, 0.0)
	hunger_changed.emit(hunger, old_hunger)

func drink(drink_value: float) -> void:
	var old_thirst = thirst
	thirst = max(thirst - drink_value, 0.0)
	thirst_changed.emit(thirst, old_thirst)

func rest(rest_value: float) -> void:
	var old_fatigue = fatigue
	fatigue = max(fatigue - rest_value, 0.0)
	fatigue_changed.emit(fatigue, old_fatigue)

func warm_up(amount: float) -> void:
	var old_temp = body_temperature
	body_temperature = min(body_temperature + amount, 37.5)
	body_temperature_changed.emit(body_temperature, old_temp)

func cool_down(amount: float) -> void:
	var old_temp = body_temperature
	body_temperature = max(body_temperature - amount, 36.5)
	body_temperature_changed.emit(body_temperature, old_temp)

func set_rates(new_hunger_rate: float, new_thirst_rate: float, new_fatigue_rate: float) -> void:
	hunger_rate = new_hunger_rate
	thirst_rate = new_thirst_rate
	fatigue_rate = new_fatigue_rate

func get_need_levels() -> Dictionary:
	return {
		"hunger": hunger,
		"thirst": thirst,
		"fatigue": fatigue,
		"body_temperature": body_temperature
	}

func are_needs_critical() -> bool:
	return (hunger >= critical_hunger or 
			thirst >= critical_thirst or 
			fatigue >= critical_fatigue or
			body_temperature <= critical_temperature_low or
			body_temperature >= critical_temperature_high)

# Helper to emit temperature signal
func emit_temperature_signal(new_temp: float, old_temp: float) -> void:
	body_temperature_changed.emit(new_temp, old_temp)
