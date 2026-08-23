extends CharacterBody3D
class_name BaseCharacter3D

# Core components
@onready var stats = $StatManager as StatManager
@onready var animation_player: AnimationPlayer = get_node_or_null("AnimationPlayer")
var inventory: UniversalInventory
var equipment: EquipmentManager
var movement: MovementController

# Character identity
@export var character_name: String = "Unnamed"
@export var character_race: String = "human"
@export var character_type: String = "player"
var unique_id: String = ""

# State management
var is_alive: bool = true
var is_conscious: bool = true
var movement_locked: bool = false

# Systems
var skill_system: SkillSystem
var class_system: ClassSystem
var survival_system: SurvivalSystem
var body_parts: BodyPartSystem

# Death 
var _death_sequence_started: bool = false
@export var death_despawn_time: float = 15.0


# Signals
signal character_died()
signal character_damaged(damage: float, damage_type: String)
signal inventory_updated()

func _ready() -> void:
	generate_unique_id()
	call_deferred("initialize_character")

func initialize_character() -> void:
	# Initialize core components
	initialize_core_components()
	
	# Find and initialize other systems
	find_and_initialize_systems()
	
	# Connect signals
	connect_system_signals()

func initialize_core_components() -> void:
	# Initialize inventory if node exists
	var inventory_node = get_node_or_null("UniversalInventory")
	if inventory_node and inventory_node is UniversalInventory:
		inventory = inventory_node
		if inventory.has_method("initialize_inventory"):
			inventory.initialize_inventory()
	
	# Initialize stats if node exists
	if stats:
		stats.character = self
		print("Inventory found: ", inventory)
	# Initialize movement if node exists
	var movement_node = get_node_or_null("MovementController")
	if movement_node and movement_node is MovementController:
		movement = movement_node
		if movement.has_method("initialize"):
			movement.initialize(self)

func find_and_initialize_systems() -> void:
	# Find and initialize skill system
	var skill_node = get_node_or_null("SkillSystem")
	if skill_node and skill_node is SkillSystem:
		skill_system = skill_node
		skill_system.character = self
	
	# Find and initialize class system
	var class_node = get_node_or_null("ClassSystem")
	if class_node and class_node is ClassSystem:
		class_system = class_node
		class_system.character = self
	
	# Find and initialize survival system
	var survival_node = get_node_or_null("SurvivalSystem")
	if survival_node and survival_node is SurvivalSystem:
		survival_system = survival_node
		survival_system.character = self
	
	# Find and initialize body parts system
	var body_parts_node = get_node_or_null("BodyPartSystem")
	if body_parts_node and body_parts_node is BodyPartSystem:
		body_parts = body_parts_node
		body_parts.character = self

func connect_system_signals() -> void:
	if inventory and inventory.has_signal("inventory_updated"):
		inventory.inventory_updated.connect(_on_inventory_updated)

func _on_inventory_updated() -> void:
	inventory_updated.emit()

func take_damage(amount: float, damage_type: String = "physical", attacker = null) -> float:
	if not is_alive:
		return 0.0
	
	var damage_to_deal = min(amount, stats.current_health if stats else amount)
	if stats:
		stats.take_damage(amount)
	
	if stats and stats.current_health <= 0:
		is_alive = false
		die()
	elif attacker:
		on_attacked(attacker)
	
	character_damaged.emit(damage_to_deal, damage_type)
	return damage_to_deal

func on_attacked(_attacker) -> void:
	# Override this in child classes for specific behavior
	pass

func heal(amount: float) -> void:
	if is_alive and stats:
		stats.heal(amount)

func die() -> void:
	if _death_sequence_started:
		return
	_death_sequence_started = true
	
	_on_death_started()
	
	var anim_name = get_death_animation_name()
	if anim_name != "" and animation_player and animation_player.has_animation(anim_name):
		animation_player.play(anim_name)
		await animation_player.animation_finished
	else:
		await get_tree().create_timer(1.0).timeout
	
	_apply_fake_ragdoll()
	_convert_to_lootable_corpse()
	character_died.emit()
	
	await get_tree().create_timer(death_despawn_time).timeout
	queue_free()

func _on_death_started() -> void:
	pass

func get_death_animation_name() -> String:
	return ""

func pickup_item(item_id: String, quantity: int = 1) -> bool:
	var item_data = Item_Database.get_item(item_id)
	if not item_data:
		print("ERROR: No item found in database for id: ", item_id)
		return false
	
	if not inventory:
		print("ERROR: ", character_name, " has no inventory to receive item")
		return false
	
	var success = inventory.add_item(item_data, quantity)
	print("Pickup result for ", item_id, ": ", success)
	return success
	


func _apply_fake_ragdoll() -> void:
	set_physics_process(false)
	var visuals = get_node_or_null("Visuals")
	if visuals:
		var fall_dir = 1.0 if randf() > 0.5 else -1.0
		var tween = create_tween()
		tween.tween_property(visuals, "rotation:z", deg_to_rad(90) * fall_dir, 0.5)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _convert_to_lootable_corpse() -> void:
	add_to_group("lootable")

func generate_unique_id() -> void:
	var timestamp = str(Time.get_unix_time_from_system())
	var random = str(randi() % 10000)
	unique_id = timestamp + "_" + random

func _physics_process(_delta: float) -> void:
	# Base physics processing
	# Override in child classes for specific behavior
	pass

# Helper methods
func get_character_name() -> String:
	return character_name

func get_character_type() -> String:
	return character_type
