# ItemPickup.gd
extends Area3D
class_name ItemPickup

@export var item_id: String = "apple"
@export var quantity: int = 1
@export var can_respawn: bool = false
@export var respawn_time: float = 30.0

var item_resource: Resource
var is_active: bool = true

@onready var mesh_instance = $MeshInstance3D
@onready var collision_shape = $CollisionShape3D

func _ready():
	# Load item from database
	var item_database = get_node_or_null("/root/ItemDatabase")
	if item_database and item_database.has_method("get_item_resource"):
		item_resource = item_database.get_item_resource(item_id)
	
	# Update appearance based on item
	update_appearance()

func update_appearance():
	if not is_active:
		mesh_instance.visible = false
		collision_shape.disabled = true
		return
	
	# Here you could set mesh, material, etc. based on item_resource
	if item_resource and item_resource.has("icon_texture"):
		# Apply texture if available
		pass

func _on_body_entered(body):
	if not is_active:
		return
	
	if body.has_method("add_item_to_inventory"):
		if body.add_item_to_inventory(item_id, quantity):
			print("Item picked up: ", item_id, " x", quantity)
			if can_respawn:
				respawn_item()
			else:
				queue_free()
		else:
			print("Inventory full, couldn't pick up: ", item_id)

func respawn_item():
	is_active = false
	update_appearance()
	
	await get_tree().create_timer(respawn_time).timeout
	
	is_active = true
	update_appearance()
	print("Item respawned: ", item_id)

func set_item(new_item_id: String, new_quantity: int = 1):
	item_id = new_item_id
	quantity = new_quantity
	
	# Reload item resource
	var item_database = get_node_or_null("/root/ItemDatabase")
	if item_database and item_database.has_method("get_item_resource"):
		item_resource = item_database.get_item_resource(item_id)
	
	update_appearance()
