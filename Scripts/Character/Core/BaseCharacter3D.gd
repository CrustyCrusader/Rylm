extends CharacterBody3D
class_name BaseCharacter3D

#region Core Systems
@onready var stats: StatManager = $StatManager
@onready var inventory: UniversalInventory = $InventorySystem
@onready var equipment: EquipmentManager = $EquipmentManager
@onready var faction: FactionComponent = $FactionComponent
@onready var movement: MovementController = $MovementController
#endregion

#region Character Identity
@export var character_name: String = "Unnamed"
@export var character_race: String = "human"
@export var character_type: String = "player"
var unique_id: String = ""
#endregion

#region State Management
var is_alive: bool = true
var is_conscious: bool = true
var current_action: String = "idle"
var movement_state: String = "standing"
var movement_locked: bool = false  
#endregion

func _ready():
	generate_unique_id()
	initialize_character()
	print("Character spawned: ", character_name, " (", character_race, " ", character_type, ")")

func generate_unique_id():
	unique_id = str(get_instance_id()) + "_" + str(Time.get_unix_time_from_system())

func initialize_character():
	# Setup all components
	if stats:
		stats.character = self
		if stats.has_method("initialize_stats"):
			stats.initialize_stats(character_race, character_type)
	
	if inventory:
		inventory.character = self
		if inventory.has_method("initialize_inventory"):
			inventory.initialize_inventory()
	
	if equipment:
		# FIXED: Use proper property/method checking
		# Check if equipment has a 'character' property by trying to set it
		var script = equipment.get_script()
		if script:
			# Try to set character property if it exists in the script
			equipment.set("character", self)
		
		# Alternatively, if equipment has a set_character method, use it
		if equipment.has_method("set_character"):
			equipment.set_character(self)
		
		# Initialize equipment
		if equipment.has_method("initialize_equipment"):
			equipment.initialize_equipment()
	
	if faction:
		faction.character = self
		if faction.has_method("initialize_faction"):
			faction.initialize_faction(character_race, character_type)
	
	if movement:
		print("DEBUG: Setting movement.character = ", self)
		movement.character = self
		print("DEBUG: movement.character is now: ", movement.character)

func _physics_process(delta):
	if not is_alive or not is_conscious:
		return
	
	# Update stats (stamina drain, hunger, etc.)
	if stats:
		stats.process_stats(delta)
	
	# Apply encumbrance effects to movement
	if inventory and movement:
		var encumbrance_multiplier = inventory.get_encumbrance_speed_multiplier()
		movement.set_speed_multiplier(encumbrance_multiplier)
	
	# Handle movement
	if movement:
		movement.process_movement(delta)
	
	move_and_slide()

#region Public API
# BaseCharacter3D.gd - Update take_damage method
func take_damage(amount: float, damage_type: String = "physical", attacker = null):
	if not is_alive:
		return 0  # Return 0 if already dead
	
	var final_damage = amount
	
	# Apply defense reductions if we have equipment
	if equipment:
		final_damage = equipment.calculate_damage_reduction(final_damage, damage_type)
	
	# Store the damage that will be dealt
	var damage_to_deal = min(final_damage, stats.current_health)
	
	stats.take_damage(final_damage)
	
	if stats.current_health <= 0:
		die()
	elif attacker:
		on_attacked(attacker)
	
	return damage_to_deal  # Return the actual damage dealt

func heal(amount: float):
	if is_alive:
		stats.heal(amount)

func use_stamina(amount: float) -> bool:
	return stats.use_stamina(amount)

func can_perform_action(stamina_cost: float = 0.0) -> bool:
	if not is_alive or not is_conscious:
		return false
	
	if stamina_cost > 0:
		return stats.current_stamina >= stamina_cost
	
	return true

func add_item(item_data, quantity: int = 1) -> bool:
	if inventory:
		return inventory.add_item(item_data, quantity)
	return false

func remove_item(item_id: String, quantity: int = 1) -> bool:
	if inventory:
		return inventory.remove_item(item_id, quantity)
	return false

# FIXED: Changed return type from bool to Variant
func get_item_data(item_id: String) -> Variant:
	if inventory:
		return inventory.get_item_data(item_id)
	return null

func equip_item(item_data, slot: String = "") -> Dictionary:
	if equipment:
		return equipment.equip_item(item_data, slot)
	return {}

func unequip_item(slot: String) -> Variant:
	if equipment:
		return equipment.unequip_item(slot)
	return {}

func has_item(item_id: String, quantity: int = 1) -> bool:
	if inventory:
		return inventory.has_item(item_id, quantity)
	return false

func get_item_count(item_id: String) -> int:
	if inventory:
		return inventory.get_item_count(item_id)
	return 0

# FIXED: Changed return type from bool to Dictionary
func get_character_summary() -> Dictionary:
	var health_value = 0.0
	var stamina_value = 0.0
	var inventory_weight = 0.0
	var encumbrance_level = "none"
	var equipment_summary = {}
	var faction_info = {}
	
	if stats:
		health_value = stats.current_health
		stamina_value = stats.current_stamina
	
	if inventory:
		inventory_weight = inventory.get_current_weight()
		encumbrance_level = inventory.get_encumbrance_level()
	
	if equipment:
		equipment_summary = equipment.get_equipment_summary()
	
	if faction:
		faction_info = faction.get_faction_info()
	
	var summary = {
		"name": character_name,
		"race": character_race,
		"type": character_type,
		"alive": is_alive,
		"health": health_value,
		"stamina": stamina_value,
		"inventory_weight": inventory_weight,
		"encumbrance_level": encumbrance_level,
		"equipment": equipment_summary,
		"faction": faction_info
	}
	return summary
#endregion

#region Event Handlers
func on_attacked(attacker):
	print(character_name, " was attacked by ", attacker.character_name if attacker else "unknown")
	# Can be overridden by specific character types

func die():
	is_alive = false
	print(character_name, " has died")
	
	# Drop inventory items
	if inventory:
		inventory.drop_all_items(global_position)
	
	# Play death animation
	if has_node("AnimationPlayer"):
		$AnimationPlayer.play("AnimationLibrary_Godot_Standard/Death01")
	
	# Schedule removal
	await get_tree().create_timer(3.0).timeout
	queue_free()
#endregion
