# ItemDatabase.gd
class_name ItemDatabase
extends Node

# Item structure
class ItemData:
	var item_id: String
	var display_name: String
	var description: String
	var weight_kg: float
	var max_stack: int
	var item_type: String
	var value: int
	
	func _init(id: String, name: String = "", desc: String = "", weight: float = 0.1, stack: int = 99, type: String = "misc", val: int = 1):
		item_id = id
		display_name = name if name != "" else id.capitalize()
		description = desc if desc != "" else "A " + display_name
		weight_kg = weight
		max_stack = stack
		item_type = type
		value = val

# Item database
var items: Dictionary = {}

# Default items
var default_items: Array = [
	ItemData.new("apple", "Apple", "A fresh red apple", 0.1, 20, "food", 5),
	ItemData.new("bandage", "Bandage", "For treating minor wounds", 0.05, 10, "medical", 10),
	ItemData.new("water_bottle", "Water Bottle", "Clean drinking water", 0.5, 5, "drink", 2),
	ItemData.new("pistol", "Pistol", "A standard issue pistol", 1.0, 1, "weapon", 100),
	ItemData.new("ammo_9mm", "9mm Ammo", "Ammunition for pistols", 0.02, 50, "ammo", 1),
	ItemData.new("medkit", "Medkit", "Comprehensive medical supplies", 1.5, 3, "medical", 50),
	ItemData.new("flashlight", "Flashlight", "Battery-powered light source", 0.3, 1, "tool", 25),
	ItemData.new("battery", "Battery", "AA battery for devices", 0.02, 20, "component", 3),
	ItemData.new("rope", "Rope", "Strong nylon rope", 0.8, 5, "tool", 15),
	ItemData.new("knife", "Knife", "Sharp survival knife", 0.4, 1, "tool", 30)
]

func _ready():
	create_default_items()
	print("ItemDatabase ready with ", items.size(), " items")

func create_default_items() -> void:
	print("Creating default items...")
	
	for item_data in default_items:
		# Create a Resource for the item
		var item_resource = ItemDataResource.new()
		
		# Set properties correctly - make sure they match ItemDataResource properties
		item_resource.set("item_id", item_data.item_id)
		item_resource.set("display_name", item_data.display_name)
		item_resource.set("description", item_data.description)
		item_resource.set("weight_kg", item_data.weight_kg)
		item_resource.set("max_stack", item_data.max_stack)
		item_resource.set("item_type", item_data.item_type)
		item_resource.set("value", item_data.value)
		
		# Store in dictionary
		items[item_data.item_id] = item_resource
		
		print("Created item: ", item_data.display_name, " (", item_data.item_id, ")")

func get_item(item_id: String) -> ItemDataResource:
	return items.get(item_id, null)

func get_item_complexity(item_id: String) -> float:
	var item = get_item(item_id)
	if item:
		# Simple complexity calculation based on weight and value
		return item.weight_kg * item.value * 0.1
	return 1.0

func get_item_resource(item_id: String) -> Resource:
	return get_item(item_id)

func has_item(item_id: String) -> bool:
	return item_id in items

func get_all_items() -> Array:
	return items.values()

func add_custom_item(item_resource: ItemDataResource) -> bool:
	if not item_resource or not item_resource.has("item_id"):
		return false
	
	var item_id = item_resource.get("item_id")
	if not item_id or item_id.is_empty():
		return false
	
	items[item_id] = item_resource
	return true

func remove_item(item_id: String) -> bool:
	return items.erase(item_id)

func get_item_count() -> int:
	return items.size()

func find_items_by_type(item_type: String) -> Array:
	var result = []
	for item_id in items:
		var item = items[item_id]
		if item and item.has("item_type") and item.get("item_type") == item_type:
			result.append(item)
	return result

func get_item_stats(item_id: String) -> Dictionary:
	var item = get_item(item_id)
	if not item:
		return {}
	
	return {
		"id": item.get("item_id") if item.has("item_id") else item_id,
		"name": item.get("display_name") if item.has("display_name") else "Unknown",
		"weight": item.get("weight_kg") if item.has("weight_kg") else 0.0,
		"max_stack": item.get("max_stack") if item.has("max_stack") else 1,
		"type": item.get("item_type") if item.has("item_type") else "misc"
	}
