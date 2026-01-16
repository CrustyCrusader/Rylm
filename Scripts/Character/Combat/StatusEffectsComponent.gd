# Character/Combat/StatusEffectsComponent.gd
extends Node
class_name StatusEffectsComponent

signal effect_added(effect_name, duration)
signal effect_removed(effect_name)
signal effect_expired(effect_name)
signal effect_refreshed(effect_name, new_duration)

class StatusEffect:
	var name: String
	var duration: float
	var max_duration: float
	var stacks: int = 1
	var max_stacks: int = 1
	var data: Dictionary
	
	func _init(effect_name: String, effect_duration: float, effect_data: Dictionary = {}):
		name = effect_name
		duration = effect_duration
		max_duration = effect_duration
		data = effect_data
	
	func update(delta: float) -> bool:
		duration -= delta
		return duration <= 0

var character: BaseCharacter3D
var active_effects: Dictionary = {}  # effect_name: StatusEffect

func _ready():
	character = get_parent() as BaseCharacter3D

func _process(delta):
	var effects_to_remove = []
	
	for effect_name in active_effects:
		var effect = active_effects[effect_name]
		
		# Update effect duration
		if effect.update(delta):
			effects_to_remove.append(effect_name)
			effect_expired.emit(effect_name)
		else:
			# Apply effect each frame
			apply_effect(effect)
	
	# Remove expired effects
	for effect_name in effects_to_remove:
		remove_effect(effect_name)

func apply_effect(effect: StatusEffect):
	if not character:
		return
	
	# Apply effect based on type
	match effect.name:
		"poison":
			character.stats.take_damage(effect.data.get("damage_per_second", 1.0) * get_physics_process_delta_time())
		
		"burn":
			character.stats.take_damage(effect.data.get("damage_per_second", 2.0) * get_physics_process_delta_time())
		
		"bleed":
			character.stats.take_damage(effect.data.get("damage_per_second", 1.5) * get_physics_process_delta_time())
		
		"stun":
			character.movement_locked = true
		
		"slow":
			if character.movement:
				character.movement.speed_multiplier = effect.data.get("slow_multiplier", 0.5)
		
		"strength_buff":
			if character.stats:
				# This would modify damage calculations
				pass

func add_effect(effect_name: String, duration: float, effect_data: Dictionary = {}) -> bool:
	if not character:
		return false
	
	# Check for immunities/resistances
	if has_immunity(effect_name):
		return false
	
	# Check if effect already exists
	if active_effects.has(effect_name):
		var existing_effect = active_effects[effect_name]
		
		# Check stacking
		if existing_effect.stacks < existing_effect.max_stacks:
			existing_effect.stacks += 1
			existing_effect.duration = duration
			effect_refreshed.emit(effect_name, duration)
			return true
		else:
			# Refresh duration if already at max stacks
			existing_effect.duration = max(existing_effect.duration, duration)
			effect_refreshed.emit(effect_name, existing_effect.duration)
			return true
	else:
		# Create new effect
		var new_effect = StatusEffect.new(effect_name, duration, effect_data)
		
		# Set stacking limits
		match effect_name:
			"poison", "burn", "bleed":
				new_effect.max_stacks = 5
			_:
				new_effect.max_stacks = 1
		
		active_effects[effect_name] = new_effect
		effect_added.emit(effect_name, duration)
		
		# Apply initial effect
		apply_effect(new_effect)
		return true

func remove_effect(effect_name: String) -> bool:
	if active_effects.has(effect_name):
		var effect = active_effects[effect_name]
		
		# Clean up effect before removal
		cleanup_effect(effect)
		
		active_effects.erase(effect_name)
		effect_removed.emit(effect_name)
		return true
	
	return false

func cleanup_effect(effect: StatusEffect):
	# Remove any permanent changes from the effect
	match effect.name:
		"stun":
			character.movement_locked = false
		"slow":
			if character.movement:
				character.movement.speed_multiplier = 1.0

func has_immunity(effect_name: String) -> bool:
	# Check character resistances
	if not character:
		return false
	
	# Example: Check equipment for immunity
	if character.equipment:
		for slot in character.equipment.equipped_items:
			var item = character.equipment.equipped_items[slot]
			if item and item.has("immunities"):
				if effect_name in item.immunities:
					return true
	
	return false

func get_effect_duration(effect_name: String) -> float:
	if active_effects.has(effect_name):
		return active_effects[effect_name].duration
	return 0.0

func get_active_effects() -> Array:
	var effects = []
	for effect_name in active_effects:
		var effect = active_effects[effect_name]
		effects.append({
			"name": effect_name,
			"duration": effect.duration,
			"stacks": effect.stacks,
			"max_stacks": effect.max_stacks
		})
	return effects

func clear_all_effects():
	for effect_name in active_effects.keys():
		remove_effect(effect_name)
