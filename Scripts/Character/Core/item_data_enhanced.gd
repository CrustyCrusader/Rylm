extends Resource
class_name InventoryItemData

@export_category("Basic Info")
@export var id: String = ""
@export var display_name: String = ""
@export var texture: Texture2D
@export var rarity: String = "common"  # common, uncommon, rare, legendary

@export_category("Physical Properties")
@export var weight_kg: float = 0.1
@export var volume_liters: float = 0.5
@export var max_stack: int = 99
@export var tags: PackedStringArray = PackedStringArray(["misc"])  # FIXED: Use PackedStringArray

@export_category("Equipment Properties")
@export var is_equippable: bool = false
@export_enum("None", "Backpack", "Pants", "Jacket", "Toolbelt", "Case") var equipment_slot: String = "None"
@export var capacity_bonus: float = 0.0
@export var slot_bonus: Dictionary = {  # Dictionary exports work fine
	"pockets": 0,
	"pants": 0,
	"jacket": 0,
	"backpack": 0,
	"case": 0
}

@export_category("Gameplay Effects")
@export var is_consumable: bool = false
@export var health_restore: int = 0
@export var stamina_restore: int = 0
@export var infection_resistance: int = 0
@export var warmth_bonus: int = 0

@export_category("Flavor & Description")
@export_multiline var flavor_text: String = "It exists. Congratulations."
@export var examine_text: String = "Yep, that's definitely a thing."
@export var pickup_line: String = "You acquire the thingamajig."

# The rest of your functions remain the same...
func use(player) -> Dictionary:
	var result = { "success": false, "message": "" }
	
	if is_consumable:
		if player.health < player.max_health and health_restore > 0:
			player.health = min(player.health + health_restore, player.max_health)
			result.message = "Restored %d health. You feel... patched." % health_restore
			result.success = true
		elif player.current_stamina < player.max_stamina and stamina_restore > 0:
			player.current_stamina = min(player.current_stamina + stamina_restore, player.max_stamina)
			result.message = "Energy boost! You can run slightly longer!"
			result.success = true
		else:
			result.message = "No effect. Maybe save it for later?"
	
	return result
