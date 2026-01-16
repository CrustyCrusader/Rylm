# Survival/NeedsEffects.gd
class_name NeedsEffects
extends Node

# Signals
signal need_effect_applied(need_type: String, severity: float)
signal need_effect_removed(need_type: String)

# Need effects data
var hunger_effects: Dictionary = {
	"minor": {"speed_multiplier": 0.9, "stamina_regen": 0.8},
	"moderate": {"speed_multiplier": 0.7, "stamina_regen": 0.5, "health_drain": 0.5},
	"severe": {"speed_multiplier": 0.5, "stamina_regen": 0.2, "health_drain": 2.0}
}

var thirst_effects: Dictionary = {
	"minor": {"stamina_regen": 0.7},
	"moderate": {"stamina_regen": 0.3, "health_drain": 1.0},
	"severe": {"stamina_regen": 0.0, "health_drain": 5.0, "speed_multiplier": 0.3}
}

var fatigue_effects: Dictionary = {
	"minor": {"speed_multiplier": 0.95},
	"moderate": {"speed_multiplier": 0.8, "stamina_regen": 0.6},
	"severe": {"speed_multiplier": 0.5, "stamina_regen": 0.2, "vision_blur": true}
}

# Active effects
var active_effects: Array = []

# Character reference
var character: BaseCharacter3D

func initialize(character_ref: BaseCharacter3D) -> void:
	character = character_ref
	print("NeedsEffects initialized for: ", character.character_name)

func _process(_delta: float) -> void:  # Fixed: underscore before unused parameter
	process_active_effects()

func apply_need_effects(hunger_level: float, thirst_level: float, fatigue_level: float) -> void:
	clear_effects()
	
	# Apply hunger effects
	if hunger_level >= 75.0:
		apply_effect("hunger_severe", hunger_effects["severe"])
	elif hunger_level >= 50.0:
		apply_effect("hunger_moderate", hunger_effects["moderate"])
	elif hunger_level >= 25.0:
		apply_effect("hunger_minor", hunger_effects["minor"])
	
	# Apply thirst effects
	if thirst_level >= 75.0:
		apply_effect("thirst_severe", thirst_effects["severe"])
	elif thirst_level >= 50.0:
		apply_effect("thirst_moderate", thirst_effects["moderate"])
	elif thirst_level >= 25.0:
		apply_effect("thirst_minor", thirst_effects["minor"])
	
	# Apply fatigue effects
	if fatigue_level >= 75.0:
		apply_effect("fatigue_severe", fatigue_effects["severe"])
	elif fatigue_level >= 50.0:
		apply_effect("fatigue_moderate", fatigue_effects["moderate"])
	elif fatigue_level >= 25.0:
		apply_effect("fatigue_minor", fatigue_effects["minor"])

func apply_effect(effect_name: String, effect_data: Dictionary) -> void:
	var effect = {
		"name": effect_name,
		"data": effect_data,
		"start_time": Time.get_unix_time_from_system()
	}
	
	active_effects.append(effect)
	need_effect_applied.emit(effect_name, 1.0)
	apply_effect_to_character(effect_data)

func apply_effect_to_character(effect_data: Dictionary) -> void:
	if not character or not character.stats:
		return
	
	# Apply speed multiplier
	var speed_multiplier = effect_data.get("speed_multiplier", 1.0)
	if speed_multiplier != 1.0 and character.movement:
		character.movement.set_speed_multiplier(speed_multiplier)
	
	# Apply stamina regen multiplier
	var stamina_regen = effect_data.get("stamina_regen", 1.0)
	if stamina_regen != 1.0:
		character.stats.stamina_regen_multiplier = stamina_regen
	
	# Apply health drain
	var health_drain = effect_data.get("health_drain", 0.0)
	if health_drain > 0.0:
		character.take_damage(health_drain, "environmental")

func clear_effects() -> void:
	for effect in active_effects:
		need_effect_removed.emit(effect["name"])
	
	active_effects.clear()
	
	# Reset character multipliers
	if character and character.stats:
		character.stats.stamina_regen_multiplier = 1.0
	if character and character.movement:
		character.movement.set_speed_multiplier(1.0)

func process_active_effects() -> void:
	var current_time = Time.get_unix_time_from_system()
	
	for effect in active_effects:
		# Apply continuous effects (like health drain)
		var effect_data = effect["data"]
		var health_drain = effect_data.get("health_drain", 0.0)
		
		if health_drain > 0.0 and character and character.is_alive:
			character.take_damage(health_drain * get_physics_process_delta_time(), "environmental")

func get_active_effects() -> Array:
	return active_effects.duplicate()

func has_effect(effect_name: String) -> bool:
	for effect in active_effects:
		if effect["name"] == effect_name:
			return true
	return false

func remove_effect(effect_name: String) -> bool:
	for i in range(active_effects.size()):
		if active_effects[i]["name"] == effect_name:
			var effect = active_effects[i]
			active_effects.remove_at(i)
			need_effect_removed.emit(effect_name)
			
			# Recalculate remaining effects
			recalculate_effects()
			return true
	
	return false

func recalculate_effects() -> void:
	# Clear and reapply based on current needs
	if character and character.survival_system:
		apply_need_effects(
			character.survival_system.hunger,
			character.survival_system.thirst,
			character.survival_system.fatigue
		)
