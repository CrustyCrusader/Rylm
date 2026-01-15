extends Resource
# Remove: class_name InventoryItemData or rename to something unique
class_name ItemDataResource  # Changed to unique name

@export var id: String = ""
@export var display_name: String = ""
@export var weight_kg: float = 0.1
@export var max_stack: int = 99
@export var is_equippable: bool = false
@export var equipment_type: String = ""
@export var type: String = "misc"  # weapon, armor, consumable, etc.
@export var stat_bonuses: Dictionary = {}

# Optional properties
@export var damage_resistances: Dictionary = {}
@export var tags: PackedStringArray = PackedStringArray(["misc"])

func _init():
	# Initialize with default values
	if id == "":
		id = "item_" + str(randi())
	if display_name == "":
		display_name = "Unnamed Item"
