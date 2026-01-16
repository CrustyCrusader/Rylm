# HealthSystem/InfectionSystem.gd
extends Node
class_name InfectionSystem

signal infection_level_changed(new_level: float)
signal infection_critical()
signal infection_cleared()
signal sepsis_started()

# Infection progression
enum InfectionStage {
	NONE,           # 0-20%
	MILD,           # 20-40%
	MODERATE,       # 40-60%
	SEVERE,         # 60-80%
	CRITICAL,       # 80-100%
	SEPTIC_SHOCK    # 100% + complications
}

# Infection source types
enum InfectionSource {
	WOUND,
	CONTAMINATED_FOOD,
	CONTAMINATED_WATER,
	ENVIRONMENT,
	ANIMAL_BITE
}

# Current state
var infection_level: float = 0.0  # 0-100%
var current_stage: InfectionStage = InfectionStage.NONE
var infection_sources: Array[Dictionary] = []
var antibiotic_resistance: float = 0.0  # Reduces treatment effectiveness

# Infection rates
var base_spread_rate: float = 0.1  # per hour
var fever_level: float = 0.0  # 0-100%
var is_septic: bool = false

func _ready():
	print("InfectionSystem initialized")

func _process(delta):
	if infection_level <= 0:
		return
	
	var old_level = infection_level
	
	# Calculate spread based on severity
	var spread_rate = base_spread_rate * (1.0 + infection_level / 100.0)
	
	# Fever increases spread
	spread_rate *= (1.0 + fever_level / 50.0)
	
	# Update infection level
	infection_level = min(100.0, infection_level + spread_rate * delta * 0.0167)  # Convert to per-second
	
	# Update fever
	update_fever(delta)
	
	# Check stage transitions
	check_stage_transition(old_level, infection_level)
	
	if infection_level != old_level:
		infection_level_changed.emit(infection_level)

func add_infection_source(source_type: InfectionSource, severity: float, location: String = ""):
	var source = {
		"type": source_type,
		"severity": severity,
		"location": location,
		"time_added": Time.get_unix_time_from_system(),
		"treated": false
	}
	
	infection_sources.append(source)
	
	# Increase infection level
	infection_level = min(100.0, infection_level + severity * 10.0)
	
	print("Infection source added: ", InfectionSource.keys()[source_type], " at ", location)

func treat_infection(treatment_power: float, targets: Array = []):
	if infection_level <= 0:
		return
	
	var old_level = infection_level
	
	# Apply resistance
	var effective_power = treatment_power * (1.0 - antibiotic_resistance)
	
	# Reduce infection level
	infection_level = max(0.0, infection_level - effective_power)
	
	# Mark sources as treated if targetted
	if targets.size() > 0:
		for source in infection_sources:
			if source["location"] in targets and not source["treated"]:
				source["treated"] = true
				infection_level -= source["severity"] * 5.0
	
	# Clear treated sources
	infection_sources = infection_sources.filter(func(source): return not source["treated"])
	
	# Check if cleared
	if infection_level <= 0:
		clear_infection()
	
	if infection_level != old_level:
		infection_level_changed.emit(infection_level)

func clear_infection():
	infection_level = 0.0
	infection_sources.clear()
	fever_level = 0.0
	is_septic = false
	current_stage = InfectionStage.NONE
	
	infection_cleared.emit()
	print("Infection cleared!")

func update_fever(delta):
	if infection_level <= 0:
		fever_level = max(0.0, fever_level - delta * 2.0)
		return
	
	# Fever increases with infection
	var target_fever = infection_level * 0.8
	var fever_change = (target_fever - fever_level) * delta * 0.1
	fever_level = clamp(fever_level + fever_change, 0.0, 100.0)

func check_stage_transition(old_level: float, new_level: float):
	var old_stage = get_stage_for_level(old_level)
	var new_stage = get_stage_for_level(new_level)
	
	if old_stage != new_stage:
		current_stage = new_stage
		print("Infection stage changed to: ", InfectionStage.keys()[new_stage])
		
		if new_stage == InfectionStage.CRITICAL:
			infection_critical.emit()
		elif new_stage == InfectionStage.SEPTIC_SHOCK:
			is_septic = true
			sepsis_started.emit()

func get_stage_for_level(level: float) -> InfectionStage:
	if level <= 20.0:
		return InfectionStage.NONE
	elif level <= 40.0:
		return InfectionStage.MILD
	elif level <= 60.0:
		return InfectionStage.MODERATE
	elif level <= 80.0:
		return InfectionStage.SEVERE
	elif level <= 100.0:
		return InfectionStage.CRITICAL
	else:
		return InfectionStage.SEPTIC_SHOCK

func get_infection_effects() -> Dictionary:
	var effects = {}
	
	if infection_level > 30.0:
		effects["health_regen"] = -0.3
		effects["stamina_regen"] = -0.2
	
	if infection_level > 50.0:
		effects["health_regen"] = -0.6
		effects["stamina_regen"] = -0.4
		effects["movement_speed"] = -0.1
	
	if infection_level > 70.0:
		effects["health_regen"] = -1.0
		effects["stamina_regen"] = -0.7
		effects["movement_speed"] = -0.2
		effects["health_drain"] = 0.5
	
	if fever_level > 30.0:
		effects["stamina_drain"] = 1.0 + (fever_level - 30.0) / 70.0
	
	return effects

func get_status() -> Dictionary:
	return {
		"level": infection_level,
		"stage": InfectionStage.keys()[current_stage],
		"fever": fever_level,
		"is_septic": is_septic,
		"sources_count": infection_sources.size(),
		"effects": get_infection_effects(),
		"resistance": antibiotic_resistance
	}
