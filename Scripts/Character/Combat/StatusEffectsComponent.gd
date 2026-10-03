# res://Scripts/Character/Combat/StatusEffectsComponent.gd
extends Node
class_name StatusEffectsComponent

# --- SIGNALS ---
signal effect_added(effect_name: String, duration: float)
signal effect_removed(effect_name: String)
signal effect_expired(effect_name: String)
signal effect_refreshed(effect_name: String, new_duration: float)

signal curse_applied(curse: CurseDataResource)
signal curse_removed(curse: CurseDataResource)
signal vice_started(vice_id: String)
signal vice_withdrawal_started(vice_id: String)

# --- INNER CLASSES ---
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

# --- STATE VARIABLES ---
var character: BaseCharacter3D
var active_effects: Dictionary = {}  # effect_name: StatusEffect

# Arcane Curses & Vice Dependencies
var active_curses: Array[CurseDataResource] = []
var active_vices: Dictionary = {} # vice_id: String -> remaining_time: float

# --- LIFECYCLE ---
func _ready():
	character = get_parent() as BaseCharacter3D

func _process(delta: float):
	# Update Standard Status Effects
	var effects_to_remove = []
	for effect_name in active_effects:
		var effect = active_effects[effect_name]
		if effect.update(delta):
			effects_to_remove.append(effect_name)
			effect_expired.emit(effect_name)
		else:
			apply_effect(effect, delta)
	
	for effect_name in effects_to_remove:
		remove_effect(effect_name)
		
	# Process Vice Buff Timers
	_process_vices(delta)

# --- STATUS EFFECT METHODS ---
func apply_effect(effect: StatusEffect, delta: float = 0.0):
	if not character:
		return
	
	var frame_delta := delta if delta > 0.0 else get_process_delta_time()
	
	match effect.name:
		"poison":
			if "stats" in character and character.stats:
				character.stats.take_damage(effect.data.get("damage_per_second", 1.0) * frame_delta)
		"burn":
			if "stats" in character and character.stats:
				character.stats.take_damage(effect.data.get("damage_per_second", 2.0) * frame_delta)
		"bleed":
			if "stats" in character and character.stats:
				character.stats.take_damage(effect.data.get("damage_per_second", 1.5) * frame_delta)
		"stun":
			character.movement_locked = true
		"slow":
			if "speed_multiplier" in character:
				character.speed_multiplier = effect.data.get("slow_multiplier", 0.5)
		"strength_buff":
			if "stats" in character and character.stats:
				pass

func add_effect(effect_name: String, duration: float, effect_data: Dictionary = {}) -> bool:
	if not character or has_immunity(effect_name):
		return false
	
	if active_effects.has(effect_name):
		var existing_effect = active_effects[effect_name]
		if existing_effect.stacks < existing_effect.max_stacks:
			existing_effect.stacks += 1
			existing_effect.duration = duration
			effect_refreshed.emit(effect_name, duration)
			return true
		else:
			existing_effect.duration = max(existing_effect.duration, duration)
			effect_refreshed.emit(effect_name, existing_effect.duration)
			return true
	else:
		var new_effect = StatusEffect.new(effect_name, duration, effect_data)
		match effect_name:
			"poison", "burn", "bleed":
				new_effect.max_stacks = 5
			_:
				new_effect.max_stacks = 1
		
		active_effects[effect_name] = new_effect
		effect_added.emit(effect_name, duration)
		apply_effect(new_effect)
		return true

func remove_effect(effect_name: String) -> bool:
	if active_effects.has(effect_name):
		var effect = active_effects[effect_name]
		cleanup_effect(effect)
		active_effects.erase(effect_name)
		effect_removed.emit(effect_name)
		return true
	return false

func cleanup_effect(effect: StatusEffect):
	match effect.name:
		"stun":
			character.movement_locked = false
		"slow":
			if "speed_multiplier" in character:
				character.speed_multiplier = 1.0

func has_immunity(effect_name: String) -> bool:
	if not character:
		return false
	if "equipment" in character and character.equipment:
		for slot in character.equipment.equipped_items:
			var item = character.equipment.equipped_items[slot]
			if item and item.has("immunities") and effect_name in item.immunities:
				return true
	return false

func get_effect_duration(effect_name: String) -> float:
	return active_effects[effect_name].duration if active_effects.has(effect_name) else 0.0

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

# --- ARCANE CURSE SYSTEM ---
func apply_curse(curse: CurseDataResource) -> void:
	if not curse:
		return
	if not has_curse(curse.get_id()):
		active_curses.append(curse)
		curse_applied.emit(curse)

func has_curse(curse_id: String) -> bool:
	for curse in active_curses:
		if curse.get_id() == curse_id:
			return true
	return false

func remove_curse_by_id(curse_id: String) -> void:
	for i in range(active_curses.size() - 1, -1, -1):
		if active_curses[i].get_id() == curse_id:
			var removed_curse = active_curses[i]
			active_curses.remove_at(i)
			curse_removed.emit(removed_curse)

func process_investigation_text(original_text: String) -> String:
	for curse in active_curses:
		if curse.corrupts_investigation_text and randf() < curse.text_corruption_chance:
			return "[Corrupted Text: The symbols twist into unreadable static...]"
	return original_text

# --- VICE & DEPENDENCY LOOP ---
func apply_vice_buff(vice_id: String, duration_seconds: float) -> void:
	active_vices[vice_id] = duration_seconds
	vice_started.emit(vice_id)

func _process_vices(delta: float) -> void:
	if active_vices.is_empty():
		return
		
	var keys = active_vices.keys()
	for vice_id in keys:
		active_vices[vice_id] -= delta
		if active_vices[vice_id] <= 0.0:
			active_vices.erase(vice_id)
			vice_withdrawal_started.emit(vice_id)
