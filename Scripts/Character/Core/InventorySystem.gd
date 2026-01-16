extends Node
class_name UniversalInventorySystem  # CHANGED: Renamed to avoid conflict

signal inventory_updated
signal weight_changed(current_weight, max_weight)

@export var base_capacity_kg: float = 20.0
@export var equipped_capacity_bonus: float = 0.0

var character: BaseCharacter3D = null
var items: Dictionary = {}  # item_id: {data, quantity}
var total_weight_kg: float = 0.0
var encumbrance_level: String = "none"

func _ready():
	pass

func initialize_inventory():
	print("Inventory initialized for ", character.character_name if character else "unknown")
	# Start with some basic items for testing
	add_test_items()

func add_test_items():
	# Test items
	var test_items = [
		{"id": "bandage", "name": "Bandage", "weight": 0.1, "quantity": 3},
		{"id": "water", "name": "Water Bottle", "weight": 0.5, "quantity": 2},
		{"id": "food", "name": "Canned Food", "weight": 0.3, "quantity": 2}
	]
	
	for item in test_items:
		add_item(item, item.quantity)
	
	print("Added test items to inventory")

func add_item(item_data: Dictionary, quantity: int = 1) -> bool:
	var item_id = item_data.get("id", str(item_data))
	
	# Check weight capacity
	var item_weight = item_data.get("weight", 0.1) * quantity
	if total_weight_kg + item_weight > get_max_capacity():
		print("Cannot add item: overweight!")
		return false
	
	# Add or update item
	if items.has(item_id):
		items[item_id].quantity += quantity
	else:
		items[item_id] = {
			"data": item_data,
			"quantity": quantity
		}
	
	# Update weight
	total_weight_kg += item_weight
	update_encumbrance()
	
	inventory_updated.emit()
	weight_changed.emit(total_weight_kg, get_max_capacity())
	
	print("Added ", quantity, "x ", item_data.get("name", "Unknown"), " to inventory")
	return true

func remove_item(item_id: String, quantity: int = 1) -> bool:
	if not items.has(item_id):
		return false
	
	var item = items[item_id]
	if item.quantity < quantity:
		return false
	
	# Update weight
	var item_weight = item.data.get("weight", 0.1) * quantity
	total_weight_kg = max(total_weight_kg - item_weight, 0)
	
	# Remove or reduce quantity
	item.quantity -= quantity
	if item.quantity <= 0:
		items.erase(item_id)
	
	update_encumbrance()
	inventory_updated.emit()
	weight_changed.emit(total_weight_kg, get_max_capacity())
	
	return true

func has_item(item_id: String, quantity: int = 1) -> bool:
	return items.has(item_id) and items[item_id].quantity >= quantity

func get_item_count(item_id: String) -> int:
	return items.get(item_id, {"quantity": 0}).quantity

func get_item_data(item_id: String) -> Variant:
	if items.has(item_id):
		return items[item_id].data
	return null

func get_max_capacity() -> float:
	return base_capacity_kg + equipped_capacity_bonus

func get_current_weight() -> float:
	return total_weight_kg

func get_encumbrance_level() -> String:
	return encumbrance_level

func get_encumbrance_speed_multiplier() -> float:
	match encumbrance_level:
		"none", "light":
			return 1.0
		"moderate":
			return 0.85
		"heavy":
			return 0.65
		"overloaded":
			return 0.4
	return 1.0

func update_encumbrance():
	var capacity_percentage = (total_weight_kg / get_max_capacity()) * 100
	
	if capacity_percentage < 50:
		encumbrance_level = "light"
	elif capacity_percentage < 75:
		encumbrance_level = "moderate"
	elif capacity_percentage < 100:
		encumbrance_level = "heavy"
	else:
		encumbrance_level = "overloaded"

func drop_all_items(position: Vector3):
	print("Dropping all items at ", position)
	# This would instantiate item pickups in the world
	for item_id in items:
		var item = items[item_id]
		print("Dropped: ", item.data.get("name", "Unknown"), " x", item.quantity)
	
	items.clear()
	total_weight_kg = 0
	update_encumbrance()
	inventory_updated.emit()

func get_inventory_summary() -> Dictionary:
	var item_list = []
	for item_id in items:
		var item = items[item_id]
		item_list.append({
			"name": item.data.get("name", "Unknown"),
			"id": item_id,
			"quantity": item.quantity,
			"weight": item.data.get("weight", 0.1) * item.quantity
		})
	
	return {
		"total_items": item_list.size(),
		"total_weight": total_weight_kg,
		"max_capacity": get_max_capacity(),
		"encumbrance": encumbrance_level,
		"items": item_list
	}
