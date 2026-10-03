# ItemPickup3D.gd
extends Area3D
@export var item_id: String = "medkit"
@export var pickup_range: float = 2.0
@export var item_data: Resource # or Dictionary / ItemResource

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	# Check if the colliding body can pick up items
	if body.has_method("pickup_item"):
		var success: bool = body.pickup_item(item_data)
		if success:
			queue_free() # Remove item from world once picked up
