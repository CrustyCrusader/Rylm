# Scripts/SaveSystem.gd
extends Node
class_name SaveSystem

# Signals
signal game_saved(success: bool)
signal game_loaded(success: bool)
signal save_file_created(file_path: String)

# Save file paths
var save_dir: String = "user://saves/"
var save_file: String = "user://saves/game_save.dat"

func _ready():
	# Create save directory if it doesn't exist
	create_save_directory()
	print("SaveSystem initialized")

func create_save_directory() -> void:
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("saves"):
		dir.make_dir("saves")
		print("Created saves directory")

func save_game(data: Dictionary) -> bool:
	print("Attempting to save game...")
	
	# Create save data structure
	var save_data = {
		"version": 1.0,
		"timestamp": Time.get_unix_time_from_system(),
		"game_data": data
	}
	
	# Convert to JSON
	var json_string = JSON.stringify(save_data)
	
	# Write to file
	var file = FileAccess.open(save_file, FileAccess.WRITE)
	if file == null:
		var error = FileAccess.get_open_error()
		push_error("Failed to open save file: ", error)
		game_saved.emit(false)
		return false
	
	file.store_string(json_string)
	file.close()
	
	print("Game saved successfully to: ", save_file)
	game_saved.emit(true)
	return true

func load_game() -> Dictionary:
	print("Attempting to load game...")
	
	var file = FileAccess.open(save_file, FileAccess.READ)
	if file == null:
		print("No save file found, returning empty data")
		game_loaded.emit(false)
		return {}
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_string)
	
	if error != OK:
		push_error("Failed to parse save file: ", json.get_error_message())
		game_loaded.emit(false)
		return {}
	
	var save_data = json.get_data()
	
	if not save_data is Dictionary:
		push_error("Invalid save data format")
		game_loaded.emit(false)
		return {}
	
	print("Game loaded successfully")
	game_loaded.emit(true)
	return save_data.get("game_data", {})

func delete_save() -> bool:
	if FileAccess.file_exists(save_file):
		var dir = DirAccess.open("user://saves/")
		var result = dir.remove("game_save.dat")
		if result == OK:
			print("Save file deleted")
			return true
		else:
			push_error("Failed to delete save file")
			return false
	return true  # File doesn't exist, so consider it deleted

func save_exists() -> bool:
	return FileAccess.file_exists(save_file)

func get_save_info() -> Dictionary:
	if not save_exists():
		return {"exists": false}
	
	var file = FileAccess.open(save_file, FileAccess.READ)
	if file == null:
		return {"exists": false}
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_string)
	
	if error != OK:
		return {"exists": false}
	
	var save_data = json.get_data()
	
	return {
		"exists": true,
		"version": save_data.get("version", 0),
		"timestamp": save_data.get("timestamp", 0),
		"file_size": FileAccess.get_file_as_string(save_file).length()
	}

# Quick save/load for player data
func save_player(player_data: Dictionary) -> bool:
	var save_data = {
		"player": player_data,
		"world_state": {},
		"inventory": {},
		"timestamp": Time.get_unix_time_from_system()
	}
	return save_game(save_data)

func load_player() -> Dictionary:
	var loaded_data = load_game()
	return loaded_data.get("player", {})

# Save/load specific game data
func save_value(key: String, value) -> bool:
	var current_data = load_game()
	current_data[key] = value
	return save_game(current_data)

func load_value(key: String, default = null):
	var current_data = load_game()
	return current_data.get(key, default)
