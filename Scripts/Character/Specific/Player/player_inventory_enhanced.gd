extends Node
class_name PlayerInventoryEnhanced

@onready var player = get_parent()

var inventory: InventoryCore
var equipment: EquipmentManager
var is_searching: bool = false
var search_results: Array[InventorySlot] = []

func _ready():
	inventory = InventoryCore.new()
	equipment = EquipmentManager.new()
	add_child(equipment)
	
	# Connect signals
	inventory.inventory_updated.connect(_on_inventory_updated)
	inventory.encumbrance_changed.connect(_on_encumbrance_changed)
	
	# Load saved data
	load_inventory()

func _process(_delta):
	# Search toggle - you'll want UI for this
	if Input.is_action_just_pressed("inventory_search"):
		toggle_search_mode()
	
	# Quick highlight medical items
	if Input.is_action_just_pressed("highlight_medical"):
		var medical_items = inventory.highlight_items_by_tag("medical", Color.RED)
		print("Found %d medical items" % medical_items.size())

func toggle_search_mode():
	is_searching = !is_searching
	if is_searching:
		start_search_mode()
	else:
		end_search_mode()

func start_search_mode():
	print("=== SEARCH MODE ACTIVATED ===")
	print("Type in console: search [term]")
	print("Example: 'search medical' or 'search food'")
	# In your actual game, you'd show a text input UI here

func end_search_mode():
	print("=== SEARCH MODE DEACTIVATED ===")
	search_results.clear()
	# Hide search UI here

func perform_search(search_term: String):
	search_results = inventory.search_items(search_term)
	print("\n=== SEARCH RESULTS: '%s' ===" % search_term)
	if search_results.is_empty():
		print("No items found. Maybe check your spelling?")
	else:
		for i in range(search_results.size()):
			var slot = search_results[i]
			print("%d. %s x%d (%.1f kg)" % [
				i + 1,
				slot.item_data.display_name,
				slot.quantity,
				slot.item_data.weight_kg * slot.quantity
			])
			print("   %s" % slot.item_data.flavor_text)

func _on_inventory_updated():
	# This function is connected to the signal
	# Update UI, play sounds, etc.
	print("Inventory updated: %d items, %.1f/%.1f kg" % [
		inventory.items.size(),
		inventory.total_weight_kg,
		inventory.get_total_capacity()
	])
	


func _on_encumbrance_changed(level: InventoryCore.EncumbranceLevel):
	# This function is connected to the signal
	var messages = {
		InventoryCore.EncumbranceLevel.LIGHT: "Light load. Moving freely!",
		InventoryCore.EncumbranceLevel.MODERATE: "Moderate load. Feeling the weight.",
		InventoryCore.EncumbranceLevel.HEAVY: "Heavy load! Movement impaired.",
		InventoryCore.EncumbranceLevel.OVERLOADED: "OVERLOADED! You can barely move!"
	}
	
	print("Encumbrance Level: %s" % messages[level])
	
	# Apply movement penalty to player
	var speed_multiplier = inventory.get_encumbrance_penalty()
	if player.has_method("set_speed_multiplier"):
		player.set_speed_multiplier(speed_multiplier)
	
	# Adjust stamina drain
	if level == InventoryCore.EncumbranceLevel.OVERLOADED:
		if player.has_method("set_stamina_drain_multiplier"):
			player.set_stamina_drain_multiplier(2.0)
	else:
		if player.has_method("set_stamina_drain_multiplier"):
			player.set_stamina_drain_multiplier(1.0)

func give_starter_items():
	# Give items based on player's race
	
	var item_db = get_node("/root/Item_Database")
	if not item_db:
		return
		
	var race = "human"
	if player.has("race"):
		race = player.race
	
	var starter_item_ids = item_db.get_starter_items_for_race(race)
	
	print("=== GIVING STARTER ITEMS FOR %s ===" % race.to_upper())
	for item_id in starter_item_ids:
		var item = get_item_from_db(item_id)  # Use helper
		if item:
			var result = inventory.add_item(item, 1)
			if result.success:
				print("+ %s" % item.display_name)
			else:
				print("- Couldn't add %s: %s" % [item.display_name, result.message])
	
	# Give basic pants if human
	if race == "human":
		var pants = item_db.get_item("pants_basic")
		inventory.add_item(pants, 1)

func auto_organize_inventory():
	# Sort by weight (lightest first) or usefulness
	inventory.items.sort_custom(func(a, b):
		if a.item_data.tags.has("medical") and not b.item_data.tags.has("medical"):
			return false  # Medical items first (false means a comes after b)
		elif not a.item_data.tags.has("medical") and b.item_data.tags.has("medical"):
			return true
		return a.item_data.weight_kg < b.item_data.weight_kg
	)
	inventory.inventory_updated.emit()
	print("Inventory organized. Medical items on top.")

