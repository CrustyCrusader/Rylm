class_name InventorySlot

var item_data: InventoryItemData
var quantity: int = 1
var condition: float = 1.0  # 0.0 to 1.0 for durability
var is_favorite: bool = false
var custom_note: String = ""

func get_effective_weight() -> float:
	return item_data.weight_kg * quantity * condition

func matches_search(search_term: String) -> bool:
	search_term = search_term.to_lower()
	return (
		search_term in item_data.display_name.to_lower() or
		search_term in item_data.flavor_text.to_lower() or
		search_term in item_data.tags or
		search_term in custom_note.to_lower()
	)
