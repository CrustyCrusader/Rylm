class_name CombatComponent
extends Node

signal attack_started()
signal attack_finished()
signal hit_landed(target: Node, damage: float, is_critical: bool)

@export var attack_rate: float = 1.0
@export var stamina_cost: float = 15.0
@export var base_damage: float = 25.0
@export_range(0.0, 1.0) var crit_chance: float = 0.1
@export var crit_multiplier: float = 1.5

var can_attack: bool = true
@onready var attack_timer: Timer = Timer.new()

func _ready() -> void:
	add_child(attack_timer)
	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_attack_timer_timeout)

func execute_attack(target_defense: DefenseComponent = null, armor_pen: float = 0.0) -> float:
	if not can_attack:
		return 0.0
		
	can_attack = false
	attack_timer.start(1.0 / maxf(attack_rate, 0.1))
	attack_started.emit()
	
	var is_crit := randf() < crit_chance
	var calculated_damage := base_damage * (crit_multiplier if is_crit else 1.0)
	
	if target_defense:
		calculated_damage = target_defense.calculate_incoming_damage(calculated_damage, armor_pen)
		
	hit_landed.emit(target_defense, calculated_damage, is_crit)
	return calculated_damage

func _on_attack_timer_timeout() -> void:
	can_attack = true
	attack_finished.emit()
