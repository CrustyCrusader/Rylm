# SurvivalSystem/FatigueSystem.gd
extends Node
class_name FatigueSystem

signal fatigue_changed(new_value: float)
signal exhausted_changed(is_exhausted: bool)
signal rested(rest_quality: float)

# Fatigue settings
@export var base_fatigue_rate: float = 0.3  # per real minute
@export var sleep_recovery_rate: float = 10.0  # per real minute when sleeping
@export var rest_recovery_rate: float = 2.0   # per real minute when resting

var fatigue: float = 0.0  # 0-100
var is_exhausted: bool = false
var recovery_multiplier: float = 1.0

# Time tracking
var time_since_sleep: float = 0.0  # in real seconds
var consecutive_awake_hours: float = 0.0

func _ready():
	print("FatigueSystem initialized")

func _process(delta):
	# Update fatigue
	var old_fatigue = fatigue
	
	if is_exhausted:
		# Fatigue accumulates faster when exhausted
		fatigue = min(100.0, fatigue + base_fatigue_rate * delta * 60.0 * 1.5)
	else:
		fatigue = min(100.0, fatigue + base_fatigue_rate * delta * 60.0)
	
	# Track awake time
	time_since_sleep += delta
	consecutive_awake_hours = time_since_sleep / 3600.0
	
	# Check exhaustion threshold
	if not is_exhausted and fatigue >= 90.0:
		is_exhausted = true
		exhausted_changed.emit(true)
	elif is_exhausted and fatigue < 80.0:
		is_exhausted = false
		exhausted_changed.emit(false)
	
	if old_fatigue != fatigue:
		fatigue_changed.emit(fatigue)

func rest(rest_duration: float, rest_type: String = "sit"):
	var old_fatigue = fatigue
	
	match rest_type:
		"sleep":
			fatigue = max(0.0, fatigue - sleep_recovery_rate * rest_duration)
			time_since_sleep = 0.0
			consecutive_awake_hours = 0.0
		"lie":
			fatigue = max(0.0, fatigue - rest_recovery_rate * rest_duration * 0.8)
		"sit":
			fatigue = max(0.0, fatigue - rest_recovery_rate * rest_duration * 0.5)
		"lean":
			fatigue = max(0.0, fatigue - rest_recovery_rate * rest_duration * 0.3)
	
	fatigue_changed.emit(fatigue)
	
	# Calculate rest quality
	var fatigue_reduced = old_fatigue - fatigue
	var rest_quality = fatigue_reduced / (sleep_recovery_rate * rest_duration)
	rested.emit(rest_quality)
	
	print("Rested (", rest_type, "). Fatigue:", fatigue)

func exert_effort(effort_level: float):
	# Increase fatigue based on physical activity
	fatigue = min(100.0, fatigue + effort_level * 5.0)
	fatigue_changed.emit(fatigue)

func update_fatigue_rate(activity_level: float, encumbrance_multiplier: float = 1.0):
	base_fatigue_rate = 0.3 * activity_level * encumbrance_multiplier

func get_fatigue_effects() -> Dictionary:
	var effects = {}
	
	if fatigue >= 40.0:
		effects["stamina_regen"] = -0.3
		effects["movement_speed"] = -0.1
	
	if fatigue >= 70.0:
		effects["stamina_regen"] = -0.6
		effects["movement_speed"] = -0.2
		effects["accuracy"] = -0.2
	
	if fatigue >= 90.0:
		effects["stamina_regen"] = -0.9
		effects["movement_speed"] = -0.4
		effects["accuracy"] = -0.4
		effects["chance_to_collapse"] = 0.01
	
	return effects

func get_status() -> Dictionary:
	return {
		"fatigue": fatigue,
		"is_exhausted": is_exhausted,
		"time_since_sleep_hours": consecutive_awake_hours,
		"effects": get_fatigue_effects(),
		"recovery_rate": sleep_recovery_rate * recovery_multiplier
	}
