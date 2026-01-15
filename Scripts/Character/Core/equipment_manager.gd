extends Node
class_name EquipmentManager

# Declare the character property to be set by BaseCharacter3D
var character: BaseCharacter3D = null

# Equipment slots with size restrictions
enum SlotSize { SMALL, MEDIUM, LARGE }

var equipped_items: Dictionary = {
	"head": null,
	"eyes": null,
	"jacket": null,
	"pants": null,
	"backpack": null,
	"toolbelt": null,
	"case": null,
	"hands": null
}

# What can go in each slot
var slot_restrictions: Dictionary = {
	"pants": {
		"size": SlotSize.SMALL,
		"max_weight_per_item": 0.5,
		"capacity_kg": 2.0,
		"slot_count": 4
	},
	"jacket": {
		"size": SlotSize.MEDIUM,
		"max_weight_per_item": 2.0,
		"capacity_kg": 5.0,
		"slot_count": 6
	},
	"backpack": {
		"size": SlotSize.LARGE,
		"max_weight_per_item": 10.0,
		"capacity_kg": 15.0,
		"slot_count": 20
	},
	"case": {
		"size": SlotSize.MEDIUM,
		"max_weight_per_item": 5.0,
		"capacity_kg": 8.0,
		"slot_count": 10,
		"protects": true
	}
}

func initialize_equipment():
	if character:
		print("Equipment initialized for: ", character.character_name)
	else:
		print("WARNING: EquipmentManager has no character reference")

func equip_item(item_data: Dictionary, slot: String = "") -> Dictionary:
	var result = { "success": false, "message": "" }
	
	# Auto-detect slot if not specified
	if slot == "":
		slot = detect_slot_from_item(item_data)
	
	# Check slot compatibility
	if slot not in equipped_items:
		result.message = "Invalid equipment slot."
		return result
	
	# Check if item is equippable
	if not item_data.get("is_equippable", true):
		result.message = "This item cannot be equipped."
		return result
	
	# Check size restrictions
	var restriction = slot_restrictions.get(slot, {})
	if restriction.has("size"):
		var item_size = get_item_size(item_data)
		if item_size > restriction.size:
			result.message = "Too large for this slot."
			return result
	
	# Check weight restrictions
	if restriction.has("max_weight_per_item") and item_data.get("weight_kg", 0) > restriction.max_weight_per_item:
		result.message = "Too heavy for this slot."
		return result
	
	# Unequip current item if any
	var old_item = equipped_items[slot]
	if old_item:
		unequip_item(slot)
	
	# Equip new item
	equipped_items[slot] = item_data
	result.success = true
	result["item"] = item_data
	
	# Messages
	match slot:
		"backpack":
			result.message = "Backpack equipped. Additional storage available!"
		"pants":
			result.message = "Pants equipped. Pocket space unlocked."
		"jacket":
			result.message = "Jacket equipped."
		"case":
			result.message = "Case secured."
		_:
			result.message = "%s equipped." % item_data.get("display_name", "Item")
	
	# Apply stat bonuses
	apply_equipment_bonuses()
	
	return result

func unequip_item(slot: String) -> Dictionary:
	var item = equipped_items[slot]
	if item:
		equipped_items[slot] = null
		remove_equipment_bonuses(item)
		return {"success": true, "item": item}
	return {"success": false, "item": null}

func remove_equipment_bonuses(item: Dictionary):
	# Remove bonuses when unequipping
	print("Removed bonuses from %s" % item.get("display_name", "Item"))
	# Reapply remaining bonuses
	apply_equipment_bonuses()

func detect_slot_from_item(item_data: Dictionary) -> String:
	# Check if item specifies a slot
	if item_data.has("equipment_slot"):
		return item_data.equipment_slot
	
	# Auto-detect based on item type
	if item_data.has("item_type"):
		match item_data.item_type:
			"hat", "helmet": return "head"
			"glasses", "goggles": return "eyes"
			"jacket", "coat": return "jacket"
			"pants", "trousers": return "pants"
			"backpack", "bag": return "backpack"
			"toolbelt": return "toolbelt"
			"case", "briefcase": return "case"
			"gloves": return "hands"
	
	return "accessory"  # Default

func get_item_size(item_data: Dictionary) -> SlotSize:
	# Determine size based on weight and volume
	var size_score = item_data.get("weight_kg", 0) * 2
	if item_data.has("volume_liters"):
		size_score += item_data.volume_liters
	
	if size_score < 1.0:
		return SlotSize.SMALL
	elif size_score < 5.0:
		return SlotSize.MEDIUM
	else:
		return SlotSize.LARGE

func apply_equipment_bonuses():
	if not character or not character.inventory:
		return
	
	# Apply cumulative bonuses from all equipment
	var total_capacity_bonus = 0.0
	var _total_warmth = 0
	var _total_infection_resist = 0
	
	for slot in equipped_items:
		var item = equipped_items[slot]
		if item:
			total_capacity_bonus += item.get("capacity_bonus", 0)
			if item.has("warmth_bonus"):
				_total_warmth += item.warmth_bonus
			if item.has("infection_resistance"):
				_total_infection_resist += item.infection_resistance
	
	# Store these on the character's inventory
	character.inventory.equipped_capacity_bonus = total_capacity_bonus
	# You might want to store warmth and infection resistance elsewhere

func calculate_damage_reduction(base_damage: float, damage_type: String) -> float:
	var final_damage = base_damage
	
	# Apply damage reduction from equipment
	for slot in equipped_items:
		var item = equipped_items[slot]
		if item and item.has("damage_reduction"):
			var damage_red = item.damage_reduction
			if damage_red is Dictionary and damage_red.has(damage_type):
				final_damage -= damage_red[damage_type]
	
	return max(final_damage, 0.0)

func get_equipment_status() -> String:
	var status = ""
	var has_equipment = false
	
	for slot in equipped_items:
		var item = equipped_items[slot]
		if item:
			status += "• %s: %s\n" % [slot.capitalize(), item.get("display_name", "Unknown")]
			has_equipment = true
	
	if not has_equipment:
		status += "No equipment equipped.\n"
		status += "Find pants, jackets, or backpacks to increase storage!"
	
	return status

func get_equipment_summary() -> Dictionary:
	var equipped_items_dict = {}
	for slot in equipped_items:
		var item = equipped_items[slot]
		if item:
			equipped_items_dict[slot] = item.get("display_name", "Unknown")
	
	var capacity_bonus = 0
	if character and character.inventory:
		capacity_bonus = character.inventory.equipped_capacity_bonus
	
	return {
		"total_equipped": get_equipped_count(),
		"capacity_bonus": capacity_bonus,
		"equipped_items": equipped_items_dict
	}

func get_equipped_count() -> int:
	var count = 0
	for slot in equipped_items:
		if equipped_items[slot] != null:
			count += 1
	return count

func has_item_equipped(item_id: String) -> bool:
	for slot in equipped_items:
		var item = equipped_items[slot]
		if item and item.get("id", "") == item_id:
			return true
	return false
