# ItemPickup3D.gd
extends Area3D
@export var item_id: String = "medkit"
@export var pickup_range: float = 2.0

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.pickup_item(item_id)
		queue_free()
