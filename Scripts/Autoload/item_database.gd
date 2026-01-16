extends Node
class_name ItemDatabase

var items: Dictionary = {}
var starter_kits: Dictionary = {
	"human": ["medkit_basic", "rations_basic", "water_bottle", "flashlight", "pants_basic"],
	"alien": ["bio_gel", "energy_cell", "translation_device"],
	"zombie": ["rotten_flesh", "infected_claw", "tattered_rags"]
}

func _ready():
	load_all_items()
	add_to_group("item_database")
	print("ItemDatabase loaded with %d items" % items.size())

func load_all_items():
	create_default_items()

func register_item(item_data: ItemDataResource):
	if item_data:
		# Add default complexity if not set
		if not item_data.has("complexity"):
			item_data.complexity = 1.0
		
		items[item_data.item_id] = item_data
		print("Registered item: ", item_data.display_name, 
			  " (Complexity: ", item_data.complexity, ")")
	else:
		print("ERROR: Invalid item data")

func get_item(item_id: String) -> ItemDataResource:
	if items.has(item_id):
		return items[item_id]
	else:
		print("WARNING: Item '%s' not found in database!" % item_id)
		return create_missing_item(item_id)

func create_missing_item(item_id: String) -> ItemDataResource:
	var item = ItemDataResource.new()
	item.id = item_id
	item.item_id = item_id
	item.display_name = "MISSING: " + item_id
	item.weight_kg = 1.0
	item.complexity = 1.0
	return item

func create_default_items():
	# Create medkit
	var medkit = ItemDataResource.new()
	medkit.id = "medkit_basic"
	medkit.item_id = "medkit_basic"
	medkit.display_name = "Field Medkit"
	medkit.weight_kg = 1.2
	medkit.max_stack = 3
	medkit.type = "consumable"
	medkit.complexity = 2.0
	# Add custom properties using stat_bonuses
	medkit.stat_bonuses = {
		"health_restore": 40,
		"description": "Contains bandages, antiseptic, and hope."
	}
	register_item(medkit)
	
	# Create pants
	var pants = ItemDataResource.new()
	pants.id = "pants_basic"
	pants.item_id = "pants_basic"
	pants.display_name = "Worn Jeans"
	pants.weight_kg = 0.8
	pants.is_equippable = true
	pants.equipment_type = "pants"
	pants.type = "equipment"
	pants.complexity = 1.0
	pants.stat_bonuses = {
		"capacity_bonus": 1.0,
		"description": "Stylishly distressed. Mostly functional."
	}
	register_item(pants)
	
	# Create backpack
	var backpack = ItemDataResource.new()
	backpack.id = "backpack_small"
	backpack.item_id = "backpack_small"
	backpack.display_name = "Scout Backpack"
	backpack.weight_kg = 1.5
	backpack.is_equippable = true
	backpack.equipment_type = "backpack"
	backpack.type = "equipment"
	backpack.complexity = 3.0
	backpack.stat_bonuses = {
		"capacity_bonus": 8.0,
		"description": "Has seen more miles than you have."
	}
	register_item(backpack)
	
	# Create rations
	var rations = ItemDataResource.new()
	rations.id = "rations_basic"
	rations.item_id = "rations_basic"
	rations.display_name = "Military Rations"
	rations.weight_kg = 0.5
	rations.max_stack = 5
	rations.type = "consumable"
	rations.complexity = 1.5
	rations.stat_bonuses = {
		"stamina_restore": 30,
		"description": "'Food' is a strong word for this."
	}
	register_item(rations)
	
	# Create water bottle
	var water = ItemDataResource.new()
	water.id = "water_bottle"
	water.item_id = "water_bottle"
	water.display_name = "Water Bottle"
	water.weight_kg = 0.7
	water.max_stack = 3
	water.type = "consumable"
	water.complexity = 1.0
	water.stat_bonuses = {
		"stamina_restore": 20,
		"description": "Half-full or half-empty? Yes."
	}
	register_item(water)

func get_starter_items_for_race(race: String) -> Array:
	return starter_kits.get(race, starter_kits["human"])

func get_item_complexity(item_id: String) -> float:
	var item = get_item(item_id)
	if item:
		return item.complexity
	return 1.0
