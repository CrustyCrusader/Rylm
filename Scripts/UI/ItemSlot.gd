
extends Control

signal item_clicked(slot_index: int, button_index: int)

@onready var icon_texture = $Icon
@onready var name_label = $NameLabel
@onready var quantity_label = $QuantityLabel

var slot_index: int = -1

func set_item_data(item_dict):
	var item = item_dict["item_data"]
	var quantity = item_dict["quantity"]
	
	name_label.text = item.display_name
	quantity_label.text = "x%d" % quantity
	
	# Load icon if available
	if item.icon_path:
		var icon = load(item.icon_path)
		if icon:
			icon_texture.texture = icon

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			item_clicked.emit(slot_index, event.button_index)
