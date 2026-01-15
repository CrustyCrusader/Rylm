extends Node
class_name UniversalInventory

#region Encumbrance Levels
enum EncumbranceLevel {
	NONE,       # 0-25%
	LIGHT,      # 25-50%
	MODERATE,   # 50-75%
	HEAVY,      # 75-100%
	OVERLOADED  # 100%+
}
#endregion

var character: BaseCharacter3D
var items: Array = []  # Array of dictionaries with item data
var current_encumbrance: EncumbranceLevel = EncumbranceLevel.NONE
var current_weight: float = 0.0

# Capacity determined by race + equipment
var base_capacity: float = 20.0  # kg
var equipped_capacity_bonus: float = 0.0

@export var debug_mode: bool = false

func initialize_inventory():
	# Set base capacity based on race
	if character:
		match character.character_race:
			"human":
				base_capacity = 25.0
			"alien":
				base_capacity = 30.0  # Aliens are stronger
			"zombie":
				base_capacity = 15.0  # Zombies are decayed
	
	print("Inventory initialized. Base capacity: ", base_capacity, "kg")

func get_total_capacity() -> float:
	return base_capacity + equipped_capacity_bonus

func add_item(item_data: Resource, quantity: int = 1) -> bool:
	if not item_data:
		print("ERROR: No item data provided")
		return false
	
	# Get item weight
	var item_weight = 1.0  # Default
	if item_data.has_method("get_weight_kg"):
		item_weight = item_data.get_weight_kg()
	elif item_data.has_meta("weight_kg"):
		item_weight = item_data.get_meta("weight_kg")
	
	item_weight *= quantity
	
	# Check if we can carry it
	if current_weight + item_weight > get_total_capacity():
		if debug_mode:
			print("Cannot add item: Would exceed capacity")
		return false
	
	# Get item ID - FIXED: Use different variable name
	var found_item_id = ""  # Changed from item_id to avoid duplicate
	if item_data.has_method("get_id"):
		found_item_id = item_data.get_id()
	elif item_data.has_meta("id"):
		found_item_id = item_data.get_meta("id")
	else:
		found_item_id = str(item_data.get_instance_id())
	
	# Get max stack - FIXED: Use different variable name
	var item_max_stack = 99  # Changed from max_stack to avoid duplicate
	if item_data.has_method("get_max_stack"):
		item_max_stack = item_data.get_max_stack()
	elif item_data.has_meta("max_stack"):
		item_max_stack = item_data.get_meta("max_stack")
	
	# Try to stack with existing items
	for item in items:
		var existing_item_data = item["item_data"]
		var existing_id = ""
		
		if existing_item_data.has_method("get_id"):
			existing_id = existing_item_data.get_id()
		elif existing_item_data.has_meta("id"):
			existing_id = existing_item_data.get_meta("id")
		
		if existing_id == found_item_id and item["quantity"] < item_max_stack:
			var can_stack = min(quantity, item_max_stack - item["quantity"])
			item["quantity"] += can_stack
			current_weight += item_weight / quantity * can_stack  # Adjust weight
			quantity -= can_stack
			
			if quantity <= 0:
				update_encumbrance()
				if debug_mode:
					print("Stacked item")
				return true
	
	# Add new item
	while quantity > 0:
		var stack_size = min(quantity, item_max_stack)
		var new_item = {
			"item_data": item_data,
			"quantity": stack_size,
			"condition": 1.0
		}
		items.append(new_item)
		current_weight += item_weight / (quantity + stack_size) * stack_size  # Adjust weight
		quantity -= stack_size
	
	update_encumbrance()
	
	if debug_mode:
		print("Added item")
	
	return true

func remove_item(item_id: String, quantity: int = 1) -> bool:
	for i in range(items.size() - 1, -1, -1):
		var item = items[i]
		if item["item_data"].id == item_id:
			var remove_count = min(quantity, item["quantity"])
			current_weight -= item["item_data"].weight_kg * remove_count
			item["quantity"] -= remove_count
			
			if item["quantity"] <= 0:
				items.remove_at(i)
			
			update_encumbrance()
			return true
	
	return false

func update_encumbrance():
	var capacity_percent = (current_weight / get_total_capacity()) * 100
	
	var old_level = current_encumbrance
	
	if capacity_percent >= 100:
		current_encumbrance = EncumbranceLevel.OVERLOADED
	elif capacity_percent >= 75:
		current_encumbrance = EncumbranceLevel.HEAVY
	elif capacity_percent >= 50:
		current_encumbrance = EncumbranceLevel.MODERATE
	elif capacity_percent >= 25:
		current_encumbrance = EncumbranceLevel.LIGHT
	else:
		current_encumbrance = EncumbranceLevel.NONE
	
	if old_level != current_encumbrance and debug_mode:
		print("Encumbrance level changed: ", EncumbranceLevel.keys()[current_encumbrance])

func get_encumbrance_speed_multiplier() -> float:
	match current_encumbrance:
		EncumbranceLevel.NONE:
			return 1.0
		EncumbranceLevel.LIGHT:
			return 0.9
		EncumbranceLevel.MODERATE:
			return 0.75
		EncumbranceLevel.HEAVY:
			return 0.5
		EncumbranceLevel.OVERLOADED:
			return 0.25
	return 1.0

func get_encumbrance_stamina_multiplier() -> float:
	match current_encumbrance:
		EncumbranceLevel.NONE:
			return 1.0
		EncumbranceLevel.LIGHT:
			return 1.1
		EncumbranceLevel.MODERATE:
			return 1.25
		EncumbranceLevel.HEAVY:
			return 1.5
		EncumbranceLevel.OVERLOADED:
			return 2.0
	return 1.0

func get_current_weight() -> float:
	return current_weight

func get_encumbrance_level() -> String:
	return EncumbranceLevel.keys()[current_encumbrance]

func drop_all_items(drop_position: Vector3):
	if debug_mode:
		print("Dropping all items at position: ", drop_position)
	
	# In a real game, you'd spawn item pickups here
	for item in items:
		print("Dropping: ", item["item_data"].display_name, " x", item["quantity"])
	
	items.clear()
	current_weight = 0
	update_encumbrance()

func get_item_data(item_id: String) -> Variant:  # FIXED: Returns item data or null
	for item in items:
		if item["item_data"].id == item_id:
			return item["item_data"]
	return null

func has_item(item_id: String, quantity: int = 1) -> bool:
	var total_quantity = 0
	for item in items:
		if item["item_data"].id == item_id:
			total_quantity += item["quantity"]
			if total_quantity >= quantity:
				return true
	return false

func get_item_count(item_id: String) -> int:
	var total = 0
	for item in items:
		if item["item_data"].id == item_id:
			total += item["quantity"]
	return total

func get_inventory_summary() -> Dictionary:
	var item_list = []
	for item in items:
		item_list.append({
			"name": item["item_data"].display_name,
			"quantity": item["quantity"],
			"weight": item["item_data"].weight_kg * item["quantity"]
		})
	
	return {
		"total_items": items.size(),
		"total_weight": current_weight,
		"capacity": get_total_capacity(),
		"encumbrance_level": get_encumbrance_level(),
		"speed_multiplier": get_encumbrance_speed_multiplier(),
		"stamina_multiplier": get_encumbrance_stamina_multiplier(),
		"items": item_list
	}
