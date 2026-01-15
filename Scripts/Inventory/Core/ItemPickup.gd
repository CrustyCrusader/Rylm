# SimpleItemPickup.gd
extends Area3D
class_name SimpleItemPickup

@export var item_id: String = "medkit_basic"
@export var quantity: int = 1

@onready var mesh = $MeshInstance3D
@onready var collision = $CollisionShape3D

var item_data: Resource = null
var spin_speed: float = 1.0

func _ready():
	# Load item from database
	var item_db = get_node("/root/ItemDatabase")
	if item_db and item_db.has_method("get_item"):
		item_data = item_db.get_item(item_id)
	
	if item_data:
		print("Item pickup created: %s x%d" % [item_data.has("display_name", "Unknown"), quantity])
	
	# Floating animation
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(self, "position:y", position.y + 0.3, 1.0)
	tween.tween_property(self, "position:y", position.y, 1.0)
	
	# Connect signal
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	# Spin slowly
	rotate_y(delta * spin_speed)

func _on_body_entered(body):
	if body.is_in_group("player") and body.has_method("add_item") and item_data:
		var success = body.add_item(item_data, quantity)
		if success:
			print("Picked up: %s x%d" % [item_data.has("display_name", "Item"), quantity])
			queue_free()
		else:
			print("Couldn't pick up %s (inventory full?)" % item_data.has("display_name", "Item"))
