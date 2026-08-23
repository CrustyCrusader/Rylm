extends Resource
class_name ItemDataResource
 
@export var item_id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var weight_kg: float = 0.1
@export var max_stack: int = 1
@export var item_type: String = "misc"
@export var value: int = 1
 
func get_id() -> String:
	return item_id

func get_weight_kg() -> float:
	return weight_kg

func get_max_stack() -> int:
	return max_stack
