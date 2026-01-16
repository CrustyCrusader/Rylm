# Scripts/Character/Core/BaseCharacter3D.gd
extends CharacterBody3D
class_name BaseCharacter3D

# Core components (will be set up if nodes exist)
@onready var stats = $StatManager as StatManager
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

# Systems (will be initialized if nodes exist)
var skill_system: SkillSystem
var class_system: ClassSystem
var survival_system: SurvivalSystem
var body_parts: BodyPartSystem

# Signals
signal character_died()
signal character_damaged(damage: float, damage_type: String)
signal inventory_updated()

func _ready():
	generate_unique_id()
	call_deferred("initialize_character")
	print("Character spawned: ", character_name)

func initialize_character():
	print("Initializing character: ", character_name)
	
	# Initialize core components
	initialize_core_components()
	
	# Find and initialize other systems
	find_and_initialize_systems()
	
	# Connect signals
	connect_system_signals()
	
	print("Character initialization complete")

func initialize_core_components():
	# Initialize inventory if node exists
	var inventory_node = get_node_or_null("UniversalInventory")
	if inventory_node and inventory_node is UniversalInventory:
		inventory = inventory_node
		if inventory.has_method("initialize_inventory"):
			inventory.initialize_inventory()
	
	# Initialize stats if node exists
	if stats:
		stats.character = self
	
	# Initialize movement if node exists
	var movement_node = get_node_or_null("MovementController")
	if movement_node and movement_node is MovementController:
		movement = movement_node
		movement.character = self

func find_and_initialize_systems():
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

func connect_system_signals():
	if inventory and inventory.has_signal("inventory_updated"):
		inventory.inventory_updated.connect(_on_inventory_updated)

func _on_inventory_updated():
	inventory_updated.emit()

func take_damage(amount: float, damage_type: String = "physical", _attacker = null) -> float:  # Fixed: added underscore
	if not is_alive:
		return 0.0
	
	print(character_name, " taking ", amount, " ", damage_type, " damage")
	
	var damage_to_deal = min(amount, stats.current_health if stats else amount)
	
	if stats:
		stats.take_damage(amount)
	
	if stats and stats.current_health <= 0:
		die()
	elif _attacker:  # Now we can use the attacker parameter
		on_attacked(_attacker)
	
	character_damaged.emit(damage_to_deal, damage_type)
	
	return damage_to_deal

# ADD THIS FUNCTION: on_attacked
func on_attacked(attacker):
	print(character_name, " was attacked by ", attacker.character_name if attacker and attacker.has_method("get_character_name") else "unknown")
	# You can add more logic here, like aggro, counter-attack, etc.

func heal(amount: float):
	if is_alive and stats:
		stats.heal(amount)

func die():
	is_alive = false
	print(character_name, " has died")
	
	# Drop inventory items
	if inventory:
		inventory.drop_all_items(global_position)
	
	character_died.emit()

func generate_unique_id():
	var timestamp = str(Time.get_unix_time_from_system())
	var random = str(randi() % 10000)
	unique_id = timestamp + "_" + random
	print("Generated unique ID: ", unique_id)

# Fixed: added underscore to unused delta parameter
func _physics_process(_delta: float):
	# Base physics processing (can be empty or have basic logic)
	# This allows child classes to call super._physics_process(delta)
	pass

# Simple helper methods for testing
func test_injury():
	if body_parts:
		body_parts.apply_damage(BodyPartSystem.BodyPart.LEFT_ARM, 25.0)
		print("Test injury applied to left arm")

func test_heal():
	if stats:
		stats.heal(20.0)
		print("Healed 20 health")
