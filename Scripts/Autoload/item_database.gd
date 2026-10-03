extends Node

var item_cache: Dictionary = {}

func _ready() -> void:
	_initialize_database()

func _initialize_database() -> void:
	register_item("medkit", {"name": "Medical Kit", "category": "medical", "stack_max": 5})
	register_item("flashlight", {"name": "Handy Flashlight", "category": "tool", "stack_max": 1})
	register_item("canned_food", {"name": "Canned Food", "category": "survival", "stack_max": 10})

func register_item(id: String, item_data: Dictionary) -> void:
	item_cache[id] = item_data

func get_item(id: String) -> Dictionary:
	return item_cache.get(id, {})
