extends Resource
class_name InventoryCore

signal inventory_updated
signal encumbrance_changed(encumbrance_level)


# Encumbrance levels affect movement speed
enum EncumbranceLevel { LIGHT, MODERATE, HEAVY, OVERLOADED }

@export var base_capacity_kg := 20.0  # What character can carry without equipment

var items: Array[InventorySlot] = []
var total_weight_kg: float = 0.0
var current_encumbrance: EncumbranceLevel = EncumbranceLevel.LIGHT

# Equipment slots - these add capacity
var equipped_backpack: InventoryItemData = null
var equipped_pants: InventoryItemData = null
var equipped_jacket: InventoryItemData = null
var equipped_case: InventoryItemData = null

func get_total_capacity() -> float:
	var capacity = base_capacity_kg
	
	# Equipment bonuses
	if equipped_backpack:
		capacity += equipped_backpack.capacity_bonus
	if equipped_pants:
		capacity += equipped_pants.capacity_bonus
	if equipped_jacket:
		capacity += equipped_jacket.capacity_bonus
	if equipped_case:
		capacity += equipped_case.capacity_bonus
	
	return capacity

func calculate_encumbrance() -> EncumbranceLevel:
	var capacity_used_percent = (total_weight_kg / get_total_capacity()) * 100
	
	if capacity_used_percent < 50:
		return EncumbranceLevel.LIGHT
	elif capacity_used_percent < 75:
		return EncumbranceLevel.MODERATE
	elif capacity_used_percent < 100:
		return EncumbranceLevel.HEAVY
	else:
		return EncumbranceLevel.OVERLOADED

func update_encumbrance():
	var new_level = calculate_encumbrance()
	if new_level != current_encumbrance:
		current_encumbrance = new_level
		encumbrance_changed.emit(new_level)
		return true
	return false

func add_item(item_data: InventoryItemData, quantity: int = 1) -> Dictionary:
	var result = { "success": false, "message": "", "overflow": 0 }
	
	# Calculate weight of what we're trying to add
	var added_weight = item_data.weight_kg * quantity
	var available_capacity = get_total_capacity() - total_weight_kg
	
	if added_weight > available_capacity:
		# Calculate how many we CAN add
		var max_quantity = int(available_capacity / item_data.weight_kg)
		if max_quantity <= 0:
			result.message = "Too heavy! Can't carry even one."
			result.overflow = quantity
			return result
		
		quantity = max_quantity
		result.overflow = quantity - max_quantity
		result.message = "Only carried %d due to weight limit." % quantity
	
	# Actual adding logic (from previous system, modified for weight)
	var remaining = quantity
	
	# Try stacking first
	for i in range(items.size()):
		if items[i].item_data == item_data and items[i].quantity < items[i].item_data.max_stack:
			var can_add = min(remaining, items[i].item_data.max_stack - items[i].quantity)
			items[i].quantity += can_add
			total_weight_kg += item_data.weight_kg * can_add
			remaining -= can_add
			if remaining <= 0:
				break
	
	# Add new slots if needed
	while remaining > 0 and get_available_slots() > 0:
		var can_add = min(remaining, item_data.max_stack)
		var new_slot = InventorySlot.new()
		new_slot.item_data = item_data
		new_slot.quantity = can_add
		items.append(new_slot)
		total_weight_kg += item_data.weight_kg * can_add
		remaining -= can_add
	
	result.success = remaining == 0
	if result.success and result.message == "":
		result.message = "Picked up %d %s" % [quantity, item_data.display_name]
	
	inventory_updated.emit()
	update_encumbrance()
	return result

func get_available_slots() -> int:
	# Different equipment provides different slot types
	var total_slots = 10  # Base pockets
	
	if equipped_pants:
		total_slots += equipped_pants.slot_bonus.pants
	if equipped_jacket:
		total_slots += equipped_jacket.slot_bonus.jacket
	if equipped_backpack:
		total_slots += equipped_backpack.slot_bonus.backpack
	if equipped_case:
		total_slots += equipped_case.slot_bonus.case
	
	return total_slots - items.size()

func get_encumbrance_penalty() -> float:
	# Returns a multiplier for movement speed
	match current_encumbrance:
		EncumbranceLevel.LIGHT:
			return 1.0
		EncumbranceLevel.MODERATE:
			return 0.85
		EncumbranceLevel.HEAVY:
			return 0.65
		EncumbranceLevel.OVERLOADED:
			return 0.4
	return 1.0

func search_items(search_term: String) -> Array[InventorySlot]:
	var results: Array[InventorySlot] = []
	search_term = search_term.to_lower()
	
	for slot in items:
		# Check name
		if search_term in slot.item_data.display_name.to_lower():
			results.append(slot)
			continue
		
		# Check flavor text
		if search_term in slot.item_data.flavor_text.to_lower():
			results.append(slot)
			continue
		
		# Check tags (PackedStringArray has find() method)
		if slot.item_data.tags.find(search_term) != -1:
			results.append(slot)
			continue
		
		# Check custom note
		if slot.custom_note != "" and search_term in slot.custom_note.to_lower():
			results.append(slot)
	
	return results

func highlight_items_by_tag(tag: String, _highlight_color: Color = Color.YELLOW) -> Array[int]:
	var highlighted_slots: Array[int] = []
	
	for i in range(items.size()):
		if tag in items[i].item_data.tags:
			highlighted_slots.append(i)
	
	return highlighted_slots
