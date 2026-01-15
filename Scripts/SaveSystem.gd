# SimpleSaveSystem.gd
extends Node
class_name SimpleSaveSystem

const SAVE_FILE = "user://save_game.json"

func save_game() -> bool:
	var player = get_tree().get_first_node_in_group("player") as BaseCharacter3D
	if not player:
		print("No player found to save")
		return false
	
	var save_data = {
		"player": {
			"name": player.character_name,
			"position": {
				"x": player.global_position.x,
				"y": player.global_position.y,
				"z": player.global_position.z
			},
			"rotation": player.rotation.y,
			"health": player.stats.current_health if player.stats else 100,
			"stamina": player.stats.current_stamina if player.stats else 100
		},
		"timestamp": Time.get_unix_time_from_system(),
		"version": "1.0"
	}
	
	# Add inventory items
	if player.inventory:
		var inventory_items = []
		for item in player.inventory.items:
			var item_data = {
				"id": item["item_data"].get("id", ""),
				"quantity": item["quantity"]
			}
			inventory_items.append(item_data)
		save_data["inventory"] = inventory_items
	
	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()
		print("Game saved successfully")
		return true
	else:
		print("Failed to save game")
		return false

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_FILE):
		print("No save file found")
		return false
	
	var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
	if not file:
		print("Failed to open save file")
		return false
	
	var json_data = JSON.parse_string(file.get_as_text())
	file.close()
	
	if not json_data:
		print("Failed to parse save data")
		return false
	
	# Apply save data
	var player = get_tree().get_first_node_in_group("player") as BaseCharacter3D
	if not player:
		print("No player found to load data into")
		return false
	
	# Load position
	if json_data.has("player") and json_data.player.has("position"):
		var pos = json_data.player.position
		player.global_position = Vector3(pos.x, pos.y, pos.z)
		player.rotation.y = json_data.player.get("rotation", 0)
	
	# Load stats
	if player.stats:
		if json_data.player.has("health"):
			player.stats.current_health = json_data.player.health
		if json_data.player.has("stamina"):
			player.stats.current_stamina = json_data.player.stamina
	
	# Load inventory
	if player.inventory and json_data.has("inventory"):
		# Clear current inventory
		player.inventory.items.clear()
		player.inventory.current_weight = 0
		
		# Load saved items
		var item_db = get_node("/root/ItemDatabase")
		for item_data in json_data.inventory:
			if item_db and item_db.has_method("get_item"):
				var item = item_db.get_item(item_data.id)
				if item:
					player.inventory.add_item(item, item_data.quantity)
	
	print("Game loaded successfully")
	return true
