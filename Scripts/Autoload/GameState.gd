# GameState.gd - Game-wide state management
extends Node
class_name GameState

# Game State Signals
signal game_paused(paused: bool)
signal game_saved(slot: int)
signal game_loaded(slot: int)
# signal player_died()  # Commented out for now - will be used later
# signal player_respawned()  # Commented out for now - will be used later

# Global Game State
var is_game_paused: bool = false:
	set(value):
		is_game_paused = value
		get_tree().paused = value
		game_paused.emit(value)

var current_save_slot: int = 1
var game_time_elapsed: float = 0.0
var player_position: Vector3 = Vector3.ZERO
var player_health: float = 100.0

# Inventory/Item State
var collected_item_ids: Array = []
var equipped_items: Dictionary = {}  # slot_name: item_id

# Quest/Objective State
var active_quests: Array = []
var completed_quests: Array = []
var objectives: Dictionary = {}

func _ready():
	print("GameState loaded")
	load_default_settings()

func _process(delta):
	if not is_game_paused:
		game_time_elapsed += delta

func save_game(slot: int = current_save_slot):
	var save_data = {
		"timestamp": Time.get_datetime_string_from_system(),
		"game_time": game_time_elapsed,
		"player_position": {
			"x": player_position.x,
			"y": player_position.y,
			"z": player_position.z
		},
		"player_health": player_health,
		"collected_items": collected_item_ids,
		"equipped_items": equipped_items,
		"active_quests": active_quests,
		"completed_quests": completed_quests
	}
	
	# Save to file
	var save_path = "user://save_slot_%d.json" % slot
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()
		print("Game saved to slot ", slot)
		game_saved.emit(slot)
	else:
		push_error("Failed to save game to slot ", slot)

func load_game(slot: int = current_save_slot):
	var save_path = "user://save_slot_%d.json" % slot
	if not FileAccess.file_exists(save_path):
		print("No save file found for slot ", slot)
		return false
	
	var file = FileAccess.open(save_path, FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var error = json.parse(json_text)
		if error == OK:
			var save_data = json.data
			current_save_slot = slot
			game_time_elapsed = save_data.get("game_time", 0.0)
			player_health = save_data.get("player_health", 100.0)
			
			var pos_dict = save_data.get("player_position", {})
			player_position = Vector3(pos_dict.get("x", 0), pos_dict.get("y", 0), pos_dict.get("z", 0))
			
			collected_item_ids = save_data.get("collected_items", [])
			equipped_items = save_data.get("equipped_items", {})
			active_quests = save_data.get("active_quests", [])
			completed_quests = save_data.get("completed_quests", [])
			
			print("Game loaded from slot ", slot)
			game_loaded.emit(slot)
			return true
		else:
			push_error("Failed to parse save file: ", json.get_error_message())
	return false

func load_default_settings():
	# Set default values
	is_game_paused = false
	game_time_elapsed = 0.0
	player_health = 100.0
	player_position = Vector3.ZERO
	collected_item_ids.clear()
	equipped_items.clear()
	active_quests.clear()
	completed_quests.clear()

func add_collected_item(item_id: String):
	if not collected_item_ids.has(item_id):
		collected_item_ids.append(item_id)
		print("Added item to global collection: ", item_id)

func is_item_collected(item_id: String) -> bool:
	return collected_item_ids.has(item_id)

func get_game_time_formatted() -> String:
	var hours = int(game_time_elapsed / 3600.0)
	var minutes = int(fmod(game_time_elapsed, 3600.0) / 60.0)
	var seconds = int(fmod(game_time_elapsed, 60.0))
	return "%02d:%02d:%02d" % [hours, minutes, seconds]

# Quick save/load commands (for console/debug)
func quick_save():
	save_game(current_save_slot)

func quick_load():
	load_game(current_save_slot)
