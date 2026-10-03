extends Node
class_name StatManager

# Reference to parent character
var character: BaseCharacter3D

#region Base Stats
@export_category("Health")
@export var max_health: float = 100.0
@export var health_regen_rate: float = 0.5  # per second
@export var health_regen_delay: float = 5.0  # seconds after damage

@export_category("Stamina")
@export var max_stamina: float = 100.0
@export var stamina_regen_rate: float = 10.0  # per second
@export var stamina_drain_multiplier: float = 1.0  # Modified by encumbrance

@export_category("Needs System - For Survival")
@export var max_hunger: float = 100.0
@export var max_thirst: float = 100.0
@export var max_fatigue: float = 100.0
@export var hunger_rate: float = 0.5  # per minute
@export var thirst_rate: float = 1.0   # per minute
@export var fatigue_rate: float = 0.2  # per minute
#endregion

#region Current Values
var current_health: float = 100.0
var current_stamina: float = 100.0
var current_hunger: float = 0.0
var current_thirst: float = 0.0
var current_fatigue: float = 0.0
#endregion

#region Status Timers
var time_since_last_damage: float = 0.0
var is_exhausted: bool = false
var is_starving: bool = false
var is_dehydrated: bool = false
#endregion

func initialize_stats(race: String, character_type: String) -> void:
	# Set base stats based on race and type
	match race:
		"human":
			max_health = 100.0
			max_stamina = 100.0
			stamina_regen_rate = 10.0
		"alien":
			max_health = 120.0
			max_stamina = 80.0
			stamina_regen_rate = 15.0
		"zombie":
			max_health = 150.0
			max_stamina = 50.0
			stamina_regen_rate = 5.0
			health_regen_rate = 2.0  # Zombies regenerate!
	
	# Reset current values
	current_health = max_health
	current_stamina = max_stamina
	current_hunger = 0.0
	current_thirst = 0.0
	current_fatigue = 0.0
	
	print("Stats initialized for ", race, " ", character_type)

func process_stats(delta: float) -> void:
	time_since_last_damage += delta
	
	# Regenerate health if not recently damaged
	if time_since_last_damage > health_regen_delay:
		current_health = minf(current_health + health_regen_rate * delta, max_health)
	
	# Regenerate stamina (slower when exhausted)
	var effective_stamina_regen := stamina_regen_rate
	if is_exhausted:
		effective_stamina_regen *= 0.3
	
	current_stamina = minf(current_stamina + effective_stamina_regen * delta, max_stamina)
	
	# Update needs (convert per-minute rates to per-second)
	current_hunger = minf(current_hunger + (hunger_rate / 60.0) * delta, max_hunger)
	current_thirst = minf(current_thirst + (thirst_rate / 60.0) * delta, max_thirst)
	current_fatigue = minf(current_fatigue + (fatigue_rate / 60.0) * delta, max_fatigue)
	
	# Check status effects
	update_status_effects(delta)

func take_damage(amount: float) -> void:
	current_health -= amount
	time_since_last_damage = 0.0
	
	# Apply stun on character if hit is heavy
	if amount > max_health * 0.25:
		if character and character.has_method("apply_stun"):
			character.apply_stun(0.5)
	
	var char_name := character.character_name if character else "Character"
	print("%s took %f damage. Health: %f" % [char_name, amount, current_health])

func heal(amount: float) -> void:
	current_health = minf(current_health + amount, max_health)

func use_stamina(amount: float) -> bool:
	if current_stamina >= amount:
		current_stamina -= amount
		return true
	return false

func drain_stamina_over_time(rate: float, delta: float) -> bool:
	var drain_amount := rate * delta * stamina_drain_multiplier
	if current_stamina >= drain_amount:
		current_stamina -= drain_amount
		return true
	
	# Not enough stamina
	current_stamina = 0.0
	is_exhausted = true
	return false

func update_status_effects(delta: float) -> void:
	# Check for exhaustion
	is_exhausted = current_stamina < max_stamina * 0.1
	
	# Check for starvation/dehydration
	is_starving = current_hunger >= max_hunger * 0.9
	is_dehydrated = current_thirst >= max_thirst * 0.9
	
	# Apply penalties using delta passed from process_stats
	if is_starving:
		current_health -= 0.1 * delta  # Starvation damage
	if is_dehydrated:
		current_stamina = maxf(current_stamina - 2.0 * delta, 0.0)

func eat(food_value: float) -> void:
	current_hunger = maxf(current_hunger - food_value, 0.0)
	is_starving = false

func drink(thirst_value: float) -> void:
	current_thirst = maxf(current_thirst - thirst_value, 0.0)
	is_dehydrated = false

func rest(fatigue_reduction: float) -> void:
	current_fatigue = maxf(current_fatigue - fatigue_reduction, 0.0)
	if current_fatigue < max_fatigue * 0.3:
		is_exhausted = false

func get_stamina_percentage() -> float:
	return current_stamina / max_stamina if max_stamina > 0 else 0.0

func get_health_percentage() -> float:
	return current_health / max_health if max_health > 0 else 0.0

func get_stat_summary() -> Dictionary:
	return {
		"health": {
			"current": current_health,
			"max": max_health,
			"percentage": get_health_percentage()
		},
		"stamina": {
			"current": current_stamina,
			"max": max_stamina,
			"percentage": get_stamina_percentage(),
			"exhausted": is_exhausted
		},
		"needs": {
			"hunger": current_hunger,
			"thirst": current_thirst,
			"fatigue": current_fatigue,
			"starving": is_starving,
			"dehydrated": is_dehydrated
		}
	}
