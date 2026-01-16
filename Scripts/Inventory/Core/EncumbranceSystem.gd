# EncumbranceSystem.gd
extends Node
class_name EncumbranceSystem

signal encumbrance_changed(new_level: String, speed_multiplier: float)
signal overload_warning()
signal capacity_reached()

# Encumbrance levels
enum EncumbranceLevel {
	NONE,       # 0-25%
	LIGHT,      # 25-50%
	MODERATE,   # 50-75%
	HEAVY,      # 75-100%
	OVERLOADED  # 100%+
}

# Capacity settings
@export var base_capacity: float = 25.0  # kg
@export var strength_capacity_multiplier: float = 2.0  # per strength point

# Current state
var current_capacity: float = 25.0
var current_weight: float = 0.0
var encumbrance_level: EncumbranceLevel = EncumbranceLevel.NONE

# Effects for each level
var encumbrance_effects = {
	EncumbranceLevel.NONE: {
		"speed_multiplier": 1.0,
		"stamina_multiplier": 1.0,
		"noise_multiplier": 1.0,
		"dodge_chance": 1.0
	},
	EncumbranceLevel.LIGHT: {
		"speed_multiplier": 0.9,
		"stamina_multiplier": 1.1,
		"noise_multiplier": 1.1,
		"dodge_chance": 0.95
	},
	EncumbranceLevel.MODERATE: {
		"speed_multiplier": 0.75,
		"stamina_multiplier": 1.25,
		"noise_multiplier": 1.25,
		"dodge_chance": 0.9
	},
	EncumbranceLevel.HEAVY: {
		"speed_multiplier": 0.5,
		"stamina_multiplier": 1.5,
		"noise_multiplier": 1.5,
		"dodge_chance": 0.8
	},
	EncumbranceLevel.OVERLOADED: {
		"speed_multiplier": 0.25,
		"stamina_multiplier": 2.0,
		"noise_multiplier": 2.0,
		"dodge_chance": 0.5
	}
}

func _ready():
	print("EncumbranceSystem initialized")
	recalculate_capacity()

func recalculate_capacity(strength_level: int = 1):
	# Calculate capacity based on strength
	current_capacity = base_capacity + (strength_level * strength_capacity_multiplier)
	print("Capacity updated:", current_capacity, "kg (Strength level:", strength_level, ")")

func add_weight(weight: float) -> bool:
	var old_level = encumbrance_level
	
	current_weight += weight
	update_encumbrance_level()
	
	# Check for warnings
	if current_weight >= current_capacity * 0.9 and old_level < EncumbranceLevel.OVERLOADED:
		overload_warning.emit()
	
	if current_weight >= current_capacity:
		capacity_reached.emit()
	
	return current_weight <= current_capacity

func remove_weight(weight: float):
	current_weight = max(0, current_weight - weight)
	update_encumbrance_level()

func update_encumbrance_level():
	var percentage = (current_weight / current_capacity) * 100.0
	
	var old_level = encumbrance_level
	
	if percentage >= 100.0:
		encumbrance_level = EncumbranceLevel.OVERLOADED
	elif percentage >= 75.0:
		encumbrance_level = EncumbranceLevel.HEAVY
	elif percentage >= 50.0:
		encumbrance_level = EncumbranceLevel.MODERATE
	elif percentage >= 25.0:
		encumbrance_level = EncumbranceLevel.LIGHT
	else:
		encumbrance_level = EncumbranceLevel.NONE
	
	if old_level != encumbrance_level:
		var effects = get_current_effects()
		encumbrance_changed.emit(EncumbranceLevel.keys()[encumbrance_level], effects["speed_multiplier"])

func get_current_effects() -> Dictionary:
	return encumbrance_effects.get(encumbrance_level, {})

func can_add_weight(weight: float) -> bool:
	return current_weight + weight <= current_capacity

func get_available_capacity() -> float:
	return max(0, current_capacity - current_weight)

func get_status() -> Dictionary:
	var effects = get_current_effects()
	
	return {
		"current_weight": current_weight,
		"capacity": current_capacity,
		"percentage": (current_weight / current_capacity) * 100.0,
		"encumbrance_level": EncumbranceLevel.keys()[encumbrance_level],
		"effects": effects,
		"available_capacity": get_available_capacity()
	}

func reset():
	current_weight = 0.0
	encumbrance_level = EncumbranceLevel.NONE
	encumbrance_changed.emit(EncumbranceLevel.keys()[encumbrance_level], 1.0)
