# Equipment/ItemEffects.gd
class_name ItemEffects
extends Node

# Signals
signal effect_applied(effect_name: String, duration: float)
signal effect_removed(effect_name: String)
signal effect_tick(effect_name: String, remaining_time: float)

# Active effects
var active_effects: Dictionary = {}

# Effect definitions
var effect_definitions: Dictionary = {
	"healing": {
		"type": "buff",
		"duration": 10.0,
		"tick_rate": 1.0,
		"on_tick": "_on_healing_tick",
		"on_end": "_on_healing_end"
	},
	"poison": {
		"type": "debuff",
		"duration": 15.0,
		"tick_rate": 2.0,
		"on_tick": "_on_poison_tick",
		"on_end": "_on_poison_end"
	},
	"strength": {
		"type": "buff",
		"duration": 30.0,
		"tick_rate": 0.0,  # No ticks
		"on_tick": "",
		"on_end": "_on_strength_end"
	},
	"invisibility": {
		"type": "buff",
		"duration": 20.0,
		"tick_rate": 0.0,
		"on_tick": "",
		"on_end": "_on_invisibility_end"
	}
}

# Character reference
var character: BaseCharacter3D

func initialize(character_ref: BaseCharacter3D) -> void:
	character = character_ref
	print("ItemEffects initialized for: ", character.character_name)

func _process(delta: float) -> void:
	process_effects(delta)

func apply_effect(effect_name: String, duration: float = -1.0, custom_data: Dictionary = {}) -> bool:
	if effect_name not in effect_definitions:
		print("Unknown effect: ", effect_name)
		return false
	
	# Use default duration if not specified
	if duration <= 0:
		duration = effect_definitions[effect_name]["duration"]
	
	# Create effect data
	var effect_data = {
		"name": effect_name,
		"type": effect_definitions[effect_name]["type"],
		"duration": duration,
		"remaining_time": duration,
		"tick_rate": effect_definitions[effect_name]["tick_rate"],
		"tick_timer": effect_definitions[effect_name]["tick_rate"],
		"data": custom_data,
		"start_time": Time.get_unix_time_from_system()
	}
	
	# Add to active effects
	active_effects[effect_name] = effect_data
	
	# Apply initial effect
	apply_initial_effect(effect_name, effect_data)
	
	effect_applied.emit(effect_name, duration)
	print("Effect applied: ", effect_name, " for ", duration, " seconds")
	
	return true

func apply_initial_effect(effect_name: String, effect_data: Dictionary) -> void:
	match effect_name:
		"healing":
			if character and character.stats:
				character.stats.health_regen_multiplier = 2.0
		"poison":
			if character and character.stats:
				character.stats.health_regen_multiplier = 0.5
		"strength":
			if character and character.stats:
				character.stats.damage_multiplier = 1.5
		"invisibility":
			if character:
				character.visible = false

func process_effects(delta: float) -> void:
	var effects_to_remove: Array = []
	
	for effect_name in active_effects:
		var effect_data = active_effects[effect_name]
		
		# Update remaining time
		effect_data["remaining_time"] -= delta
		effect_data["tick_timer"] -= delta
		
		# Process tick if needed
		if effect_data["tick_rate"] > 0 and effect_data["tick_timer"] <= 0:
			process_effect_tick(effect_name, effect_data)
			effect_data["tick_timer"] = effect_data["tick_rate"]
			effect_tick.emit(effect_name, effect_data["remaining_time"])
		
		# Check if effect should be removed
		if effect_data["remaining_time"] <= 0:
			effects_to_remove.append(effect_name)
	
	# Remove expired effects
	for effect_name in effects_to_remove:
		remove_effect(effect_name)

func process_effect_tick(effect_name: String, effect_data: Dictionary) -> void:
	match effect_name:
		"healing":
			if character and character.stats:
				character.heal(character.stats.max_health * 0.02)  # 2% healing per tick
		"poison":
			if character and character.stats:
				character.take_damage(character.stats.max_health * 0.03, "poison")  # 3% damage per tick

func remove_effect(effect_name: String) -> bool:
	if effect_name not in active_effects:
		return false
	
	var effect_data = active_effects[effect_name]
	
	# Apply end effect
	apply_end_effect(effect_name, effect_data)
	
	# Remove from active effects
	active_effects.erase(effect_name)
	
	effect_removed.emit(effect_name)
	print("Effect removed: ", effect_name)
	
	return true

func apply_end_effect(effect_name: String, effect_data: Dictionary) -> void:
	match effect_name:
		"healing":
			if character and character.stats:
				character.stats.health_regen_multiplier = 1.0
		"poison":
			if character and character.stats:
				character.stats.health_regen_multiplier = 1.0
		"strength":
			if character and character.stats:
				character.stats.damage_multiplier = 1.0
		"invisibility":
			if character:
				character.visible = true

func has_effect(effect_name: String) -> bool:
	return effect_name in active_effects

func get_effect_remaining_time(effect_name: String) -> float:
	if effect_name in active_effects:
		return active_effects[effect_name]["remaining_time"]
	return 0.0

func get_active_effects() -> Array:
	var effects: Array = []
	for effect_name in active_effects:
		effects.append({
			"name": effect_name,
			"remaining_time": active_effects[effect_name]["remaining_time"],
			"type": active_effects[effect_name]["type"]
		})
	return effects

func clear_all_effects() -> void:
	for effect_name in active_effects.keys():
		remove_effect(effect_name)

# Helper to emit effect removed signal
func emit_effect_removed_signal(effect_name: String) -> void:
	effect_removed.emit(effect_name)

func refresh_effect(effect_name: String, duration: float = -1.0) -> bool:
	if not has_effect(effect_name):
		return false
	
	if duration <= 0:
		duration = effect_definitions[effect_name]["duration"]
	
	active_effects[effect_name]["remaining_time"] = duration
	active_effects[effect_name]["tick_timer"] = active_effects[effect_name]["tick_rate"]
	
	print("Effect refreshed: ", effect_name, " for ", duration, " seconds")
	return true
