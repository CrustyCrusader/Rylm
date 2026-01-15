# SimpleTestPickup.gd - Fixed pick_up function
extends Area3D
class_name SimpleTestPickup

@export var item_id: String = "medkit_basic"
@export var quantity: int = 1

@onready var mesh = $MeshInstance3D
@onready var collision = $CollisionShape3D

var spin_speed: float = 1.0
var float_height: float = 0.5
var float_speed: float = 1.0
var initial_y: float = 0.0
var time: float = 0.0

func _ready():
	initial_y = global_position.y
	
	# Connect signal
	body_entered.connect(_on_body_entered)
	
	print("Test pickup created for item: ", item_id, " x", quantity)
	
	# Start floating animation
	start_floating_animation()

func _physics_process(delta):
	time += delta
	
	# Floating animation
	global_position.y = initial_y + sin(time * float_speed) * float_height
	
	# Spinning animation
	rotate_y(delta * spin_speed)

func start_floating_animation():
	# Create a tween for floating effect
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(self, "position:y", position.y + float_height, 1.0 / float_speed)
	tween.tween_property(self, "position:y", position.y, 1.0 / float_speed)

func _on_body_entered(body):
	if body.is_in_group("player") and body.has_method("add_item"):
		pick_up(body)

func pick_up(character):
	# FIXED: Check if ItemDatabase exists as an autoload
	# First, try to get the ItemDatabase singleton
	var item_db = null
	
	# Method 1: Check if ItemDatabase is available globally (if set as autoload)
	if has_node("/root/ItemDatabase"):
		item_db = get_node("/root/ItemDatabase")
		print("Found ItemDatabase at /root/ItemDatabase")
	
	# Method 2: Try to find it in the scene tree
	if not item_db:
		var nodes = get_tree().get_nodes_in_group("item_database")
		if nodes.size() > 0:
			item_db = nodes[0]
			print("Found ItemDatabase in group 'item_database'")
	
	# Method 3: Create a simple fallback item
	if not item_db:
		print("WARNING: ItemDatabase not found. Creating fallback item.")
		var fallback_item = Resource.new()
		fallback_item.set_meta("id", item_id)
		fallback_item.set_meta("display_name", "Test " + item_id)
		fallback_item.set_meta("weight_kg", 1.0)
		fallback_item.set_meta("max_stack", 99)
		
		if character.add_item(fallback_item, quantity):
			print("Picked up fallback item: ", item_id, " x", quantity)
			queue_free()
		return
	
	# Get item from database
	if item_db and item_db.has_method("get_item"):
		var item_data = item_db.get_item(item_id)
		
		if item_data:
			if character.add_item(item_data, quantity):
				# Get item name for display
				var item_name = "Item"
				if item_data.has_method("get_display_name"):
					item_name = item_data.get_display_name()
				elif item_data.has_meta("display_name"):
					item_name = item_data.get_meta("display_name")
				
				print("Picked up: ", item_name, " x", quantity)
				queue_free()
			else:
				print("Inventory full! Could not pick up: ", item_id)
		else:
			print("ERROR: Item not found in database: ", item_id)
	else:
		print("ERROR: ItemDatabase doesn't have get_item method")
