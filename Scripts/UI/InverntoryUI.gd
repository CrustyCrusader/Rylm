extends CanvasLayer

#region References
@onready var inventory_panel = $InventoryPanel
@onready var item_grid = $InventoryPanel/ScrollContainer/ItemGrid
@onready var close_button = $InventoryPanel/CloseButton
@onready var weight_label = $InventoryPanel/WeightLabel
@onready var capacity_label = $InventoryPanel/CapacityLabel
#endregion

#region Variables
var player: BaseCharacter3D = null
var ui_visible: bool = false

#endregion

func _ready():
	# Start hidden
	inventory_panel.visible = false
	
	# Connect button
	close_button.pressed.connect(close_inventory)

func set_player(new_player: BaseCharacter3D):
	player = new_player

func toggle_inventory():
	if ui_visible:
		close_inventory()
	else:
		open_inventory()

func open_inventory():
	if not player:
		return
	
	ui_visible = true
	inventory_panel.visible = true
	
	# Show mouse cursor
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Update inventory display
	update_inventory_display()
	
	# Pause game if single player
	get_tree().paused = true

func close_inventory():
	ui_visible = false
	inventory_panel.visible = false
	
	# Hide mouse cursor
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Unpause game
	get_tree().paused = false

func update_inventory_display():
	if not player or not player.inventory:
		return
	
	# Clear existing items
	for child in item_grid.get_children():
		child.queue_free()
	
	# Update weight info
	var current_weight = player.inventory.get_current_weight()
	var total_capacity = player.inventory.get_total_capacity()
	var encumbrance = player.inventory.get_encumbrance_level()
	
	weight_label.text = "Weight: %.1f / %.1f kg" % [current_weight, total_capacity]
	capacity_label.text = "Encumbrance: %s" % encumbrance
	
	# Add items to grid
	var items = player.inventory.items
	for i in range(items.size()):
		var item_data = items[i]
		var item_slot = item_slot_scene.instantiate()
		
		# Set item data
		item_slot.set_item_data(item_data)
		item_slot.slot_index = i
		item_slot.item_clicked.connect(_on_item_clicked)
		
		item_grid.add_child(item_slot)
	
	# If no items, show message
	if items.size() == 0:
		var empty_label = Label.new()
		empty_label.text = "Inventory is empty"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		item_grid.add_child(empty_label)

func _on_item_clicked(slot_index: int, button_index: int):
	if not player or not player.inventory:
		return
	
	var items = player.inventory.items
	if slot_index < items.size():
		var item = items[slot_index]
		
		if button_index == MOUSE_BUTTON_LEFT:
			# Try to use/equip item
			_on_item_use(item)
		elif button_index == MOUSE_BUTTON_RIGHT:
			# Show context menu
			_show_item_context_menu(item, slot_index)

func _on_item_use(item):
	# Check if item is equippable
	if player.equipment and "equipment_slot" in item["item_data"]:
		player.equip_item(item["item_data"])
		update_inventory_display()
		print("Equipped: ", item["item_data"].display_name)
	
	# Check if item is consumable
	elif "heal_amount" in item["item_data"]:
		player.heal(item["item_data"].heal_amount)
		player.inventory.remove_item(item["item_data"].id, 1)
		update_inventory_display()
		print("Used: ", item["item_data"].display_name)

func _show_item_context_menu(item, slot_index):
	# Create a simple context menu
	var context_menu = preload("res://Scenes/ContextMenu.tscn").instantiate()
	context_menu.position = get_viewport().get_mouse_position()
	context_menu.item = item
	context_menu.slot_index = slot_index
	
	# Add options based on item type
	if player.equipment and "equipment_slot" in item["item_data"]:
		context_menu.add_option("Equip", Callable(self, "_on_item_equip"))
	
	if "heal_amount" in item["item_data"]:
		context_menu.add_option("Use", Callable(self, "_on_item_use"))
	
	context_menu.add_option("Drop", Callable(self, "_on_item_drop"))
	context_menu.add_option("Inspect", Callable(self, "_on_item_inspect"))
	
	add_child(context_menu)

func _on_item_equip(item):
	if player.equipment:
		player.equip_item(item["item_data"])
		update_inventory_display()

func _on_item_drop(item, _slot_index):
	if player.inventory:
		player.inventory.remove_item(item["item_data"].id, 1)
		update_inventory_display()
		print("Dropped: ", item["item_data"].display_name)

func _on_item_inspect(item):
	# Show item details
	var details = "Name: %s\nWeight: %.1f kg\nQuantity: %d" % [
		item["item_data"].display_name,
		item["item_data"].weight_kg,
		item["quantity"]
	]
	
	# Add description if available
	if "description" in item["item_data"]:
		details += "\n\n" + item["item_data"].description
	
	print(details)