func get_inventory_summary() -> String:
	var summary = "=== INVENTORY SUMMARY ===\n"
	summary += "Weight: %.1f/%.1f kg\n" % [inventory.total_weight_kg, inventory.get_total_capacity()]
	summary += "Encumbrance: %s\n" % InventoryCore.EncumbranceLevel.keys()[inventory.current_encumbrance]
	summary += "Slots used: %d\n" % inventory.items.size()
	summary += "\n=== EQUIPMENT ===\n"
	summary += equipment.get_equipment_status()
	
	# List heavy items
	var heavy_items = []
	for slot in inventory.items:
		if slot.item_data.weight_kg * slot.quantity > 2.0:
			heavy_items.append(slot)
	
	if not heavy_items.is_empty():
		summary += "\n=== HEAVY ITEMS ===\n"
		for slot in heavy_items:
			summary += "• %s: %.1f kg\n" % [slot.item_data.display_name, slot.item_data.weight_kg * slot.quantity]
	
	return summary

# Save/load with equipment
func save_inventory():
	var save_data = {
		"inventory": [],
		"equipment": {},
		"stats": {
			"total_weight": inventory.total_weight_kg,
			"encumbrance": inventory.current_encumbrance
		}
	}
	
	# Save items
	for slot in inventory.items:
		var slot_data = {
			"item_id": slot.item_data.id,
			"quantity": slot.quantity
		}
		
				# Only add condition if it exists (InventorySlot class has this property)
		if slot.get("condition") != null:  # Check if property exists
			slot_data["condition"] = slot.condition
		
		 # Only add custom_note if it exists
		if slot.get("custom_note") != null:  # Check if property exists
			slot_data["note"] = slot.custom_note
		
		save_data["inventory"].append(slot_data)
	
	# Save equipment
	for slot_name in equipment.equipped_items:
		var item = equipment.equipped_items[slot_name]
		if item:
			save_data["equipment"][slot_name] = item.id
	
	var file = FileAccess.open("user://inventory_enhanced.save", FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data))
	print("Inventory saved.")

func load_inventory():
	if not FileAccess.file_exists("user://inventory_enhanced.save"):
		# First time - give starter items based on race
		give_starter_items()
	
		return	

  # Only reach this code if save file EXISTS
	var file = FileAccess.open("user://inventory_enhanced.save", FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	
	# Clear and load
	inventory.items.clear()
	
	var item_db = get_node("/root/Item_Database")
	if not item_db:
		print("ERROR: ItemDatabase not found!")
		return
			
	for item_data in data["inventory"]:
		var item = item_db.get_item(item_data["item_id"])
		if item:
			var slot = InventorySlot.new()
			slot.item_data = item
			slot.quantity = item_data["quantity"]
			if item_data.has("condition"):
				slot.condition = item_data["condition"]
			if item_data.has("note"):
				slot.custom_note = item_data["note"]
			inventory.items.append(slot)
	
	# Load equipment
	for slot_name in data["equipment"]:
		var item = item_db.get_item(data["equipment"][slot_name])
		if item:
			equipment.equip_item(item, slot_name)
	
	# Update weight and encumbrance
	inventory.total_weight_kg = data["stats"]["total_weight"]
	inventory.current_encumbrance = data["stats"]["encumbrance"]
	
	# Update signals
	inventory.inventory_updated.emit()
	inventory.update_encumbrance()
	
	print("Inventory loaded: %d items" % inventory.items.size())

# Player helper methods
func set_speed_multiplier(multiplier: float):
	# This will be called from _on_encumbrance_changed
	if player.has_method("set_movement_speed_multiplier"):
		player.set_movement_speed_multiplier(multiplier)

func set_stamina_drain_multiplier(multiplier: float):
	if player.has_method("set_stamina_drain_multiplier"):
		player.set_stamina_drain_multiplier(multiplier)
		

func get_slot_property(slot, property_name, default_value = null):
	# Check if the slot has the property
	if slot.has(property_name):  # This works for classes with properties
		return slot.get(property_name)
	elif slot is Dictionary and slot.has(property_name):  # For dictionary slots
		return slot[property_name]
	else:
		return default_value

func get_item_from_db(item_id: String) -> InventoryItemData:
	var item_db = get_node("/root/ItemDatabase")
	if item_db:
		return item_db.get_item(item_id)
	else:
		print("ERROR: ItemDatabase singleton not found!")
		return null
