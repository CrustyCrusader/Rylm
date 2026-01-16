# ItemDataResource.gd
extends Resource
class_name ItemDataResource

# Item properties
@export var item_id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var weight_kg: float = 0.1
@export var max_stack: int = 99
@export var item_type: String = "misc"
@export var value: int = 1
@export var icon_texture: Texture2D
@export var mesh: Mesh
@export var is_consumable: bool = false
@export var durability: float = 100.0
@export var rarity: String = "common"  # common, uncommon, rare, epic, legendary

# Additional metadata
@export var tags: Array[String] = []
@export var effects: Dictionary = {}
@export var requirements: Dictionary = {}
@export var crafting_recipe: Array = []

func _init():
	# Ensure item_id is set if not already
	if item_id.is_empty():
		item_id = str(get_instance_id())

func get_id() -> String:
	return item_id

func get_weight_kg() -> float:
	return weight_kg

func get_max_stack() -> int:
	return max_stack

func get_display_name() -> String:
	return display_name

func get_description() -> String:
	return description

# Usage functions (if needed)
func on_use(character) -> void:
	if character and character.has_method("use_item"):
		character.use_item(self)

func on_equip(character) -> void:
	if character and character.has_method("equip_item"):
		character.equip_item(self)

func on_unequip(character) -> void:
	if character and character.has_method("unequip_item"):
		character.unequip_item(self)

func get_save_data() -> Dictionary:
	return {
		"item_id": item_id,
		"display_name": display_name,
		"description": description,
		"weight_kg": weight_kg,
		"max_stack": max_stack,
		"item_type": item_type,
		"value": value,
		"durability": durability,
		"rarity": rarity,
		"tags": tags,
		"effects": effects
	}

func load_from_data(data: Dictionary) -> void:
	if data.has("item_id"):
		item_id = data["item_id"]
	elif item_id.is_empty():  # Only generate new ID if we don't have one already
		item_id = "item_" + str(randi())  # FIXED: changed "id" to "item_id"
	
	if data.has("display_name"):
		display_name = data["display_name"]
	
	if data.has("description"):
		description = data["description"]
	
	if data.has("weight_kg"):
		weight_kg = data["weight_kg"]
	
	if data.has("max_stack"):
		max_stack = data["max_stack"]
	
	if data.has("item_type"):
		item_type = data["item_type"]
	
	if data.has("value"):
		value = data["value"]
	
	if data.has("durability"):
		durability = data["durability"]
	
	if data.has("rarity"):
		rarity = data["rarity"]
	
	if data.has("tags"):
		tags = data["tags"]
	
	if data.has("effects"):
		effects = data["effects"]
	
	# Set default display name if empty
	if display_name.is_empty():
		display_name = "Unnamed Item"
