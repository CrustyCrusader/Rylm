# DEBUG_ButtonTest.gd
extends Node

func _ready():
	# Wait a bit for UI to load
	await get_tree().create_timer(1.0).timeout
	
	# Find all SimpleInventoryUI nodes
	var ui_nodes = get_tree().get_nodes_in_group("inventory_ui")
	for ui in ui_nodes:
		print("Found UI: ", ui.name)
		if ui.has_method("debug_print_button_status"):
			ui.debug_print_button_status()

# Add this to SimpleInventoryUI.gd:
func debug_print_button_status():
	print("=== SimpleInventoryUI Debug ===")
	print("close_button assigned: ", close_button != null)
	print("visible: ", visible)
	print("player assigned: ", player != null)
