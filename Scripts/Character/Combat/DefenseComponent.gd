class_name DefenseComponent
extends Node

signal damage_mitigated(original_damage: float, final_damage: float)
signal damage_blocked()
signal dodge_executed()

@export_range(0.0, 1.0) var block_chance: float = 0.15
@export_range(0.0, 1.0) var dodge_chance: float = 0.10
@export var base_damage_reduction: float = 5.0
@export_range(0.0, 0.9) var armor_mitigation_percent: float = 0.20

var is_blocking: bool = false

func set_damage_reduction(amount: float) -> void:
	base_damage_reduction = maxf(0.0, amount)

func execute_dodge() -> bool:
	if randf() < dodge_chance:
		dodge_executed.emit()
		return true
	return false

func calculate_incoming_damage(raw_damage: float, armor_penetration: float = 0.0) -> float:
	if execute_dodge():
		return 0.0
		
	if is_blocking and randf() < block_chance:
		damage_blocked.emit()
		return 0.0
		
	var effective_armor_percent := maxf(0.0, armor_mitigation_percent - armor_penetration)
	var damage_after_armor_pct := raw_damage * (1.0 - effective_armor_percent)
	var final_damage := maxf(0.0, damage_after_armor_pct - base_damage_reduction)
	
	damage_mitigated.emit(raw_damage, final_damage)
	return final_damage
