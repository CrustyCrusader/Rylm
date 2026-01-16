# Equipment/EquipmentSlots.gd
class_name EquipmentSlots
extends Node

# Signals
signal slot_equipped(slot: String, item_data: Dictionary)
signal slot_unequipped(slot: String, item_data: Dictionary)

# Slot definitions
var slots: Dictionary = {
	"helmet": {},
	"chest": {},
	"legs": {},
	"boots": {},
	"gloves": {},
	"primary_weapon": {},
	"secondary_weapon": {},
	"backpack": {},
	"accessory_1": {},
	"accessory_2": {}
}

# Slot types and restrictions
var slot_restrictions: Dictionary = {
	"helmet": ["armor", "clothing"],
	"chest": ["armor", "clothing"],
	"legs": ["armor", "clothing"],
	"boots": ["armor", "clothing"],
	"gloves": ["armor", "clothing"],
	"primary_weapon": ["weapon", "tool"],
	"secondary_weapon": ["weapon", "tool"],
	"backpack": ["container"],
	"accessory_1": ["accessory", "utility"],
	"accessory_2": ["accessory", "utility"]
}

func get_slot(slot_name: String) -> Dictionary:
	var slot_data = slots.get(slot_name)
	if slot_data == null:
		return {}
	return slot_data

func set_slot(slot_name: String, item_data: Dictionary) -> bool:
	if slot_name not in slots:
		print("Invalid slot: ", slot_name)
		return false
	
	# Check slot restrictions
	if not can_equip_in_slot(slot_name, item_data):
		print("Item cannot be equipped in slot: ", slot_name)
		return false
	
	var current_item = slots[slot_name]
	slots[slot_name] = item_data
	slot_equipped.emit(slot_name, item_data)
	return true

func clear_slot(slot_name: String) -> Dictionary:
	if slot_name not in slots:
		print("Invalid slot: ", slot_name)
		return {}
	
	var item_data = slots[slot_name]
	slots[slot_name] = {}
	slot_unequipped.emit(slot_name, item_data)
	return item_data

func can_equip_in_slot(slot_name: String, item_data: Dictionary) -> bool:
	if slot_name not in slots:
		return false
	
	# Check if slot is empty or can be replaced
	var current_item = slots.get(slot_name)
	if current_item and not current_item.is_empty():
		# Check if item can be swapped
		pass
	
	# Check item type restrictions
	var allowed_types = slot_restrictions.get(slot_name, [])
	var item_type = item_data.get("type", "")
	
	if allowed_types.is_empty() or item_type.is_empty():
		return true
	
	return item_type in allowed_types

func get_equipped_item(slot_name: String) -> Variant:
	var slot_data = slots.get(slot_name)
	if slot_data == null or slot_data.is_empty():
		return null
	return slot_data.get("item")

func is_slot_empty(slot_name: String) -> bool:
	var slot_data = slots.get(slot_name)
	if slot_data == null:
		return true
	return slot_data.is_empty()

func get_all_slots() -> Dictionary:
	return slots.duplicate()

func get_occupied_slots() -> Dictionary:
	var occupied = {}
	for slot_name in slots:
		var slot_data = slots[slot_name]
		if slot_data and not slot_data.is_empty():
			occupied[slot_name] = slot_data
	return occupied

func get_armor_slots() -> Dictionary:
	var armor_slots = {}
	var armor_slot_names = ["helmet", "chest", "legs", "boots", "gloves"]
	
	for slot_name in armor_slot_names:
		var slot_data = slots.get(slot_name)
		if slot_data == null:
			slot_data = {}
		
		if not slot_data.is_empty():
			armor_slots[slot_name] = slot_data
	
	return armor_slots

func get_weapon_slots() -> Dictionary:
	var weapon_slots = {}
	var weapon_slot_names = ["primary_weapon", "secondary_weapon"]
	
	for slot_name in weapon_slot_names:
		var slot_data = slots.get(slot_name)
		if slot_data == null:
			slot_data = {}
		
		if not slot_data.is_empty():
			weapon_slots[slot_name] = slot_data
	
	return weapon_slots

func get_total_armor() -> float:
	var total_armor = 0.0
	var armor_slots = get_armor_slots()
	
	for slot_name in armor_slots:
		var slot_data = armor_slots[slot_name]
		var armor_value = slot_data.get("armor", 0.0)
		total_armor += armor_value
	
	return total_armor
